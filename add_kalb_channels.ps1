# ── Config ──────────────────────────────────────────────────────────────────
$SB_URL = 'https://ahpzdwemvunyaumrnxal.supabase.co/rest/v1'
$SB_KEY = 'sb_publishable_NPPdURwPz_DEt6JG--haaw_CThnEoQF'
$YT_KEY = 'AIzaSyBX47DSTcr3ZOPtbmYIoG0ECvHw1VHHHis'
$DEFAULT_NICHE = 'Kick a Lucky Block'

$sbHdr = @{
    'apikey'        = $SB_KEY
    'Authorization' = "Bearer $SB_KEY"
    'Content-Type'  = 'application/json'
}

# ── Channel list (YouTube channel IDs from research) ─────────────────────────
$targetChannels = @(
    @{ ytId = 'UCjGUDGiK-wrCNHwqSOqGBQw'; hint = 'GUGA Blox'       },
    @{ ytId = 'UC0halS8nrHxKLW6bfNoBYgQ'; hint = 'BenjaBlox'       },
    @{ ytId = 'UCBuNmnxOzVL_dy7HmO0Mz8Q'; hint = 'Roblox Noob'     },
    @{ ytId = 'UC4XY9C-ZViMEIXT4mDk_h_w'; hint = 'TanRox Roblox'   },
    @{ ytId = 'UCfGwGgBYzp1-TI527dXBBLg'; hint = 'Tung Bro'        },
    @{ ytId = 'UCydV5nlLba9Tw2cq6LMYvLw'; hint = 'Zakke'           },
    @{ ytId = 'UCnEdTerOMGQmH03ahAmxaFA'; hint = 'Potemer'          },
    @{ ytId = 'UCWD4mHtcAGhq1uogzqH0lKg'; hint = 'SpeedAnera'      },
    @{ ytId = 'UC7bpcgyPaq6MihFsGOVJnDw'; hint = 'uniecto'         },
    @{ ytId = 'UCQwDMIf1EAnYulPxuPs63wg'; hint = 'ectoxu'          },
    @{ ytId = 'UCRwBASV3V4d1vdZSFhG_oyw'; hint = 'Zunaki'          },
    @{ ytId = 'UC7X-PQO1vMbCTYx4Co_Ou6w'; hint = 'Robler'          },
    @{ ytId = 'UC3l7Z8jx4AoE1i_S_-Y_4Eg'; hint = 'BeeYT'           },
    @{ ytId = 'UCip7I0kh5W4fbDWgZji2k9g'; hint = 'Fubu'            },
    @{ ytId = 'UCDm64DTeYFT27gRumEwQRCA'; hint = 'JandelBlox'      },
    @{ ytId = 'UCRjiLHnquY_74lOY-eb9fkQ'; hint = 'Sentroxz'        },
    @{ ytId = 'UCGqN5h11C5xsD5x8cILct9g'; hint = 'Sky Roblox'      },
    @{ ytId = 'UCPIzPN_V3Wk2KN5wIK3Kwsg'; hint = 'gattu'           },
    @{ ytId = 'UCnesc0BUlTL8GxfLo3Ov3fw'; hint = 'Nyashka Roblox'  },
    @{ ytId = 'UCMQWI7gKBT87vTkelq9C5YQ'; hint = 'BloxDaily'       },
    @{ ytId = 'UCtbxInwb4hP5lGYEHFeZ1fg'; hint = 'DarkNoobH'       },
    @{ ytId = 'UCt27yjOGB6KqiXXcRrVgrLg'; hint = 'BaconBlocks'     },
    @{ ytId = 'UC3WBAnj-fEBCOpF9TTA7xdw'; hint = 'Feros'           },
    @{ ytId = 'UCx43wRV_5eVAu2ah2aR-3NQ'; hint = 'Raynoo'          },
    @{ ytId = 'UCwkDYwR6NT9KhQJA0ZQ9jBw'; hint = 'FixEye Roblox'   },
    @{ ytId = 'UCrgR_3iaComosA0r_9hW9fA'; hint = 'Gare'            },
    @{ ytId = 'UCDz9PMr9ILTkPCqqTPv3eLA'; hint = 'DiscoFlake'      },
    @{ ytId = 'UCEjWELI73VOM0gE2ePK_hdA'; hint = 'Ajeet Gaming'    }
)

# ── Niche assignment ─────────────────────────────────────────────────────────
function Get-VideoNiche($title) {
    $t = $title.ToLower()
    if ($t -match 'kick.*lucky|lucky.*kick|kickalucky|kick.*block') { return 'Kick a Lucky Block' }
    if ($t -match 'tsunami')     { return 'Escape Tsunami Brainrot' }
    if ($t -match 'troll tower') { return 'Troll Tower' }
    if ($t -match '99 nights')   { return '99 Nights in the Forest' }
    return 'Kick a Lucky Block'   # default — these are all Kick a Lucky Block channels
}

# ── Shorts scraper ───────────────────────────────────────────────────────────
function Get-ChannelShorts($ytChannelId) {
    $url = 'https://www.youtube.com/channel/' + $ytChannelId + '/shorts'
    try {
        $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 25 `
                    -Headers @{ 'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120 Safari/537.36' }
    } catch { Write-Host "  [HTTP error] $ytChannelId : $_"; return @() }

    $m = [regex]::Match($resp.Content, 'var ytInitialData\s*=\s*(\{.+?\});\s*</script>')
    if (-not $m.Success) {
        $m = [regex]::Match($resp.Content, 'ytInitialData\s*=\s*(\{.+?\});\s*(?:var |</script>)')
    }
    if (-not $m.Success) { Write-Host "  [no ytInitialData] $ytChannelId"; return @() }

    try { $data = $m.Groups[1].Value | ConvertFrom-Json }
    catch { Write-Host "  [JSON parse error] $ytChannelId"; return @() }

    $list = [System.Collections.Generic.List[object]]::new()
    try {
        $tabs = $data.contents.twoColumnBrowseResultsRenderer.tabs
        $shortsTab = $tabs | Where-Object { $_.tabRenderer.title -eq 'Shorts' }
        if (-not $shortsTab) { Write-Host "  [no Shorts tab] $ytChannelId"; return @() }

        $contents = @($shortsTab.tabRenderer.content.richGridRenderer.contents)
        foreach ($item in $contents) {
            $vm = $item.richItemRenderer.content.shortsLockupViewModel
            if (-not $vm) { continue }
            $videoId = $vm.onTap.innertubeCommand.reelWatchEndpoint.videoId
            if (-not $videoId) { continue }

            $rawTitle = $vm.overlayMetadata.primaryText.content
            $title = [regex]::Replace(($rawTitle -replace '\s+', ' ').Trim(), '[^\x20-\x7E]', '').Trim()
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
            $list.Add([PSCustomObject]@{
                video_id = $videoId
                title    = $title
                views    = $views
                url      = 'https://www.youtube.com/shorts/' + $videoId
            })
        }
    } catch { Write-Host "  [parse error] $ytChannelId : $_" }

    return ,$list
}

# ═══════════════════════════════════════════════════════════════════════════
# STEP 1 — Fetch all 28 channels from YouTube Data API (one batch call)
# ═══════════════════════════════════════════════════════════════════════════
Write-Host "`n=== STEP 1: Fetching channel info from YouTube API ==="
$ytIds = ($targetChannels | ForEach-Object { $_.ytId }) -join ','
$ytResp = Invoke-RestMethod -Uri ('https://www.googleapis.com/youtube/v3/channels?part=snippet,statistics&id=' + $ytIds + '&maxResults=50&key=' + $YT_KEY) -Method Get
$ytMap = @{}
foreach ($item in @($ytResp.items)) {
    $ytMap[$item.id] = $item
}
Write-Host "YouTube API returned info for $($ytMap.Count) channels."

# ═══════════════════════════════════════════════════════════════════════════
# STEP 2 — Load existing DB channels, match, insert new ones
# ═══════════════════════════════════════════════════════════════════════════
Write-Host "`n=== STEP 2: Syncing channels to database ==="
$dbChannels = @(Invoke-RestMethod -Uri ($SB_URL + '/channels?select=id,name,url&limit=1000') -Headers $sbHdr)

# Index DB channels by name (lowercase) and by any UC... id found in URL
$dbByName  = @{}
$dbByYtId  = @{}
foreach ($ch in $dbChannels) {
    $dbByName[$ch.name.ToLower()] = $ch
    if ($ch.url -match '(UC[A-Za-z0-9_-]{22})') { $dbByYtId[$Matches[1]] = $ch }
}

# channelLookup: ytChannelId → DB row { id, name }
$channelLookup = @{}

$added = 0; $skipped = 0
foreach ($tc in $targetChannels) {
    $ytId  = $tc.ytId
    $ytInfo = $ytMap[$ytId]

    # Try to find in DB
    $existing = $null
    if ($dbByYtId.ContainsKey($ytId))         { $existing = $dbByYtId[$ytId] }
    elseif ($ytInfo) {
        $nameLower = $ytInfo.snippet.title.ToLower()
        if ($dbByName.ContainsKey($nameLower)) { $existing = $dbByName[$nameLower] }
    }

    if ($existing) {
        $channelLookup[$ytId] = $existing
        $skipped++
        Write-Host "  EXISTS : $($existing.name)"
        continue
    }

    # Not in DB — insert
    if (-not $ytInfo) { Write-Host "  SKIP (no YT info): $($tc.hint)"; continue }

    $name  = $ytInfo.snippet.title
    $subs  = if ($ytInfo.statistics.subscriberCount) { [long]$ytInfo.statistics.subscriberCount } else { $null }
    $start = if ($ytInfo.snippet.publishedAt) { $ytInfo.snippet.publishedAt.Substring(0,10) } else { $null }
    $handle = $ytInfo.snippet.customUrl   # e.g. @gugablox
    $chUrl  = if ($handle) { 'https://youtube.com/' + $handle } else { 'https://youtube.com/channel/' + $ytId }

    $record = @{ name = $name; url = $chUrl; niche = $DEFAULT_NICHE; subscribers = $subs; date_started = $start }
    $body   = $record | ConvertTo-Json -Compress
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)

    try {
        $ins = Invoke-RestMethod -Uri ($SB_URL + '/channels') -Method Post -Headers ($sbHdr + @{ 'Prefer' = 'return=representation' }) -Body $bodyBytes
        $newRow = @($ins)[0]
        $channelLookup[$ytId] = $newRow
        $added++
        Write-Host "  ADDED  : $name"
    } catch {
        Write-Host "  ERROR adding $name : $_"
    }
}
Write-Host "Channels: $added added, $skipped already existed."

# ═══════════════════════════════════════════════════════════════════════════
# STEP 3 — Load all existing video_ids from DB to skip duplicates
# ═══════════════════════════════════════════════════════════════════════════
Write-Host "`n=== STEP 3: Loading existing video IDs from DB ==="
$existingVidIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$offset = 0
do {
    $vBatch = @(Invoke-RestMethod -Uri ($SB_URL + '/videos?select=video_id&limit=1000&offset=' + $offset) -Headers $sbHdr)
    foreach ($v in $vBatch) { if ($v.video_id) { $existingVidIds.Add($v.video_id) | Out-Null } }
    $offset += 1000
} while ($vBatch.Count -eq 1000)
Write-Host "Loaded $($existingVidIds.Count) existing video IDs."

# ═══════════════════════════════════════════════════════════════════════════
# STEP 4 — Scrape Shorts for each channel
# ═══════════════════════════════════════════════════════════════════════════
Write-Host "`n=== STEP 4: Scraping Shorts tabs ==="
# allNewVideos: list of records ready to insert (minus published_date, added in step 5)
$allNewVideos = [System.Collections.Generic.List[object]]::new()

foreach ($tc in $targetChannels) {
    $ytId = $tc.ytId
    $dbRow = $channelLookup[$ytId]
    if (-not $dbRow) { Write-Host "  SKIP (no DB row): $($tc.hint)"; continue }

    Write-Host "  Scraping: $($dbRow.name) ..."
    $shorts = @(Get-ChannelShorts $ytId)
    $newCount = 0
    foreach ($s in $shorts) {
        if ($existingVidIds.Contains($s.video_id)) { continue }
        $allNewVideos.Add([PSCustomObject]@{
            channel_id   = $dbRow.id
            channel_name = $dbRow.name
            niche        = Get-VideoNiche $s.title
            title        = $s.title
            video_id     = $s.video_id
            url          = $s.url
            views        = $s.views
            published_date = $null
        })
        $existingVidIds.Add($s.video_id) | Out-Null
        $newCount++
    }
    Write-Host "    $($shorts.Count) scraped, $newCount new"
    Start-Sleep -Milliseconds 800
}
Write-Host "Total new videos to insert: $($allNewVideos.Count)"

# ═══════════════════════════════════════════════════════════════════════════
# STEP 5 — Fetch published dates from YouTube Data API
# ═══════════════════════════════════════════════════════════════════════════
Write-Host "`n=== STEP 5: Fetching published dates ==="
$dateMap = @{}
$batchSz = 50
for ($i = 0; $i -lt $allNewVideos.Count; $i += $batchSz) {
    $chunk   = @($allNewVideos[$i..([Math]::Min($i + $batchSz - 1, $allNewVideos.Count - 1))])
    $idList  = ($chunk | ForEach-Object { $_.video_id }) -join ','
    $ytUri   = 'https://www.googleapis.com/youtube/v3/videos?part=snippet&maxResults=50&key=' + $YT_KEY + '&id=' + $idList
    try {
        $ytR = Invoke-RestMethod -Uri $ytUri -Method Get
        foreach ($item in @($ytR.items)) {
            if ($item.snippet.publishedAt) {
                $dateMap[$item.id] = $item.snippet.publishedAt.Substring(0,10)
            }
        }
    } catch { Write-Host "  YT date error at $i : $_" }
    Start-Sleep -Milliseconds 100
}
# Apply dates
foreach ($v in $allNewVideos) {
    if ($dateMap.ContainsKey($v.video_id)) { $v.published_date = $dateMap[$v.video_id] }
}
Write-Host "Got published dates for $($dateMap.Count) / $($allNewVideos.Count) videos."

# ═══════════════════════════════════════════════════════════════════════════
# STEP 6 — Insert videos in batches of 50
# ═══════════════════════════════════════════════════════════════════════════
Write-Host "`n=== STEP 6: Inserting videos ==="
$insertHdr = $sbHdr.Clone()
$insertHdr['Prefer'] = 'return=minimal'

$totalInserted = 0; $totalFailed = 0
for ($i = 0; $i -lt $allNewVideos.Count; $i += 50) {
    $chunk = @($allNewVideos[$i..([Math]::Min($i + 49, $allNewVideos.Count - 1))])
    $rows  = $chunk | ForEach-Object {
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
    }
    $body      = ConvertTo-Json -InputObject @($rows) -Compress -Depth 5
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)

    try {
        Invoke-RestMethod -Uri ($SB_URL + '/videos') -Method Post -Headers $insertHdr -Body $bodyBytes | Out-Null
        $totalInserted += $chunk.Count
    } catch {
        # Try one-by-one on batch failure
        foreach ($row in $chunk) {
            $oneBody  = ConvertTo-Json -InputObject @($row) -Compress -Depth 5
            $oneBytes = [System.Text.Encoding]::UTF8.GetBytes($oneBody)
            try {
                Invoke-RestMethod -Uri ($SB_URL + '/videos') -Method Post -Headers $insertHdr -Body $oneBytes | Out-Null
                $totalInserted++
            } catch { $totalFailed++ }
        }
    }

    if (($i / 50) % 10 -eq 0 -and $i -gt 0) {
        Write-Host "  Inserted $totalInserted so far..."
    }
}

Write-Host ""
Write-Host "=== DONE ==="
Write-Host "Channels added   : $added"
Write-Host "Channels existed : $skipped"
Write-Host "Videos inserted  : $totalInserted"
Write-Host "Videos failed    : $totalFailed"
