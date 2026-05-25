$SB_URL = 'https://ahpzdwemvunyaumrnxal.supabase.co/rest/v1'
$SB_KEY = 'sb_publishable_NPPdURwPz_DEt6JG--haaw_CThnEoQF'
$YT_KEY = 'AIzaSyBX47DSTcr3ZOPtbmYIoG0ECvHw1VHHHis'
$DEFAULT_NICHE = 'Kick a Lucky Block'

$sbHdr = @{
    'apikey'        = $SB_KEY
    'Authorization' = "Bearer $SB_KEY"
    'Content-Type'  = 'application/json'
}

$targetYtIds = @(
    'UCjGUDGiK-wrCNHwqSOqGBQw',
    'UC0halS8nrHxKLW6bfNoBYgQ',
    'UCBuNmnxOzVL_dy7HmO0Mz8Q',
    'UC4XY9C-ZViMEIXT4mDk_h_w',
    'UCfGwGgBYzp1-TI527dXBBLg',
    'UCydV5nlLba9Tw2cq6LMYvLw',
    'UCnEdTerOMGQmH03ahAmxaFA',
    'UCWD4mHtcAGhq1uogzqH0lKg',
    'UC7bpcgyPaq6MihFsGOVJnDw',
    'UCQwDMIf1EAnYulPxuPs63wg',
    'UCRwBASV3V4d1vdZSFhG_oyw',
    'UC7X-PQO1vMbCTYx4Co_Ou6w',
    'UC3l7Z8jx4AoE1i_S_-Y_4Eg',
    'UCip7I0kh5W4fbDWgZji2k9g',
    'UCDm64DTeYFT27gRumEwQRCA',
    'UCRjiLHnquY_74lOY-eb9fkQ',
    'UCGqN5h11C5xsD5x8cILct9g',
    'UCPIzPN_V3Wk2KN5wIK3Kwsg',
    'UCnesc0BUlTL8GxfLo3Ov3fw',
    'UCMQWI7gKBT87vTkelq9C5YQ',
    'UCtbxInwb4hP5lGYEHFeZ1fg',
    'UCt27yjOGB6KqiXXcRrVgrLg',
    'UC3WBAnj-fEBCOpF9TTA7xdw',
    'UCx43wRV_5eVAu2ah2aR-3NQ',
    'UCwkDYwR6NT9KhQJA0ZQ9jBw',
    'UCrgR_3iaComosA0r_9hW9fA',
    'UCDz9PMr9ILTkPCqqTPv3eLA',
    'UCEjWELI73VOM0gE2ePK_hdA'
)

function Get-VideoNiche($title) {
    $t = $title.ToLower()
    if ($t -match 'kick.*lucky|lucky.*kick|kickalucky|lucky.block') { return 'Kick a Lucky Block' }
    if ($t -match 'tsunami')     { return 'Escape Tsunami Brainrot' }
    if ($t -match 'troll tower') { return 'Troll Tower' }
    if ($t -match '99 nights')   { return '99 Nights in the Forest' }
    return 'Kick a Lucky Block'
}

# ── STEP 1: Load DB channels ──────────────────────────────────────────────────
Write-Host "=== STEP 1: Loading DB channels ==="
$rawDbChannels = Invoke-RestMethod -Uri ($SB_URL + '/channels?select=id,name,url&limit=1000') -Headers $sbHdr
$allDbChannels = @($rawDbChannels)
Write-Host ("DB has " + $allDbChannels.Count + " channels.")

# ── STEP 2: Fetch YT channel info (one batch) ────────────────────────────────
Write-Host "=== STEP 2: Fetching channel info from YouTube API ==="
$ytIdsJoined = $targetYtIds -join ','
$ytApiResp = Invoke-RestMethod -Uri ('https://www.googleapis.com/youtube/v3/channels?part=snippet&id=' + $ytIdsJoined + '&maxResults=50&key=' + $YT_KEY)
$ytInfoMap = @{}
foreach ($item in @($ytApiResp.items)) { $ytInfoMap[$item.id] = $item }
Write-Host ("YouTube API returned info for " + $ytInfoMap.Count + " channels.")

# ── STEP 3: Match each target channel to a DB row ────────────────────────────
Write-Host "=== STEP 3: Matching channels to DB ==="
$channelLookup = @{}

foreach ($ytId in $targetYtIds) {
    $ytInfo   = $ytInfoMap[$ytId]
    $ytTitle  = if ($ytInfo) { $ytInfo.snippet.title.Trim() } else { '' }
    $ytHandle = if ($ytInfo -and $ytInfo.snippet.customUrl) { $ytInfo.snippet.customUrl.ToLower().TrimStart('@') } else { '' }

    $found = $null
    foreach ($ch in $allDbChannels) {
        $chUrl  = if ($ch.url)  { $ch.url.ToLower()  } else { '' }
        $chName = if ($ch.name) { $ch.name.Trim().ToLower() } else { '' }
        if ($chUrl  -match [regex]::Escape($ytId))      { $found = $ch; break }
        if ($ytHandle -and $chUrl -match [regex]::Escape($ytHandle)) { $found = $ch; break }
        if ($ytTitle -and $chName -eq $ytTitle.ToLower()) { $found = $ch; break }
    }

    if ($found) {
        $channelLookup[$ytId] = $found
        Write-Host ("  MATCHED: " + $found.name)
    } else {
        Write-Host ("  NO MATCH: " + $ytId + " (" + $ytTitle + ") - skipping")
    }
}
Write-Host ("Matched " + $channelLookup.Count + " / " + $targetYtIds.Count + " channels.")

# ── STEP 4: Load existing video IDs ─────────────────────────────────────────
Write-Host "=== STEP 4: Loading existing video IDs ==="
$existingVidIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$offset = 0
do {
    $uri    = $SB_URL + '/videos?select=video_id&limit=1000&offset=' + $offset.ToString()
    $vBatch = Invoke-RestMethod -Uri $uri -Headers $sbHdr
    foreach ($v in @($vBatch)) { if ($v.video_id) { [void]$existingVidIds.Add($v.video_id) } }
    $batchCount = @($vBatch).Count
    $offset += 1000
} while ($batchCount -eq 1000)
Write-Host ("Existing video IDs loaded: " + $existingVidIds.Count)

# ── STEP 5: Fetch Shorts per channel via YT search API ───────────────────────
Write-Host "=== STEP 5: Fetching Shorts ==="
$allNewVideos = [System.Collections.Generic.List[object]]::new()

foreach ($ytId in $targetYtIds) {
    $dbRow = $channelLookup[$ytId]
    if (-not $dbRow) { Write-Host ("  SKIP (no DB row): " + $ytId); continue }

    $chName = $dbRow.name
    Write-Host ("  " + $chName + " ...")

    $pageToken = ''
    $pageNum   = 0
    $newForCh  = 0

    do {
        $searchUri = 'https://www.googleapis.com/youtube/v3/search?part=id&channelId=' + $ytId + '&type=video&videoDuration=short&maxResults=50&order=date&key=' + $YT_KEY
        if ($pageToken) { $searchUri += '&pageToken=' + $pageToken }

        try { $searchResp = Invoke-RestMethod -Uri $searchUri -Method Get }
        catch { Write-Host ("    Search error: " + $_.Exception.Message); break }

        $videoIds = @($searchResp.items | ForEach-Object { $_.id.videoId }) | Where-Object { $_ }
        if ($videoIds.Count -eq 0) { break }

        $idsParam    = $videoIds -join ','
        $detailsUri  = 'https://www.googleapis.com/youtube/v3/videos?part=snippet,statistics&id=' + $idsParam + '&maxResults=50&key=' + $YT_KEY
        try { $detailsResp = Invoke-RestMethod -Uri $detailsUri -Method Get }
        catch { Write-Host ("    Details error: " + $_.Exception.Message); break }

        foreach ($item in @($detailsResp.items)) {
            $vid = $item.id
            if ($existingVidIds.Contains($vid)) { continue }

            $rawTitle = $item.snippet.title
            $title    = [regex]::Replace($rawTitle, '[^\x20-\x7E]', '').Trim()
            if (-not $title) { $title = 'Untitled' }

            $views = 0
            if ($item.statistics.viewCount) { $views = [long]$item.statistics.viewCount }

            $pubDate = $null
            if ($item.snippet.publishedAt) { $pubDate = $item.snippet.publishedAt.Substring(0,10) }

            $allNewVideos.Add([PSCustomObject]@{
                channel_id     = $dbRow.id
                channel_name   = $chName
                niche          = Get-VideoNiche $title
                title          = $title
                video_id       = $vid
                url            = 'https://www.youtube.com/shorts/' + $vid
                views          = $views
                published_date = $pubDate
            })
            [void]$existingVidIds.Add($vid)
            $newForCh++
        }

        $pageToken = $searchResp.nextPageToken
        $pageNum++
        Start-Sleep -Milliseconds 200
    } while ($pageToken -and $pageNum -lt 3)

    Write-Host ("    " + $newForCh + " new Shorts queued")
    Start-Sleep -Milliseconds 300
}

Write-Host ("Total new videos to insert: " + $allNewVideos.Count)

# ── STEP 6: Insert in batches of 50 ─────────────────────────────────────────
Write-Host "=== STEP 6: Inserting ==="
$insertHdr = @{
    'apikey'        = $SB_KEY
    'Authorization' = "Bearer $SB_KEY"
    'Content-Type'  = 'application/json'
    'Prefer'        = 'return=minimal'
}

$totalOk = 0; $totalFail = 0

for ($i = 0; $i -lt $allNewVideos.Count; $i += 50) {
    $end   = [Math]::Min($i + 49, $allNewVideos.Count - 1)
    $chunk = @($allNewVideos[$i..$end])
    $rows  = @($chunk | ForEach-Object {
        @{
            channel_id     = $_.channel_id
            channel_name   = $_.channel_name
            niche          = $_.niche
            title          = $_.title
            video_id       = $_.video_id
            url            = $_.url
            views          = $_.views
            published_date = $_.published_date
        }
    })
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $rows -Compress -Depth 5))

    try {
        Invoke-RestMethod -Uri ($SB_URL + '/videos') -Method Post -Headers $insertHdr -Body $bodyBytes | Out-Null
        $totalOk += $chunk.Count
    } catch {
        foreach ($row in $chunk) {
            $ob = [System.Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject @($row) -Compress -Depth 5))
            try {
                Invoke-RestMethod -Uri ($SB_URL + '/videos') -Method Post -Headers $insertHdr -Body $ob | Out-Null
                $totalOk++
            } catch {
                $totalFail++
                if ($totalFail -le 5) { Write-Host ("  Fail: " + $row.video_id + " - " + $_.Exception.Message) }
            }
        }
    }
    if ($totalOk -gt 0 -and ($totalOk % 200) -eq 0) { Write-Host ("  Inserted " + $totalOk + " so far...") }
}

Write-Host ""
Write-Host "=== DONE ==="
Write-Host ("Videos inserted : " + $totalOk)
Write-Host ("Videos failed   : " + $totalFail)

$hdrC = $sbHdr.Clone(); $hdrC['Prefer'] = 'count=exact'
$fc = Invoke-WebRequest -Uri ($SB_URL + '/videos?select=id&limit=1') -Headers $hdrC
Write-Host ("Total videos in DB: " + $fc.Headers['Content-Range'])
