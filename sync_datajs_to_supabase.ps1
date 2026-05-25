$SB_URL  = 'https://ahpzdwemvunyaumrnxal.supabase.co/rest/v1'
$SB_KEY  = 'sb_publishable_NPPdURwPz_DEt6JG--haaw_CThnEoQF'
$DATA_JS = 'C:\Users\RZeva\roblox-research\data.js'

$sbHdr     = @{ apikey = $SB_KEY; Authorization = "Bearer $SB_KEY"; 'Content-Type' = 'application/json' }
$upsertHdr = $sbHdr.Clone()
$upsertHdr['Prefer'] = 'resolution=ignore-duplicates,return=minimal'

Write-Host '=== Sync data.js -> Supabase ==='

# -- 1. Parse data.js with Node.js --
Write-Host 'Parsing data.js via Node...'
$nodeScript = @'
var src = require('fs').readFileSync(process.argv[1],'utf8');
// Replace const with var so eval works in Node global scope
var modified = src.replace(/^const CHANNELS/m,'var CHANNELS').replace(/^const VIDEOS/m,'var VIDEOS');
eval(modified);
// Output as JSON
process.stdout.write(JSON.stringify({ channels: CHANNELS, videos: VIDEOS }));
'@
$tmpNode = [System.IO.Path]::GetTempFileName() + '.js'
[System.IO.File]::WriteAllText($tmpNode, $nodeScript, [System.Text.Encoding]::UTF8)

$jsonOut = & node $tmpNode $DATA_JS
Remove-Item $tmpNode -Force

if (-not $jsonOut) {
    Write-Host 'ERROR: node failed to parse data.js. Make sure Node.js is installed.'
    exit 1
}

$parsed   = $jsonOut | ConvertFrom-Json
$jsVideos = @($parsed.videos)
Write-Host ('  data.js videos: ' + $jsVideos.Count)

# -- 2. Load existing Supabase channels (to get UUIDs) --
Write-Host 'Loading Supabase channels...'
$sbChannels = @(Invoke-RestMethod -Uri ($SB_URL + '/channels?select=id,name,url&limit=1000') -Headers $sbHdr)
Write-Host ('  Supabase channels: ' + $sbChannels.Count)

# Build lookup: channel name (lowercase) -> supabase UUID
$chByName = @{}
foreach ($ch in $sbChannels) {
    $key = $ch.name.Trim().ToLower()
    $chByName[$key] = $ch.id
}

# -- 3. Load existing video_ids from Supabase (to skip duplicates) --
Write-Host 'Loading existing Supabase video IDs...'
$existingSbIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$offset = 0
do {
    $batch = @(Invoke-RestMethod -Uri ($SB_URL + '/videos?select=video_id&limit=1000&offset=' + $offset) -Headers $sbHdr)
    foreach ($v in $batch) { if ($v.video_id) { [void]$existingSbIds.Add($v.video_id) } }
    $offset += 1000
} while ($batch.Count -eq 1000)
Write-Host ('  Existing Supabase video IDs: ' + $existingSbIds.Count)

# -- 4. Build insert rows --
Write-Host 'Building insert rows...'
$rows        = [System.Collections.Generic.List[object]]::new()
$noChannelId = [System.Collections.Generic.List[string]]::new()

foreach ($v in $jsVideos) {
    # Extract video_id from URL
    $vidId = $null
    if ($v.url -match '/shorts/([A-Za-z0-9_-]{11})') { $vidId = $Matches[1] }
    elseif ($v.url -match 'v=([A-Za-z0-9_-]{11})') { $vidId = $Matches[1] }
    if (-not $vidId) { continue }

    # Skip if already in Supabase
    if ($existingSbIds.Contains($vidId)) { continue }

    # Look up channel UUID
    $chName  = ($v.channelName + '').Trim()
    $chIdVal = $chByName[$chName.ToLower()]

    if (-not $chIdVal) {
        # Try partial match (channel names may differ slightly)
        foreach ($key in $chByName.Keys) {
            if ($key -like ('*' + $chName.ToLower() + '*') -or $chName.ToLower() -like ('*' + $key + '*')) {
                $chIdVal = $chByName[$key]
                break
            }
        }
    }

    if (-not $chIdVal -and -not $noChannelId.Contains($chName)) {
        $noChannelId.Add($chName)
    }

    $pubDate = if ($v.publishedDate) { $v.publishedDate } else { $null }
    $views   = if ($v.views)         { [long]$v.views }   else { 0 }
    $niche   = if ($v.niche)         { $v.niche }          else { $null }

    $rows.Add(@{
        channel_id     = $chIdVal
        channel_name   = $chName
        niche          = $niche
        title          = $v.title
        video_id       = $vidId
        url            = $v.url
        views          = $views
        published_date = $pubDate
    })
    [void]$existingSbIds.Add($vidId)
}

Write-Host ('  Rows to insert : ' + $rows.Count)
Write-Host ('  Already in SB  : ' + ($jsVideos.Count - $rows.Count - ($jsVideos.Count - $existingSbIds.Count + $existingSbIds.Count - $jsVideos.Count)))

if ($noChannelId.Count -gt 0) {
    Write-Host ('  WARNING: ' + $noChannelId.Count + ' channel names not matched to a Supabase UUID:')
    $noChannelId | Select-Object -First 20 | ForEach-Object { Write-Host ('    ' + $_) }
    Write-Host '  These videos will insert with channel_id = null.'
}

# -- 5. Insert in batches of 100 --
Write-Host ''
Write-Host 'Inserting into Supabase...'
$ok = 0; $fail = 0
$rowList = @($rows)

for ($i = 0; $i -lt $rowList.Count; $i += 100) {
    $end   = [Math]::Min($i + 99, $rowList.Count - 1)
    $chunk = $rowList[$i..$end]
    $body  = [System.Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $chunk -Compress -Depth 5))
    try {
        Invoke-RestMethod -Uri ($SB_URL + '/videos') -Method Post -Headers $upsertHdr -Body $body | Out-Null
        $ok += $chunk.Count
        if (($i / 100) % 10 -eq 0) {
            Write-Host ('  ' + $ok + ' / ' + $rowList.Count + ' inserted...')
        }
    } catch {
        # Retry row by row
        foreach ($row in $chunk) {
            $b = [System.Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject @($row) -Compress -Depth 5))
            try {
                Invoke-RestMethod -Uri ($SB_URL + '/videos') -Method Post -Headers $upsertHdr -Body $b | Out-Null
                $ok++
            } catch {
                $fail++
            }
        }
    }
    Start-Sleep -Milliseconds 100
}

Write-Host ''
Write-Host ('=== DONE: ' + $ok + ' inserted, ' + $fail + ' failed ===')

# Final count
$hdrC = $sbHdr.Clone(); $hdrC['Prefer'] = 'count=exact'
try {
    $fc = Invoke-WebRequest -Uri ($SB_URL + '/videos?select=id&limit=1') -Headers $hdrC
    Write-Host ('Total videos in Supabase: ' + $fc.Headers['Content-Range'])
} catch {}
