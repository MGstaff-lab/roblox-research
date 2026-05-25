$SB_URL  = 'https://ahpzdwemvunyaumrnxal.supabase.co/rest/v1/videos'
$SB_KEY  = 'sb_publishable_NPPdURwPz_DEt6JG--haaw_CThnEoQF'
$YT_KEY  = 'AIzaSyBX47DSTcr3ZOPtbmYIoG0ECvHw1VHHHis'

$sbHdr = @{
    'apikey'        = $SB_KEY
    'Authorization' = "Bearer $SB_KEY"
    'Content-Type'  = 'application/json'
}

# ── 1. Fetch all video records (paginated) ──────────────────────────────────
$all = [System.Collections.Generic.List[object]]::new()
$limit  = 1000
$offset = 0

do {
    $uri   = $SB_URL + '?select=id,video_id&limit=' + $limit + '&offset=' + $offset
    $batch = Invoke-RestMethod -Uri $uri -Headers $sbHdr -Method Get
    if ($null -eq $batch -or $batch.Count -eq 0) { break }
    foreach ($r in @($batch)) { $all.Add($r) }
    Write-Host "Fetched offset $offset → total $($all.Count)"
    $offset += $limit
} while ($batch.Count -eq $limit)

Write-Host "Total video records fetched: $($all.Count)"

# Filter to records that have a video_id but no published_date yet
$toUpdate = @($all | Where-Object { $_.video_id -and $_.video_id.Trim() -ne '' })
Write-Host "Records with video_id: $($toUpdate.Count)"

# ── 2. Batch to YouTube Data API (50 at a time) ─────────────────────────────
$dateMap  = @{}
$ytBase   = 'https://www.googleapis.com/youtube/v3/videos'
$batchSz  = 50

for ($i = 0; $i -lt $toUpdate.Count; $i += $batchSz) {
    $chunk   = @($toUpdate[$i..([Math]::Min($i + $batchSz - 1, $toUpdate.Count - 1))])
    $ids     = ($chunk | ForEach-Object { $_.video_id }) -join ','
    $ytUri   = $ytBase + '?part=snippet&maxResults=50&key=' + $YT_KEY + '&id=' + $ids

    try {
        $ytResp = Invoke-RestMethod -Uri $ytUri -Method Get
        if ($ytResp.items) {
            foreach ($item in @($ytResp.items)) {
                $published = $item.snippet.publishedAt
                if ($published) {
                    $dateMap[$item.id] = $published.Substring(0, 10)
                }
            }
        }
    } catch {
        Write-Host "YT API error at batch $i : $_"
    }

    if ($i % 500 -eq 0) {
        Write-Host "YT progress: $i / $($toUpdate.Count)  dates so far: $($dateMap.Count)"
    }
    Start-Sleep -Milliseconds 100
}

Write-Host "Dates fetched from YouTube: $($dateMap.Count)"

# ── 3. PATCH Supabase records ────────────────────────────────────────────────
$patched = 0
$skipped = 0

foreach ($rec in $toUpdate) {
    $date = $dateMap[$rec.video_id]
    if (-not $date) { $skipped++; continue }

    $patchUri = $SB_URL + '?id=eq.' + $rec.id
    $body     = '{"published_date":"' + $date + '"}'
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)

    try {
        Invoke-RestMethod -Uri $patchUri -Method Patch -Headers $sbHdr -Body $bodyBytes | Out-Null
        $patched++
    } catch {
        Write-Host "PATCH error for $($rec.id): $_"
    }

    if ($patched % 100 -eq 0 -and $patched -gt 0) {
        Write-Host "Patched $patched so far…"
    }
}

Write-Host ""
Write-Host "Done. Patched: $patched  |  Skipped (no YT date): $skipped"
