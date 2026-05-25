$SB_URL  = 'https://ahpzdwemvunyaumrnxal.supabase.co/rest/v1'
$SB_KEY  = 'sb_publishable_NPPdURwPz_DEt6JG--haaw_CThnEoQF'
$DATA_JS = 'C:\Users\RZeva\roblox-research\data.js'

$sbHdr     = @{ apikey = $SB_KEY; Authorization = "Bearer $SB_KEY"; 'Content-Type' = 'application/json' }
$insertHdr = $sbHdr.Clone(); $insertHdr['Prefer'] = 'resolution=ignore-duplicates,return=minimal'

Write-Host '=== Sync data.js -> Supabase (pure PowerShell) ==='

# -- 1. Load Supabase channels to get UUIDs --
Write-Host 'Loading Supabase channels...'
$sbChannels = @(Invoke-RestMethod -Uri ($SB_URL + '/channels?select=id,name&limit=1000') -Headers $sbHdr)
Write-Host ('  ' + $sbChannels.Count + ' channels found')

$chByName = @{}
foreach ($ch in $sbChannels) {
    $key = $ch.name.Trim().ToLower()
    if (-not $chByName.ContainsKey($key)) { $chByName[$key] = $ch.id }
}

# -- 2. Load existing Supabase video IDs (paginated) --
Write-Host 'Loading existing Supabase video IDs...'
$existingSbIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$offset = 0
do {
    $batch = @(Invoke-RestMethod -Uri ($SB_URL + '/videos?select=video_id&limit=1000&offset=' + $offset) -Headers $sbHdr)
    foreach ($v in $batch) { if ($v.video_id) { [void]$existingSbIds.Add($v.video_id) } }
    $offset += 1000
} while ($batch.Count -eq 1000)
Write-Host ('  ' + $existingSbIds.Count + ' already in Supabase')

# -- 3. Parse VIDEOS lines from data.js --
Write-Host 'Parsing data.js VIDEOS...'
$lines    = [System.IO.File]::ReadAllLines($DATA_JS, [System.Text.Encoding]::UTF8)
$rows     = [System.Collections.Generic.List[object]]::new()
$inVideos = $false
$noMatch  = [System.Collections.Generic.HashSet[string]]::new()

foreach ($line in $lines) {
    if ($line -match 'const VIDEOS = \[') { $inVideos = $true; continue }
    if (-not $inVideos)                   { continue }
    if ($line -match '^\];')              { break }

    # Must contain a Shorts URL
    if ($line -notmatch "url: 'https://www\.youtube\.com/shorts/([A-Za-z0-9_-]{11})'") { continue }
    $vidId = $Matches[1]
    if ($existingSbIds.Contains($vidId)) { continue }

    # Extract each field
    $title   = if ($line -match "title: '(.*?)', channelName:")        { $Matches[1] -replace "\\'", "'" } else { 'Untitled' }
    $chName  = if ($line -match "channelName: '(.*?)', channelUrl:")   { $Matches[1] -replace "\\'", "'" } else { '' }
    $views   = if ($line -match 'views: (\d+)')                        { [long]$Matches[1] }               else { 0 }
    $pubDate = if ($line -match "publishedDate: '(\d{4}-\d{2}-\d{2})'") { $Matches[1] }                   else { $null }
    $niche   = if ($line -match "niche: '([^']+)'")                    { $Matches[1] }                    else { $null }

    # Look up channel UUID by name
    $chKey   = $chName.Trim().ToLower()
    $chIdVal = $chByName[$chKey]
    if (-not $chIdVal) {
        foreach ($key in $chByName.Keys) {
            if ($chKey -like ('*' + $key + '*') -or $key -like ('*' + $chKey + '*')) {
                $chIdVal = $chByName[$key]
                break
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

Write-Host ('  ' + $rows.Count + ' new rows to insert')
if ($noMatch.Count -gt 0) {
    Write-Host ('  WARNING: ' + $noMatch.Count + ' channel name(s) not matched in Supabase (channel_id will be null):')
    $noMatch | Select-Object -First 10 | ForEach-Object { Write-Host ('    ' + $_) }
}

# -- 4. Insert in batches of 100 --
Write-Host 'Inserting into Supabase...'
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
        # Retry one-by-one on batch failure
        foreach ($row in $chunk) {
            $b = [System.Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject @($row) -Compress -Depth 5))
            try {
                Invoke-RestMethod -Uri ($SB_URL + '/videos') -Method Post -Headers $insertHdr -Body $b | Out-Null
                $ok++
            } catch { $fail++ }
        }
    }

    # Progress every 1000
    if ($ok -gt 0 -and ($ok % 1000 -lt 100)) {
        Write-Host ('  ' + $ok + ' / ' + $rowArr.Count + ' inserted...')
    }
    Start-Sleep -Milliseconds 80
}

Write-Host ''
Write-Host ('=== DONE: ' + $ok + ' inserted, ' + $fail + ' failed ===')

# Final count in Supabase
$hdrC = $sbHdr.Clone(); $hdrC['Prefer'] = 'count=exact'
try {
    $fc = Invoke-WebRequest -Uri ($SB_URL + '/videos?select=id&limit=1') -Headers $hdrC
    Write-Host ('Total videos now in Supabase: ' + $fc.Headers['Content-Range'])
} catch {}
