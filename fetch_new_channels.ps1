$YT_KEY  = 'AIzaSyBX47DSTcr3ZOPtbmYIoG0ECvHw1VHHHis'
$DATA_JS = 'C:\Users\RZeva\roblox-research\data.js'
$CUTOFF  = (Get-Date).AddDays(-90)

Write-Host '=== Fetching new channels - 90-day Shorts ==='
Write-Host ('Cutoff: ' + $CUTOFF.ToString('yyyy-MM-dd'))

$newHandles = @(
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

$newVideoLines   = [System.Collections.Generic.List[string]]::new()
$newChannelLines = [System.Collections.Generic.List[string]]::new()
$terminated      = [System.Collections.Generic.List[string]]::new()

foreach ($handle in $newHandles) {
    Write-Host ('[' + $handle + ']')

    # Resolve handle to channel info
    $chUri = 'https://www.googleapis.com/youtube/v3/channels?part=snippet,contentDetails,statistics&forHandle=' + $handle + '&key=' + $YT_KEY
    try {
        $chResp = Invoke-RestMethod -Uri $chUri -TimeoutSec 15
    } catch {
        Write-Host ('  API error: ' + $_.Exception.Message)
        $terminated.Add($handle)
        continue
    }

    if (-not $chResp.items -or @($chResp.items).Count -eq 0) {
        Write-Host '  Channel not found - skipping'
        $terminated.Add($handle)
        continue
    }

    $chItem    = @($chResp.items)[0]
    $ytChId    = $chItem.id
    $chName    = $chItem.snippet.title
    $uploadsId = $chItem.contentDetails.relatedPlaylists.uploads
    $subs      = if ($chItem.statistics.subscriberCount) { [long]$chItem.statistics.subscriberCount } else { 0 }
    $chUrl     = 'https://www.youtube.com/' + $handle

    Write-Host ('  ' + $chName + ' | subs=' + $subs)

    # Add CHANNELS entry
    $escapedName = Escape-JS $chName
    $newChannelLines.Add("  { name: '$escapedName', url: '$chUrl', niche: null, subscribers: $subs, dateStarted: null, totalVideos: null, uploadsPerWeek: null, avgViewsPerVideo: null, estMonthlyRevenue: null, outlierScore: null, legacyChannel: false },")

    # Paginate playlist for last 90 days
    $pageToken  = ''
    $pageNum    = 0
    $newForCh   = 0
    $stopPaging = $false

    do {
        $plUri = 'https://www.googleapis.com/youtube/v3/playlistItems?part=contentDetails&playlistId=' + $uploadsId + '&maxResults=50&key=' + $YT_KEY
        if ($pageToken) { $plUri = $plUri + '&pageToken=' + $pageToken }

        try {
            $plResp = Invoke-RestMethod -Uri $plUri -TimeoutSec 15
        } catch {
            Write-Host ('  Playlist error: ' + $_.Exception.Message)
            break
        }

        $recentIds  = @()
        $oldestDate = [datetime]::MaxValue

        foreach ($plItem in @($plResp.items)) {
            $pubAt = $plItem.contentDetails.videoPublishedAt
            if (-not $pubAt) { continue }
            $pubDt = [datetime]$pubAt
            if ($pubDt -lt $oldestDate) { $oldestDate = $pubDt }
            if ($pubDt -ge $CUTOFF)     { $recentIds += $plItem.contentDetails.videoId }
        }

        if ($oldestDate -lt $CUTOFF) { $stopPaging = $true }

        if ($recentIds.Count -gt 0) {
            $dUri = 'https://www.googleapis.com/youtube/v3/videos?part=snippet,statistics,contentDetails&id=' + ($recentIds -join ',') + '&key=' + $YT_KEY
            try {
                $dResp = Invoke-RestMethod -Uri $dUri -TimeoutSec 15
            } catch { break }

            foreach ($vItem in @($dResp.items)) {
                if ((Parse-ISODuration $vItem.contentDetails.duration) -gt 180) { continue }

                $vid      = $vItem.id
                $rawTitle = [regex]::Replace($vItem.snippet.title, '[^\x20-\x7E]', '').Trim()
                if (-not $rawTitle) { $rawTitle = 'Untitled' }
                $views    = if ($vItem.statistics.viewCount) { [long]$vItem.statistics.viewCount } else { 0 }
                $pubStr   = if ($vItem.snippet.publishedAt)  { $vItem.snippet.publishedAt.Substring(0,10) } else { '' }

                $t  = Escape-JS $rawTitle
                $cn = Escape-JS $chName

                $newVideoLines.Add("  { title: '$t', channelName: '$cn', channelUrl: '$chUrl', views: $views, publishedDate: '$pubStr', thumbnailUrl: 'https://i.ytimg.com/vi/$vid/maxresdefault.jpg', url: 'https://www.youtube.com/shorts/$vid', niche: null },")
                $newForCh++
            }
        }

        $pageToken = $plResp.nextPageToken
        $pageNum++
        Start-Sleep -Milliseconds 250
    } while ($pageToken -and (-not $stopPaging) -and ($pageNum -lt 12))

    Write-Host ('  -> ' + $newForCh + ' Shorts in last 90 days')
    Start-Sleep -Milliseconds 350
}

Write-Host ''
Write-Host '=== Summary ==='
Write-Host ('  New channel entries : ' + $newChannelLines.Count)
Write-Host ('  New video entries   : ' + $newVideoLines.Count)
Write-Host ('  Terminated/missing  : ' + $terminated.Count)

if ($terminated.Count -gt 0) {
    Write-Host '  Terminated channels:'
    foreach ($t in $terminated) { Write-Host ('    ' + $t) }
}

if ($newChannelLines.Count -eq 0 -and $newVideoLines.Count -eq 0) {
    Write-Host 'Nothing to write - exiting'
    exit 0
}

# Read data.js
$raw = [System.IO.File]::ReadAllText($DATA_JS, [System.Text.Encoding]::UTF8)

# 1. Insert new CHANNELS before the first ]; after "const CHANNELS = ["
if ($newChannelLines.Count -gt 0) {
    $chMarker = 'const CHANNELS = ['
    $chStart  = $raw.IndexOf($chMarker)
    $afterCh  = $raw.Substring($chStart + $chMarker.Length)
    $chClose  = $afterCh.IndexOf('];')
    $chBody   = $afterCh.Substring(0, $chClose).TrimEnd()
    $chRest   = $afterCh.Substring($chClose)

    $raw = $raw.Substring(0, $chStart) + $chMarker + "`n" + $chBody + "`n" + ($newChannelLines -join "`n") + "`n" + $chRest
    Write-Host ('  CHANNELS array updated (+' + $newChannelLines.Count + ')')
}

# 2. Append new VIDEOS before the final ]; of the VIDEOS array
if ($newVideoLines.Count -gt 0) {
    $closeSeq = "`n];"
    $lastIdx  = $raw.LastIndexOf($closeSeq)
    if ($lastIdx -ge 0) {
        $raw = $raw.Substring(0, $lastIdx) + "`n" + ($newVideoLines -join "`n") + $raw.Substring($lastIdx)
        Write-Host ('  VIDEOS array updated (+' + $newVideoLines.Count + ')')
    } else {
        Write-Host '  WARNING: could not locate VIDEOS closing ];'
    }
}

[System.IO.File]::WriteAllText($DATA_JS, $raw, [System.Text.Encoding]::UTF8)
Write-Host ''
Write-Host '=== data.js written successfully ==='
