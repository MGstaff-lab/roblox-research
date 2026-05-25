$SB_URL  = 'https://ahpzdwemvunyaumrnxal.supabase.co/rest/v1'
$SB_KEY  = 'sb_publishable_NPPdURwPz_DEt6JG--haaw_CThnEoQF'
$DATA_JS = 'C:\Users\RZeva\roblox-research\data.js'

$sbHdr     = @{ apikey = $SB_KEY; Authorization = "Bearer $SB_KEY"; 'Content-Type' = 'application/json' }
$insertHdr = $sbHdr.Clone(); $insertHdr['Prefer'] = 'return=minimal'

Write-Host '=== Sync data.js -> Supabase ==='

# -- 1. Load Supabase channels to get UUIDs --
Write-Host 'Loading Supabase channels...'
$sbChannels = @(Invoke-RestMethod -Uri ($SB_URL + '/channels?select=id,name&limit=1000') -Headers $sbHdr)
Write-Host ('  ' + $sbChannels.Count + ' channels in Supabase')

$chByName = @{}
foreach ($ch in $sbChannels) {
    $key = $ch.name.Trim().ToLower()
    if (-not $chByName.ContainsKey($key)) { $chByName[$key] = $ch.id }
}

# Show first 5 channel names so we can verify matching
Write-Host '  Sample Supabase channel names:'
$sbChannels | Select-Object -First 5 | ForEach-Object { Write-Host ('    [' + $_.name + ']') }

# -- 2. Load existing Supabase video IDs --
Write-Host 'Loading existing Supabase video IDs...'
$existingSbIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$offset = 0
do {
    $batch = @(Invoke-RestMethod -Uri ($SB_URL + '/videos?select=video_id&limit=1000&offset=' + $offset) -Headers $sbHdr)
    foreach ($v in $batch) { if ($v.video_id) { [void]$existingSbIds.Add($v.video_id) } }
    $offset += 1000
} while ($batch.Count -eq 1000)
Write-Host ('  ' + $existingSbIds.Count + ' videos already in Supabase')

# -- 3. Parse VIDEOS from data.js --
Write-Host 'Parsing data.js VIDEOS...'
$lines    = [System.IO.File]::ReadAllLines($DATA_JS, [System.Text.Encoding]::UTF8)
$rows     = [System.Collections.Generic.List[object]]::new()
$inVideos = $false
$noMatch  = [System.Collections.Generic.HashSet[string]]::new()

foreach ($line in $lines) {
    if ($line -match 'const VIDEOS = \[') { $inVideos = $true; continue }
    if (-not $inVideos)                   { continue }
    if ($line -match '^\];')              { break }
    if ($line -notmatch "url: 'https://www\.youtube\.com/shorts/([A-Za-z0-9_-]{11})'") { continue }
    $vidId = $Matches[1]
    if ($existingSbIds.Contains($vidId))  { continue }

    $title   = if ($line -match "title: '(.*?)', channelName:")         { $Matches[1] -replace "\\'", "'" } else { 'Untitled' }
    $chName  = if ($line -match "channelName: '(.*?)', channelUrl:")    { $Matches[1] -replace "\\'", "'" } else { '' }
    $views   = if ($line -match 'views: (\d+)')                         { [long]$Matches[1] }               else { 0 }
    $pubDate = if ($line -match "publishedDate: '(\d{4}-\d{2}-\d{2})'") { $Matches[1] }                    else { $null }
    $niche   = if ($line -match "niche: '([^']+)'")                     { $Matches[1] }                    else { $null }

    $chKey   = $chName.Trim().ToLower()
    $chIdVal = $chByName[$chKey]
    if (-not $chIdVal) {
        foreach ($key in $chByName.Keys) {
            if ($chKey -like ('*' + $key + '*') -or $key -like ('*' + $chKey + '*')) {
                $chIdVal = $chByName[$key]; break
            }
        }
    }
    if (-not $chIdVal) { [void]$noMatch.Add($chName) }

    $rows.Add(@{
        channel_id     = $chIdVal
        channel_name   = $chName
        niche          = $niche
        title          = $title
        video_id       = $vidId
        url            = 'https://www.youtube.com/shorts/' + $vidId
        views          = $views
        published_date = $pubDate
    })
    [void]$existingSbIds.Add($vidId)
}

Write-Host ('  ' + $rows.Count + ' rows to insert')
Write-Host ('  ' + $noMatch.Count + ' channel names not matched (channel_id = null)')
if ($noMatch.Count -gt 0) {
    Write-Host '  Unmatched channels (first 10):'
    $noMatch | Select-Object -First 10 | ForEach-Object { Write-Host ('    [' + $_ + ']') }
}

# -- 4. Diagnostic: try inserting ONE row and print any error --
Write-Host ''
Write-Host '--- Diagnostic: testing 1 row insert ---'
$testRow  = @($rows)[0]
$testBody = [System.Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject @($testRow) -Compress -Depth 5))
Write-Host ('  Payload: ' + [System.Text.Encoding]::UTF8.GetString($testBody).Substring(0, [Math]::Min(300, [System.Text.Encoding]::UTF8.GetString($testBody).Length)))
try {
    $testResp = Invoke-RestMethod -Uri ($SB_URL + '/videos') -Method Post -Headers $insertHdr -Body $testBody
    Write-Host '  TEST INSERT: SUCCESS'
} catch {
    $errBody = $null
    try { $errBody = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream()).ReadToEnd() } catch {}
    Write-Host ('  TEST INSERT FAILED: ' + $_.Exception.Message)
    if ($errBody) { Write-Host ('  Error detail: ' + $errBody) }
    Write-Host ''
    Write-Host 'Fix the error above before bulk inserting. Exiting.'
    exit 1
}

# -- 5. Bulk insert in batches of 100 --
Write-Host ''
Write-Host 'Bulk inserting...'
$ok = 0; $fail = 0
$rowArr = @($rows)

for ($i = 0; $i -lt $rowArr.Count; $i += 100) {
    $end   = [Math]::Min($i + 99, $rowArr.Count - 1)
    $chunk = $rowArr[$i..$end]
    $body  = [System.Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $chunk -Compress -Depth 5))
    try {
        Invoke-RestMethod -Uri ($SB_URL + '/videos') -Method Post -Headers $insertHdr -Body $body | Out-Null
        $ok += $chunk.Count
    } catch {
        foreach ($row in $chunk) {
            $b = [System.Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject @($row) -Compress -Depth 5))
            try {
                Invoke-RestMethod -Uri ($SB_URL + '/videos') -Method Post -Headers $insertHdr -Body $b | Out-Null
                $ok++
            } catch { $fail++ }
        }
    }
    if (($i % 1000) -lt 100) { Write-Host ('  ' + $ok + ' / ' + $rowArr.Count + '...') }
    Start-Sleep -Milliseconds 80
}

Write-Host ''
Write-Host ('=== DONE: ' + $ok + ' inserted, ' + $fail + ' failed ===')
$hdrC = $sbHdr.Clone(); $hdrC['Prefer'] = 'count=exact'
try {
    $fc = Invoke-WebRequest -Uri ($SB_URL + '/videos?select=id&limit=1') -Headers $hdrC
    Write-Host ('Total videos in Supabase: ' + $fc.Headers['Content-Range'])
} catch {}
