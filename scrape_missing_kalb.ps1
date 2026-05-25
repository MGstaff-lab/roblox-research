$SB_URL = 'https://ahpzdwemvunyaumrnxal.supabase.co/rest/v1'
$SB_KEY = 'sb_publishable_NPPdURwPz_DEt6JG--haaw_CThnEoQF'
$YT_KEY = 'AIzaSyBX47DSTcr3ZOPtbmYIoG0ECvHw1VHHHis'

$sbHdr = @{
    'apikey'        = $SB_KEY
    'Authorization' = "Bearer $SB_KEY"
    'Content-Type'  = 'application/json'
}
$insertHdr = $sbHdr.Clone(); $insertHdr['Prefer'] = 'return=minimal'

# Channels that got 0 videos due to quota (ytId -> DB channel name)
$missing = @(
    @{ ytId = 'UCRjiLHnquY_74lOY-eb9fkQ'; name = 'Sentroxz'        },
    @{ ytId = 'UCPIzPN_V3Wk2KN5wIK3Kwsg'; name = 'gattu'           },
    @{ ytId = 'UCnesc0BUlTL8GxfLo3Ov3fw'; name = 'Nyashka Roblox'  },
    @{ ytId = 'UCMQWI7gKBT87vTkelq9C5YQ'; name = 'BloxDaily'       },
    @{ ytId = 'UCtbxInwb4hP5lGYEHFeZ1fg'; name = 'DarkNoobH'       },
    @{ ytId = 'UCt27yjOGB6KqiXXcRrVgrLg'; name = 'BaconBlocks'     },
    @{ ytId = 'UC3WBAnj-fEBCOpF9TTA7xdw'; name = 'Feros'           },
    @{ ytId = 'UCx43wRV_5eVAu2ah2aR-3NQ'; name = 'Raynoo'          },
    @{ ytId = 'UCwkDYwR6NT9KhQJA0ZQ9jBw'; name = 'FixEye Roblox'   },
    @{ ytId = 'UCrgR_3iaComosA0r_9hW9fA'; name = 'Gare'            },
    @{ ytId = 'UCEjWELI73VOM0gE2ePK_hdA'; name = 'Ajeet Gaming'    }
)

function Get-VideoNiche($title) {
    $t = $title.ToLower()
    if ($t -match 'kick.*lucky|lucky.*kick|kickalucky|lucky.block') { return 'Kick a Lucky Block' }
    if ($t -match 'tsunami')     { return 'Escape Tsunami Brainrot' }
    if ($t -match 'troll tower') { return 'Troll Tower' }
    if ($t -match '99 nights')   { return '99 Nights in the Forest' }
    return 'Kick a Lucky Block'
}

function Get-ChannelShorts($ytChannelId) {
    $url = 'https://www.youtube.com/channel/' + $ytChannelId + '/shorts'
    try {
        $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 25 `
            -Headers @{ 'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124 Safari/537.36'; 'Accept-Language' = 'en-US,en;q=0.9' }
    } catch { Write-Host ("  HTTP error: " + $_.Exception.Message); return @() }

    # Try multiple regex patterns for ytInitialData
    $patterns = @(
        'var ytInitialData\s*=\s*(\{.+?\});\s*</script>',
        'ytInitialData\s*=\s*(\{.+?\});\s*var ',
        'ytInitialData\s*=\s*(\{.+?\});\s*</script>'
    )
    $json = $null
    foreach ($pat in $patterns) {
        $m = [regex]::Match($resp.Content, $pat, [System.Text.RegularExpressions.RegexOptions]::Singleline)
        if ($m.Success) { $json = $m.Groups[1].Value; break }
    }
    if (-not $json) { Write-Host "  [no ytInitialData]"; return @() }

    try { $data = $json | ConvertFrom-Json } catch { Write-Host "  [JSON error]"; return @() }

    $list = [System.Collections.Generic.List[object]]::new()
    try {
        $tabs = $data.contents.twoColumnBrowseResultsRenderer.tabs
        $shortsTab = $null
        foreach ($tab in @($tabs)) {
            if ($tab.tabRenderer -and $tab.tabRenderer.title -eq 'Shorts') { $shortsTab = $tab; break }
        }
        if (-not $shortsTab) { Write-Host "  [no Shorts tab]"; return @() }

        $contents = $shortsTab.tabRenderer.content.richGridRenderer.contents
        foreach ($item in @($contents)) {
            $vm = $null
            if ($item.richItemRenderer) { $vm = $item.richItemRenderer.content.shortsLockupViewModel }
            if (-not $vm) { continue }

            $videoId = $vm.onTap.innertubeCommand.reelWatchEndpoint.videoId
            if (-not $videoId) { continue }

            $rawTitle = $vm.overlayMetadata.primaryText.content
            $title    = [regex]::Replace(($rawTitle -replace '\s+',' ').Trim(), '[^\x20-\x7E]', '').Trim()
            if (-not $title) { $title = 'Untitled' }

            $viewsText = $vm.overlayMetadata.secondaryText.content
            $views = 0
            if ($viewsText -match '([\d.]+)\s*([KMBkmb]?)') {
                $num = [double]$Matches[1]
                switch ($Matches[2].ToUpper()) {
                    'K' { $views = [long]($num * 1e3) }
                    'M' { $views = [long]($num * 1e6) }
                    'B' { $views = [long]($num * 1e9) }
                    default { $views = [long]$num }
                }
            }
            $list.Add([PSCustomObject]@{ video_id = $videoId; title = $title; views = $views })
        }
    } catch { Write-Host ("  [parse error]: " + $_.Exception.Message) }

    return $list
}

# Load DB channel lookup (ytId -> DB id)
$rawDb = Invoke-RestMethod -Uri ($SB_URL + '/channels?select=id,name,url&limit=1000') -Headers $sbHdr
$allDbChannels = @($rawDb)
$channelLookup = @{}
foreach ($ch in $allDbChannels) {
    foreach ($m in $missing) {
        if ($ch.url -and $ch.url.ToLower() -match [regex]::Escape($m.ytId)) { $channelLookup[$m.ytId] = $ch; break }
        if ($ch.name -and $ch.url -and $ch.url.ToLower() -match ($m.name.ToLower() -replace ' ','')) { $channelLookup[$m.ytId] = $ch; break }
        if ($ch.name.Trim().ToLower() -eq $m.name.ToLower()) { $channelLookup[$m.ytId] = $ch; break }
    }
}
# Also match by ytId in URL directly
foreach ($m in $missing) {
    if ($channelLookup[$m.ytId]) { continue }
    foreach ($ch in $allDbChannels) {
        if ($ch.url -and $ch.url -match $m.ytId) { $channelLookup[$m.ytId] = $ch; break }
    }
}

# Load existing video IDs
$existingVidIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$offset = 0
do {
    $vBatch = Invoke-RestMethod -Uri ($SB_URL + '/videos?select=video_id&limit=1000&offset=' + $offset) -Headers $sbHdr
    foreach ($v in @($vBatch)) { if ($v.video_id) { [void]$existingVidIds.Add($v.video_id) } }
    $bc = @($vBatch).Count; $offset += 1000
} while ($bc -eq 1000)
Write-Host ("Existing video IDs: " + $existingVidIds.Count)

# Scrape and collect
$allNew = [System.Collections.Generic.List[object]]::new()

foreach ($m in $missing) {
    $dbRow = $channelLookup[$m.ytId]
    if (-not $dbRow) {
        # Try to find by name substring
        foreach ($ch in $allDbChannels) {
            if ($ch.name -and $ch.name.ToLower() -match ($m.name.ToLower().Split(' ')[0])) { $dbRow = $ch; break }
        }
    }
    if (-not $dbRow) { Write-Host ("SKIP (no DB row): " + $m.name); continue }

    Write-Host ("Scraping: " + $dbRow.name + " (" + $m.ytId + ")")
    $shorts = @(Get-ChannelShorts $m.ytId)
    $newCount = 0
    foreach ($s in $shorts) {
        if ($existingVidIds.Contains($s.video_id)) { continue }
        $allNew.Add([PSCustomObject]@{
            channel_id   = $dbRow.id
            channel_name = $dbRow.name
            niche        = Get-VideoNiche $s.title
            title        = $s.title
            video_id     = $s.video_id
            url          = 'https://www.youtube.com/shorts/' + $s.video_id
            views        = $s.views
        })
        [void]$existingVidIds.Add($s.video_id)
        $newCount++
    }
    Write-Host ("  " + $shorts.Count + " scraped, " + $newCount + " new")
    Start-Sleep -Milliseconds 1000
}

Write-Host ("Total to insert: " + $allNew.Count)

# Fetch published dates for the scraped videos
if ($allNew.Count -gt 0) {
    Write-Host "Fetching published dates..."
    $dateMap = @{}
    for ($i = 0; $i -lt $allNew.Count; $i += 50) {
        $end    = [Math]::Min($i + 49, $allNew.Count - 1)
        $chunk  = @($allNew[$i..$end])
        $idList = ($chunk | ForEach-Object { $_.video_id }) -join ','
        $ytUri  = 'https://www.googleapis.com/youtube/v3/videos?part=snippet&maxResults=50&key=' + $YT_KEY + '&id=' + $idList
        try {
            $ytR = Invoke-RestMethod -Uri $ytUri -Method Get
            foreach ($item in @($ytR.items)) {
                if ($item.snippet.publishedAt) { $dateMap[$item.id] = $item.snippet.publishedAt.Substring(0,10) }
            }
        } catch { Write-Host ("  Date fetch error: " + $_.Exception.Message) }
        Start-Sleep -Milliseconds 150
    }
    Write-Host ("Got dates for " + $dateMap.Count + " videos.")

    # Insert
    $totalOk = 0; $totalFail = 0
    for ($i = 0; $i -lt $allNew.Count; $i += 50) {
        $end   = [Math]::Min($i + 49, $allNew.Count - 1)
        $chunk = @($allNew[$i..$end])
        $rows  = @($chunk | ForEach-Object {
            @{
                channel_id     = $_.channel_id
                channel_name   = $_.channel_name
                niche          = $_.niche
                title          = $_.title
                video_id       = $_.video_id
                url            = $_.url
                views          = $_.views
                published_date = if ($dateMap[$_.video_id]) { $dateMap[$_.video_id] } else { $null }
            }
        })
        $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $rows -Compress -Depth 5))
        try {
            Invoke-RestMethod -Uri ($SB_URL + '/videos') -Method Post -Headers $insertHdr -Body $bodyBytes | Out-Null
            $totalOk += $chunk.Count
        } catch {
            foreach ($row in $chunk) {
                $ob = [System.Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject @($row) -Compress -Depth 5))
                try { Invoke-RestMethod -Uri ($SB_URL + '/videos') -Method Post -Headers $insertHdr -Body $ob | Out-Null; $totalOk++ }
                catch { $totalFail++ }
            }
        }
    }
    Write-Host ("Inserted: " + $totalOk + "  Failed: " + $totalFail)
}

$hdrC = $sbHdr.Clone(); $hdrC['Prefer'] = 'count=exact'
$fc = Invoke-WebRequest -Uri ($SB_URL + '/videos?select=id&limit=1') -Headers $hdrC
Write-Host ("Total videos in DB: " + $fc.Headers['Content-Range'])
