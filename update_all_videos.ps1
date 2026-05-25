$SB_URL = 'https://ahpzdwemvunyaumrnxal.supabase.co/rest/v1'
$SB_KEY = 'sb_publishable_NPPdURwPz_DEt6JG--haaw_CThnEoQF'
$YT_KEY = 'AIzaSyBX47DSTcr3ZOPtbmYIoG0ECvHw1VHHHis'

$sbHdr = @{ 'apikey' = $SB_KEY; 'Authorization' = "Bearer $SB_KEY"; 'Content-Type' = 'application/json' }
$insertHdr = $sbHdr.Clone(); $insertHdr['Prefer'] = 'return=minimal'

function Get-VideoNiche($title) {
    $t = $title.ToLower()
    if ($t -match 'kick.*lucky|lucky.*kick|kickalucky|lucky.block') { return 'Kick a Lucky Block' }
    if ($t -match 'tsunami')     { return 'Escape Tsunami Brainrot' }
    if ($t -match 'troll tower') { return 'Troll Tower' }
    if ($t -match '99 nights')   { return '99 Nights in the Forest' }
    return 'unassigned'
}

function Get-YtRef($url) {
    if ($url -match '/channel/(UC[^/?&#/]+)') { return @{ type = 'id'; value = $Matches[1] } }
    if ($url -match '/@([^/?&#/]+)')          { return @{ type = 'handle'; value = '@' + $Matches[1] } }
    return $null
}

function Insert-Videos($list) {
    if ($list.Count -eq 0) { return @{ ok = 0; fail = 0 } }
    $ok = 0; $fail = 0
    for ($i = 0; $i -lt $list.Count; $i += 50) {
        $chunk = @($list[$i..[Math]::Min($i+49, $list.Count-1)])
        $body  = [System.Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $chunk -Compress -Depth 5))
        try {
            Invoke-RestMethod -Uri ($SB_URL + '/videos') -Method Post -Headers $insertHdr -Body $body | Out-Null
            $ok += $chunk.Count
        } catch {
            foreach ($row in $chunk) {
                $b = [System.Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject @($row) -Compress -Depth 5))
                try { Invoke-RestMethod -Uri ($SB_URL + '/videos') -Method Post -Headers $insertHdr -Body $b | Out-Null; $ok++ }
                catch { $fail++ }
            }
        }
    }
    return @{ ok = $ok; fail = $fail }
}

function Parse-ISODuration($dur) {
    if ($dur -match 'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?') {
        return ([int]($Matches[1]) * 3600) + ([int]($Matches[2]) * 60) + [int]($Matches[3])
    }
    return 9999
}

# ── Load channels ──────────────────────────────────────────────────────────────
Write-Host "=== Loading DB channels ==="
$rawCh = Invoke-RestMethod -Uri ($SB_URL + '/channels?select=id,name,url,niche&limit=1000') -Headers $sbHdr
$allChannels = @($rawCh)
Write-Host ("  " + $allChannels.Count + " channels")

# ── Load all existing video_ids (paginated) ────────────────────────────────────
Write-Host "=== Loading existing video IDs ==="
$existingVidIds   = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$channelHasVideos = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$offset = 0
do {
    $vBatch = Invoke-RestMethod -Uri ($SB_URL + '/videos?select=video_id,channel_id&limit=1000&offset=' + $offset) -Headers $sbHdr
    foreach ($v in @($vBatch)) {
        if ($v.video_id)   { [void]$existingVidIds.Add($v.video_id) }
        if ($v.channel_id) { [void]$channelHasVideos.Add($v.channel_id) }
    }
    $bc = @($vBatch).Count; $offset += 1000
} while ($bc -eq 1000)
Write-Host ("  " + $existingVidIds.Count + " existing video IDs")

$newChannels      = @($allChannels | Where-Object { -not $channelHasVideos.Contains($_.id) })
$existingChannels = @($allChannels | Where-Object {  $channelHasVideos.Contains($_.id) })
Write-Host ("  New channels (0 videos): " + $newChannels.Count)
Write-Host ("  Existing channels:       " + $existingChannels.Count)

# ══════════════════════════════════════════════════════════════════════════════
# TASK 1: New channels — scrape ALL Shorts, niche = "unassigned"
# ══════════════════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "=== TASK 1: New channels ==="
$t1List = [System.Collections.Generic.List[object]]::new()
$t1Ok = 0; $t1Fail = 0

foreach ($ch in $newChannels) {
    $ytRef = Get-YtRef $ch.url
    if (-not $ytRef) { Write-Host ("  SKIP (bad URL): " + $ch.name); continue }

    # Resolve channel ID
    $param = if ($ytRef.type -eq 'id') { 'id=' + $ytRef.value } else { 'forHandle=' + $ytRef.value }
    try {
        $ytCh = Invoke-RestMethod -Uri ('https://www.googleapis.com/youtube/v3/channels?part=snippet&' + $param + '&key=' + $YT_KEY)
    } catch { Write-Host ("  SKIP (YT error): " + $ch.name); continue }
    if (-not $ytCh.items -or @($ytCh.items).Count -eq 0) { Write-Host ("  SKIP (not found): " + $ch.name); continue }

    $ytChannelId = @($ytCh.items)[0].id
    Write-Host ("  " + $ch.name + " (" + $ytChannelId + ")")

    $pageToken = ''; $pageNum = 0; $newForCh = 0
    do {
        $sUri = 'https://www.googleapis.com/youtube/v3/search?part=id&channelId=' + $ytChannelId +
                '&type=video&videoDuration=short&maxResults=50&order=date&key=' + $YT_KEY
        if ($pageToken) { $sUri += '&pageToken=' + $pageToken }
        try { $sResp = Invoke-RestMethod -Uri $sUri -Method Get }
        catch { Write-Host ("    Search error: " + $_.Exception.Message); break }

        $vids = @($sResp.items | ForEach-Object { $_.id.videoId }) | Where-Object { $_ }
        if ($vids.Count -eq 0) { break }

        $dUri = 'https://www.googleapis.com/youtube/v3/videos?part=snippet,statistics&id=' + ($vids -join ',') + '&key=' + $YT_KEY
        try { $dResp = Invoke-RestMethod -Uri $dUri -Method Get } catch { break }

        foreach ($item in @($dResp.items)) {
            $vid = $item.id
            if ($existingVidIds.Contains($vid)) { continue }
            $title = [regex]::Replace($item.snippet.title, '[^\x20-\x7E]', '').Trim()
            if (-not $title) { $title = 'Untitled' }
            $views   = if ($item.statistics.viewCount) { [long]$item.statistics.viewCount } else { 0 }
            $pubDate = if ($item.snippet.publishedAt)  { $item.snippet.publishedAt.Substring(0,10) } else { $null }

            $t1List.Add(@{
                channel_id     = $ch.id
                channel_name   = $ch.name
                niche          = 'unassigned'
                title          = $title
                video_id       = $vid
                url            = 'https://www.youtube.com/shorts/' + $vid
                views          = $views
                published_date = $pubDate
            })
            [void]$existingVidIds.Add($vid)
            $newForCh++
        }
        $pageToken = $sResp.nextPageToken; $pageNum++
        Start-Sleep -Milliseconds 200
    } while ($pageToken -and $pageNum -lt 3)

    Write-Host ("    " + $newForCh + " new Shorts queued")

    if ($t1List.Count -ge 200) {
        $r = Insert-Videos $t1List; $t1Ok += $r.ok; $t1Fail += $r.fail
        Write-Host ("    [Batch inserted: " + $r.ok + " ok, " + $r.fail + " fail]")
        $t1List.Clear()
    }
    Start-Sleep -Milliseconds 300
}
if ($t1List.Count -gt 0) { $r = Insert-Videos $t1List; $t1Ok += $r.ok; $t1Fail += $r.fail }
Write-Host ("Task 1 complete: " + $t1Ok + " inserted, " + $t1Fail + " failed")

# ══════════════════════════════════════════════════════════════════════════════
# TASK 2: Existing channels — fetch Shorts published in last 3 days
# ══════════════════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "=== TASK 2: Recent updates (last 3 days) ==="
$cutoff = (Get-Date).AddDays(-3)
Write-Host ("  Cutoff date: " + $cutoff.ToString('yyyy-MM-dd'))

$t2List = [System.Collections.Generic.List[object]]::new()
$t2Ok = 0; $t2Fail = 0

foreach ($ch in $existingChannels) {
    $ytRef = Get-YtRef $ch.url
    if (-not $ytRef) { continue }

    # Derive uploads playlist ID efficiently
    $uploadsId  = $null
    $ytChannelId = $null

    if ($ytRef.type -eq 'id') {
        $ytChannelId = $ytRef.value
        $uploadsId   = 'UU' + $ytChannelId.Substring(2)
    } else {
        try {
            $r = Invoke-RestMethod -Uri ('https://www.googleapis.com/youtube/v3/channels?part=contentDetails&forHandle=' + $ytRef.value + '&key=' + $YT_KEY)
            if (@($r.items).Count -gt 0) {
                $ytChannelId = @($r.items)[0].id
                $uploadsId   = @($r.items)[0].contentDetails.relatedPlaylists.uploads
            }
        } catch { continue }
    }
    if (-not $uploadsId) { continue }

    # Get recent uploads from playlist
    $plUri = 'https://www.googleapis.com/youtube/v3/playlistItems?part=contentDetails&playlistId=' + $uploadsId + '&maxResults=15&key=' + $YT_KEY
    try { $plResp = Invoke-RestMethod -Uri $plUri -Method Get } catch { continue }

    $recentIds = @()
    foreach ($item in @($plResp.items)) {
        $pubAt = $item.contentDetails.videoPublishedAt
        if ($pubAt -and ([datetime]$pubAt) -ge $cutoff) { $recentIds += $item.contentDetails.videoId }
    }
    if ($recentIds.Count -eq 0) { continue }

    # Get details + duration to filter Shorts (<=180s)
    $dUri = 'https://www.googleapis.com/youtube/v3/videos?part=snippet,statistics,contentDetails&id=' + ($recentIds -join ',') + '&key=' + $YT_KEY
    try { $dResp = Invoke-RestMethod -Uri $dUri -Method Get } catch { continue }

    $newForCh = 0
    foreach ($item in @($dResp.items)) {
        $vid = $item.id
        if ($existingVidIds.Contains($vid)) { continue }
        if ((Parse-ISODuration $item.contentDetails.duration) -gt 180) { continue }

        $title   = [regex]::Replace($item.snippet.title, '[^\x20-\x7E]', '').Trim()
        if (-not $title) { $title = 'Untitled' }
        $views   = if ($item.statistics.viewCount) { [long]$item.statistics.viewCount } else { 0 }
        $pubDate = if ($item.snippet.publishedAt)  { $item.snippet.publishedAt.Substring(0,10) } else { $null }

        $t2List.Add(@{
            channel_id     = $ch.id
            channel_name   = $ch.name
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

    if ($newForCh -gt 0) { Write-Host ("  " + $ch.name + ": " + $newForCh + " new") }
    Start-Sleep -Milliseconds 150
}

if ($t2List.Count -gt 0) { $r = Insert-Videos $t2List; $t2Ok += $r.ok; $t2Fail += $r.fail }
Write-Host ("Task 2 complete: " + $t2Ok + " inserted, " + $t2Fail + " failed")

# ── Final count ────────────────────────────────────────────────────────────────
$hdrC = $sbHdr.Clone(); $hdrC['Prefer'] = 'count=exact'
$fc = Invoke-WebRequest -Uri ($SB_URL + '/videos?select=id&limit=1') -Headers $hdrC
Write-Host ""
Write-Host ("=== TOTAL VIDEOS IN DB: " + $fc.Headers['Content-Range'] + " ===")
