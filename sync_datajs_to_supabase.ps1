$SB_URL  = 'https://ahpzdwemvunyaumrnxal.supabase.co/rest/v1'
$SB_KEY  = 'sb_publishable_NPPdURwPz_DEt6JG--haaw_CThnEoQF'
$DATA_JS = 'C:\Users\RZeva\roblox-research\data.js'

$sbHdr     = @{ apikey = $SB_KEY; Authorization = "Bearer $SB_KEY"; 'Content-Type' = 'application/json' }
$insertHdr = $sbHdr.Clone(); $insertHdr['Prefer'] = 'return=minimal'

# Proper JSON-array fetcher for PS 5.1
function SB-Get($path) {
    $r = Invoke-WebRequest -Uri ($SB_URL + $path) -Headers $sbHdr -UseBasicParsing
    $parsed = $r.Content | ConvertFrom-Json
    # ConvertFrom-Json in PS 5.1 returns a single PSCustomObject for arrays —
    # force it into a proper array
    return @($parsed)
}

Write-Host '=== Sync data.js -> Supabase ==='

# -- 1. Load channel name -> UUID map --
Write-Host 'Loading Supabase channels...'
$sbChannels = SB-Get '/channels?select=id,name&limit=1000'
Write-Host ('  ' + $sbChannels.Count + ' channels')

$chByName = @{}
foreach ($ch in $sbChannels) {
    if (-not $ch.name) { continue }
    $key = [string]$ch.name.Trim().ToLower()
    $val = [string]$ch.id
    if ($key -and $val -and -not $chByName.ContainsKey($key)) {
        $chByName[$key] = $val
    }
}
Write-Host ('  ' + $chByName.Count + ' unique channel name keys built')
# Show a sample so we can verify
$chByName.Keys | Select-Object -First 5 | ForEach-Object { Write-Host ('    [' + $_ + '] -> ' + $chByName[$_].Substring(0,8) + '...') }

# -- 2. Load existing video IDs --
Write-Host 'Loading existing Supabase video IDs...'
$existingSbIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$offset = 0
do {
    $batch = SB-Get ('/videos?select=video_id&limit=1000&offset=' + $offset)
    foreach ($v in $batch) { if ($v.video_id) { [void]$existingSbIds.Add([string]$v.video_id) } }
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
    if ($existingSbIds.Contains($vidId)) { continue }

    $title   = if ($line -match "title: '(.*?)', channelName:")         { $Matches[1] -replace "\\'", "'" } else { 'Untitled' }
    $chName  = if ($line -match "channelName: '(.*?)', channelUrl:")    { $Matches[1] -replace "\\'", "'" } else { '' }
    $views   = if ($line -match 'views: (\d+)')                         { [long]$Matches[1] }               else { 0 }
    $pubDate = if ($line -match "publishedDate: '(\d{4}-\d{2}-\d{2})'") { $Matches[1] }                    else { $null }
    $niche   = if ($line -match "niche: '([^']+)'")                     { $Matches[1] }                    else { $null }

    # Exact name lookup first, then prefix match (no wildcard partial match)
    $chKey   = [string]$chName.Trim().ToLower()
    $chIdVal = $null
    if ($chByName.ContainsKey($chKey)) {
        $chIdVal = $chByName[$chKey]
    } else {
        # Try case-insensitive starts-with match only
        foreach ($key in $chByName.Keys) {
            if ($chKey -eq $key) { $chIdVal = $chByName[$key]; break }
        }
    }
    if (-not $chIdVal) { [void]$noMatch.Add($chName) }

    # Build row — only include channel_id if we have a real UUID string
    $row = [ordered]@{
        channel_name   = [string]$chName
        niche          = $niche
        title          = [string]$title
        video_id       = [string]$vidId
        url            = 'https://www.youtube.com/shorts/' + $vidId
        views          = [long]$views
        published_date = $pubDate
    }
    if ($chIdVal -and $chIdVal -match '^[0-9a-f-]{36}$') {
        $row['channel_id'] = [string]$chIdVal
    }

    $rows.Add($row)
    [void]$existingSbIds.Add($vidId)
}

Write-Host ('  ' + $rows.Count + ' rows to insert')
Write-Host ('  ' + $noMatch.Count + ' channel names not matched (inserting without channel_id)')
if ($noMatch.Count -gt 0 -and $noMatch.Count -le 15) {
    $noMatch | ForEach-Object { Write-Host ('    [' + $_ + ']') }
}

# -- 4. Diagnostic: test one row --
Write-Host ''
Write-Host '--- Testing 1 row insert ---'
$testRow  = @($rows)[0]
$testJson = ConvertTo-Json -InputObject @($testRow) -Compress -Depth 5
Write-Host ('  Payload: ' + $testJson.Substring(0, [Math]::Min(250, $testJson.Length)))
$testBody = [System.Text.Encoding]::UTF8.GetBytes($testJson)
try {
    Invoke-RestMethod -Uri ($SB_URL + '/videos') -Method Post -Headers $insertHdr -Body $testBody | Out-Null
    Write-Host '  TEST INSERT: SUCCESS'
} catch {
    $errBody = $null
    try {
        $stream = $_.Exception.Response.GetResponseStream()
        $errBody = [System.IO.StreamReader]::new($stream).ReadToEnd()
    } catch {}
    Write-Host ('  TEST INSERT FAILED: ' + $_.Exception.Message)
    if ($errBody) { Write-Host ('  Error detail: ' + $errBody) }
    Write-Host 'Exiting. Fix the error above first.'
    exit 1
}

# -- 5. Bulk insert in batches of 100 --
Write-Host ''
Write-Host 'Bulk inserting...'
$ok = 0; $fail = 0
$rowArr = @($rows)
# Skip index 0 - already inserted in test
for ($i = 1; $i -lt $rowArr.Count; $i += 100) {
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
    if ($ok -gt 0 -and ($ok % 1000) -lt 100) { Write-Host ('  ' + $ok + ' / ' + ($rowArr.Count - 1) + '...') }
    Start-Sleep -Milliseconds 60
}
$ok++ # count the test row

Write-Host ''
Write-Host ('=== DONE: ' + $ok + ' inserted, ' + $fail + ' failed ===')
$hdrC = $sbHdr.Clone(); $hdrC['Prefer'] = 'count=exact'
try {
    $fc = Invoke-WebRequest -Uri ($SB_URL + '/videos?select=id&limit=1') -Headers $hdrC -UseBasicParsing
    Write-Host ('Total videos now in Supabase: ' + $fc.Headers['Content-Range'])
} catch {}
