param(
    [int]$StartIndex = 0,
    [int]$EndIndex   = 9999
)

$YT_KEY  = 'AIzaSyBX47DSTcr3ZOPtbmYIoG0ECvHw1VHHHis'
$DATA_JS = 'C:\Users\RZeva\roblox-research\data.js'
$CUTOFF  = (Get-Date).AddDays(-90)
$CUTOFF_STR = $CUTOFF.ToString('yyyy-MM-dd') + 'T00:00:00Z'

Write-Host '=== Fetch Shorts - last 90 days ==='
Write-Host ('Cutoff: ' + $CUTOFF.ToString('yyyy-MM-dd'))
Write-Host ('Channel range: ' + $StartIndex + ' to ' + $EndIndex)
Write-Host ''

# Parse channels from data.js
$raw = [System.IO.File]::ReadAllText($DATA_JS, [System.Text.Encoding]::UTF8)
$chStart = $raw.IndexOf('const CHANNELS = [')
$chEnd   = $raw.IndexOf('];', $chStart)
$chBlock = $raw.Substring($chStart, $chEnd - $chStart + 2)

$channels = [System.Collections.Generic.List[hashtable]]::new()
$chMatches = [regex]::Matches($chBlock, '{ name: "([^"]+)", url: "([^"]+)", niche: "([^"]+)"')
foreach ($m in $chMatches) {
    $channels.Add(@{
        name  = $m.Groups[1].Value
        url   = $m.Groups[2].Value
        niche = $m.Groups[3].Value
    })
}
Write-Host ('Parsed ' + $channels.Count + ' channels from data.js')

function Get-YtRef($url) {
    if ($url -match '/channel/(UC[^/?&#]+)') { return @{ type = 'id'; value = $Matches[1] } }
    if ($url -match '/@([^/?&#]+)')          { return @{ type = 'handle'; value = '@' + $Matches[1] } }
    return $null
}

function Parse-Duration($dur) {
    if ($dur -match 'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?') {
        return ([int]($Matches[1]) * 3600) + ([int]($Matches[2]) * 60) + [int]($Matches[3])
    }
    return 9999
}

function Escape-JS($s) {
    $s = $s -replace '\\', '\\\\'
    $s = $s -replace '"', '\"'
    $s = $s -replace "`r", ''
    $s = $s -replace "`n", ' '
    return $s
}

$allVideos    = [System.Collections.Generic.List[hashtable]]::new()
$downChannels = [System.Collections.Generic.List[string]]::new()
$seen         = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

$endIdx   = [Math]::Min($EndIndex, $channels.Count - 1)
$selected = @($channels[$StartIndex..$endIdx])
Write-Host ('Processing ' + $selected.Count + ' channels')
Write-Host ''

$idx = $StartIndex
foreach ($ch in $selected) {
    $idx++
    Write-Host ('  [' + $idx + '/' + $channels.Count + '] ' + $ch.name + ' ...')

    $ytRef = Get-YtRef $ch.url
    if (-not $ytRef) {
        Write-Host ('    SKIP: cannot parse URL ' + $ch.url)
        continue
    }

    $ytChannelId = $null
    if ($ytRef.type -eq 'id') {
        $ytChannelId = $ytRef.value
    } else {
        $resolveUri = 'https://www.googleapis.com/youtube/v3/channels?part=id&forHandle=' + $ytRef.value + '&key=' + $YT_KEY
        try {
            $r = Invoke-RestMethod -Uri $resolveUri -Method Get -TimeoutSec 20
            if (@($r.items).Count -gt 0) { $ytChannelId = @($r.items)[0].id }
        } catch {
            Write-Host ('    ERR resolving handle: ' + $_)
        }
        if (-not $ytChannelId) {
            Write-Host ('    DOWN: could not resolve handle ' + $ytRef.value)
            $downChannels.Add($ch.name)
            continue
        }
    }

    $pageToken = ''; $pageNum = 0; $newForCh = 0
    do {
        $sUri = 'https://www.googleapis.com/youtube/v3/search?part=id' +
                '&channelId=' + $ytChannelId +
                '&type=video&videoDuration=short' +
                '&maxResults=50&order=date' +
                '&publishedAfter=' + $CUTOFF_STR +
                '&key=' + $YT_KEY
        if ($pageToken) { $sUri = $sUri + '&pageToken=' + $pageToken }

        $sResp = $null
        try {
            $sResp = Invoke-RestMethod -Uri $sUri -Method Get -TimeoutSec 20
        } catch {
            $errStr = $_.ToString()
            if ($errStr -match '403|quota') {
                Write-Host '    QUOTA EXCEEDED - stopping'
                exit 1
            }
            Write-Host ('    Search error p' + $pageNum + ': ' + $errStr)
            break
        }

        $videoIds = @($sResp.items | ForEach-Object { $_.id.videoId } | Where-Object { $_ })
        if ($videoIds.Count -eq 0) { break }

        $dUri = 'https://www.googleapis.com/youtube/v3/videos?part=snippet,statistics,contentDetails' +
                '&id=' + ($videoIds -join ',') +
                '&key=' + $YT_KEY
        $dResp = $null
        try {
            $dResp = Invoke-RestMethod -Uri $dUri -Method Get -TimeoutSec 20
        } catch {
            Write-Host ('    Detail error: ' + $_)
            break
        }

        foreach ($item in @($dResp.items)) {
            $vid = $item.id
            if ($seen.Contains($vid)) { continue }

            $durSec = Parse-Duration $item.contentDetails.duration
            if ($durSec -gt 180) { continue }

            $pubAt   = $item.snippet.publishedAt
            $pubDate = if ($pubAt) { $pubAt.Substring(0, 10) } else { $null }

            $views = 0L
            if ($item.statistics.viewCount) { $views = [long]$item.statistics.viewCount }

            $rawTitle = $item.snippet.title
            $title    = [regex]::Replace($rawTitle, '[^\x20-\x7E]', '').Trim()
            if (-not $title) { $title = 'Untitled' }

            $thumb = 'https://i.ytimg.com/vi/' + $vid + '/maxres2.jpg'

            [void]$seen.Add($vid)
            $allVideos.Add(@{
                title         = $title
                channelName   = $ch.name
                channelUrl    = $ch.url
                views         = $views
                publishedDate = $pubDate
                thumbnailUrl  = $thumb
                url           = 'https://www.youtube.com/shorts/' + $vid
                niche         = $null
            })
            $newForCh++
        }

        $pageToken = $sResp.nextPageToken
        $pageNum++
        Start-Sleep -Milliseconds 150
    } while ($pageToken -and $pageNum -lt 10)

    Write-Host ('    ' + $newForCh + ' shorts found')
    Start-Sleep -Milliseconds 200
}

Write-Host ''
Write-Host '=== COLLECTION DONE ==='
Write-Host ('Total videos: ' + $allVideos.Count)
Write-Host ('Down channels: ' + $downChannels.Count)
Write-Host ''

# Build JS lines
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('')
$lines.Add('  // ============================================================')
$lines.Add('  // SYNCED: ' + (Get-Date -Format 'yyyy-MM-dd') + ' via YouTube Data API v3')
$lines.Add('  // Cutoff: last 90 days (since ' + $CUTOFF.ToString('yyyy-MM-dd') + ')')
$lines.Add('  // niche = null (unassigned)')
$lines.Add('  // ============================================================')
$lines.Add('')

# Sort by channelName then publishedDate descending
$sorted = @($allVideos | Sort-Object @{e={$_.channelName}}, @{e={$_.publishedDate}; d=$true})

$currentChannel = ''
foreach ($v in $sorted) {
    if ($v.channelName -ne $currentChannel) {
        $currentChannel = $v.channelName
        $lines.Add('  // -- ' + $currentChannel + ' --')
    }
    $safeTitle = Escape-JS $v.title
    $safeThumb = Escape-JS $v.thumbnailUrl
    $line = '  { title: "' + $safeTitle + '", channelName: "' + $v.channelName + '", channelUrl: "' + $v.channelUrl + '", views: ' + $v.views + ', publishedDate: "' + $v.publishedDate + '", thumbnailUrl: "' + $safeThumb + '", url: "' + $v.url + '", niche: null },'
    $lines.Add($line)
}

if ($downChannels.Count -gt 0) {
    $lines.Add('')
    $lines.Add('  // == DOWN CHANNELS (API error / not found) ==')
    foreach ($d in $downChannels) { $lines.Add('  // DOWN: ' + $d) }
}
$lines.Add('')

# Patch data.js - use index-based replacement to avoid regex backreference issues
$content  = [System.IO.File]::ReadAllText($DATA_JS, [System.Text.Encoding]::UTF8)
$newBlock = $lines -join "`n"

$vidStart = $content.IndexOf('const VIDEOS = [')
if ($vidStart -lt 0) {
    Write-Host 'ERROR: could not find "const VIDEOS = [" in data.js'
    exit 1
}
$openBracket = $vidStart + 'const VIDEOS = ['.Length
# Find the matching closing ]; after the VIDEOS opening
$vidEnd = $content.IndexOf('];', $openBracket)
if ($vidEnd -lt 0) {
    Write-Host 'ERROR: could not find closing ]; for VIDEOS array'
    exit 1
}

$updated = $content.Substring(0, $openBracket) + "`n" + $newBlock + $content.Substring($vidEnd)

# Update header comments using simple string replacement (no regex on user content)
$updated = [regex]::Replace($updated, '// Last updated: \d{4}-\d{2}-\d{2}', '// Last updated: ' + (Get-Date -Format 'yyyy-MM-dd'))
$updated = [regex]::Replace($updated, '// Videos last synced:[^\n]*', '// Videos last synced: ' + (Get-Date -Format 'yyyy-MM-dd') + ' via YouTube Data API v3 (last 90 days)')
# Remove SYNC_STATUS block
$updated = [regex]::Replace($updated, '// SYNC_STATUS:[^\n]*(\n//[^\n]*)*\n', '')

[System.IO.File]::WriteAllText($DATA_JS, $updated, [System.Text.Encoding]::UTF8)

Write-Host 'data.js updated successfully.'
Write-Host ''
if ($downChannels.Count -gt 0) {
    Write-Host '=== DOWN / NOT FOUND ==='
    foreach ($d in $downChannels) { Write-Host ('  - ' + $d) }
}
Write-Host '=== DONE ==='
