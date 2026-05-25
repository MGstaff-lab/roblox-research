$YT_KEY  = 'AIzaSyBX47DSTcr3ZOPtbmYIoG0ECvHw1VHHHis'
$DATA_JS = 'C:\Users\RZeva\roblox-research\data.js'

Write-Host '=== Full history fetch for 42 new channels ==='

$handles = @(
    '@CharaBlox', '@corlblox', '@rorants', '@pizaoff', '@pimix17',
    '@sleepypandablox', '@gattu', '@GaboEZ', '@Cheetify', '@CHOAAM',
    '@kdazo6969', '@jimrants', '@galrots', '@cosmo-o2e', '@Miss_DramaQueen',
    '@steamgirl01', '@BettiGuest', '@eazyethan', '@mr.watermelon111',
    '@junelldominic', '@noobeeblox', '@cheesymembey', '@MichaelRobloxRP',
    '@CarlaBloxy', '@imDinoBro', '@MikuwuYT', '@Deyaaaan', '@NitroBoosty',
    '@Ricarro', '@mr-gamie', '@apollorblx', '@NguyenPhiLong06', '@Mashles27',
    '@laylaroblox', '@jelly-fishtastic', '@BloopoRoblox', '@Aqua_Mia',
    '@huydutblox', '@toslowblox', '@roloop', '@tanroxrb', '@scrim-m2b'
)

function Escape-JS([string]$s) {
    $s = $s -replace '\\', '\\'
    $s = $s -replace "'",  "\'"
    $s = $s -replace "`n", ' '
    $s = $s -replace "`r", ''
    return $s
}

function Parse-ISODuration($dur) {
    if ($dur -match 'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?') {
        return ([int]($Matches[1]) * 3600) + ([int]($Matches[2]) * 60) + [int]($Matches[3])
    }
    return 9999
}

# -- Load all existing video IDs from data.js --
Write-Host 'Loading existing video IDs from data.js...'
$raw = [System.IO.File]::ReadAllText($DATA_JS, [System.Text.Encoding]::UTF8)
$existingIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$idMatches = [regex]::Matches($raw, '/shorts/([A-Za-z0-9_-]{11})')
foreach ($m in $idMatches) { [void]$existingIds.Add($m.Groups[1].Value) }
Write-Host ('  Found ' + $existingIds.Count + ' existing video IDs')

$allNewLines = [System.Collections.Generic.List[string]]::new()
$totalSkipped = 0

foreach ($handle in $handles) {
    Write-Host ('[' + $handle + ']')

    # Resolve handle
    $chUri = 'https://www.googleapis.com/youtube/v3/channels?part=snippet,contentDetails&forHandle=' + $handle + '&key=' + $YT_KEY
    try {
        $chResp = Invoke-RestMethod -Uri $chUri -TimeoutSec 15
    } catch {
        Write-Host ('  Error resolving: ' + $_.Exception.Message)
        continue
    }

    if (-not $chResp.items -or @($chResp.items).Count -eq 0) {
        Write-Host '  Not found - skipping'
        continue
    }

    $chItem    = @($chResp.items)[0]
    $chName    = $chItem.snippet.title
    $uploadsId = $chItem.contentDetails.relatedPlaylists.uploads
    $chUrl     = 'https://www.youtube.com/' + $handle

    Write-Host ('  ' + $chName)

    # Paginate ALL uploads (no date cutoff)
    $pageToken = ''
    $pageNum   = 0
    $newForCh  = 0
    $skipForCh = 0

    do {
        $plUri = 'https://www.googleapis.com/youtube/v3/playlistItems?part=contentDetails&playlistId=' + $uploadsId + '&maxResults=50&key=' + $YT_KEY
        if ($pageToken) { $plUri = $plUri + '&pageToken=' + $pageToken }

        try {
            $plResp = Invoke-RestMethod -Uri $plUri -TimeoutSec 15
        } catch {
            Write-Host ('  Playlist error p' + $pageNum + ': ' + $_.Exception.Message)
            break
        }

        $idsOnPage = @()
        foreach ($plItem in @($plResp.items)) {
            $vid = $plItem.contentDetails.videoId
            if (-not $vid) { continue }
            if ($existingIds.Contains($vid)) { $skipForCh++; continue }
            $idsOnPage += $vid
        }

        if ($idsOnPage.Count -gt 0) {
            $dUri = 'https://www.googleapis.com/youtube/v3/videos?part=snippet,statistics,contentDetails&id=' + ($idsOnPage -join ',') + '&key=' + $YT_KEY
            try {
                $dResp = Invoke-RestMethod -Uri $dUri -TimeoutSec 15
            } catch { break }

            foreach ($vItem in @($dResp.items)) {
                if ((Parse-ISODuration $vItem.contentDetails.duration) -gt 180) { continue }

                $vid      = $vItem.id
                $rawTitle = [regex]::Replace($vItem.snippet.title, '[^\x20-\x7E]', '').Trim()
                if (-not $rawTitle) { $rawTitle = 'Untitled' }
                $views    = if ($vItem.statistics.viewCount) { [long]$vItem.statistics.viewCount } else { 0 }
                $pubStr   = if ($vItem.snippet.publishedAt) { $vItem.snippet.publishedAt.Substring(0,10) } else { '' }

                $t  = Escape-JS $rawTitle
                $cn = Escape-JS $chName

                $allNewLines.Add("  { title: '$t', channelName: '$cn', channelUrl: '$chUrl', views: $views, publishedDate: '$pubStr', thumbnailUrl: 'https://i.ytimg.com/vi/$vid/maxresdefault.jpg', url: 'https://www.youtube.com/shorts/$vid', niche: null },")
                [void]$existingIds.Add($vid)
                $newForCh++
            }
        }

        $pageToken = $plResp.nextPageToken
        $pageNum++
        Start-Sleep -Milliseconds 200

        # Flush every 300 new lines to avoid huge in-memory buffer
        if ($allNewLines.Count -ge 300) {
            Write-Host ('  [flush ' + $allNewLines.Count + ' lines to disk]')
            $rawNow = [System.IO.File]::ReadAllText($DATA_JS, [System.Text.Encoding]::UTF8)
            $closeSeq = "`n];"
            $lastIdx  = $rawNow.LastIndexOf($closeSeq)
            $rawNow   = $rawNow.Substring(0, $lastIdx) + "`n" + ($allNewLines -join "`n") + $rawNow.Substring($lastIdx)
            [System.IO.File]::WriteAllText($DATA_JS, $rawNow, [System.Text.Encoding]::UTF8)
            $allNewLines.Clear()
        }

    } while ($pageToken -and $pageNum -lt 60)

    $totalSkipped += $skipForCh
    Write-Host ('  -> ' + $newForCh + ' new | ' + $skipForCh + ' already had | pages=' + $pageNum)
    Start-Sleep -Milliseconds 400
}

Write-Host ''
Write-Host ('Total skipped (already in DB): ' + $totalSkipped)
Write-Host ('Remaining to flush:            ' + $allNewLines.Count)

# Final flush
if ($allNewLines.Count -gt 0) {
    $rawFinal = [System.IO.File]::ReadAllText($DATA_JS, [System.Text.Encoding]::UTF8)
    $closeSeq = "`n];"
    $lastIdx  = $rawFinal.LastIndexOf($closeSeq)
    $rawFinal = $rawFinal.Substring(0, $lastIdx) + "`n" + ($allNewLines -join "`n") + $rawFinal.Substring($lastIdx)
    [System.IO.File]::WriteAllText($DATA_JS, $rawFinal, [System.Text.Encoding]::UTF8)
    Write-Host 'Final flush written.'
}

# Quick count
$rawCheck = [System.IO.File]::ReadAllText($DATA_JS, [System.Text.Encoding]::UTF8)
$vCount   = ([regex]::Matches($rawCheck, "^\s+\{ title:", [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count
Write-Host ''
Write-Host ('=== DONE. Total VIDEOS in data.js: ' + $vCount + ' ===')
