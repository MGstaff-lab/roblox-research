# sync_videos_yt.ps1
# Fetches new videos for all channels in data.js using the YouTube Data API v3.
# No Supabase required — reads channels from data.js, writes VIDEOS back to data.js.
#
# Cutoff: 2026-05-11 (last sync was May 10)
# Niche: null / unassigned on all new videos
#
# Usage: .\sync_videos_yt.ps1
#        .\sync_videos_yt.ps1 -NewChannelCutoffDays 90   (override new-channel window)

param(
    [int]$NewChannelCutoffDays = 90
)

$YT_KEY          = 'AIzaSyBX47DSTcr3ZOPtbmYIoG0ECvHw1VHHHis'
$EXISTING_CUTOFF = [datetime]'2026-05-11T00:00:00Z'
$NEW_CUTOFF      = (Get-Date).AddDays(-$NewChannelCutoffDays)
$DATA_JS         = Join-Path $PSScriptRoot 'data.js'

# ── Channel list (from data.js CHANNELS array) ────────────────────────────────
$CHANNELS = @(
  @{ name="Adrsh Roblox";          url="https://youtube.com/channel/UCfliXgJLUrtQRdTqqoRmmgQ" },
  @{ name="Haro";                   url="https://youtube.com/channel/UC7rrJcEjb7P7IvGbtabyJ0A" },
  @{ name="BradeyRoblox";           url="https://youtube.com/channel/UCDZ3EbVK-rpBklxiW3hLufg" },
  @{ name="Puddles";                url="https://youtube.com/channel/UCn1IjWgX8zOQ1zWV0siq9bA" },
  @{ name="BlueRblx";               url="https://youtube.com/channel/UCiW6YNZzVZ_tEn26PILRhRw" },
  @{ name="RobloxNoobReal";         url="https://youtube.com/channel/UCrlDqwJiTTLRgcypZaIG_EA" },
  @{ name="Gohanrobloxeditz";       url="https://youtube.com/channel/UC-YhR2B9aQT5tmOGy8nevdA" },
  @{ name="AvocadoBoyRoblox";       url="https://youtube.com/channel/UCgsX_jXxofIMRG9v9F7Y59g" },
  @{ name="Sleepy Kitty ROBLOX";    url="https://youtube.com/channel/UC80diLNH00jmwGr04y4nAHg" },
  @{ name="RobloxStudio By Lea";    url="https://youtube.com/channel/UCsn3ZAnlMlbQmObHRPBbxeg" },
  @{ name="DaRobloxGuy";            url="https://youtube.com/channel/UC_AlsFoZ4TKmhl-FfLRO3yg" },
  @{ name="PinkRants";              url="https://youtube.com/channel/UCuCivOoCN2Pxh4PvcVeylbw" },
  @{ name="MiaRoblox";              url="https://youtube.com/channel/UC6ncerOzpCSXx0k0eo135Xg" },
  @{ name="Roblox Empire";          url="https://youtube.com/channel/UC1BKjyhtivUX0NnK9zu3EEg" },
  @{ name="MiloRants";              url="https://youtube.com/channel/UCyKZQDVSBh84FmhGvET64oQ" },
  @{ name="Prolls";                 url="https://youtube.com/channel/UCAHZUcHC7z2EgwwLncIoGAg" },
  @{ name="Bloxx";                  url="https://youtube.com/channel/UCBHR_IKKEGbjaoSTv-gYAIQ" },
  @{ name="RobloxiniRants";         url="https://youtube.com/channel/UCbdiWfYVFpLVcmsN8IdzxvA" },
  @{ name="RankingRobloxclipz";     url="https://youtube.com/channel/UC0FMS-NvJS0wWaI5rlS2njA" },
  @{ name="MikeRoblox";             url="https://youtube.com/channel/UCxHxDmzFSOuYmRwMHec8g7g" },
  @{ name="Dasheeeer";              url="https://youtube.com/channel/UCfbUZsAY5HEgHl36c44gyfQ" },
  @{ name="Roozoo Roblox";          url="https://youtube.com/channel/UCRIkgHU8G_LAGvI-bwNrO8g" },
  @{ name="FhyonRoblox";            url="https://youtube.com/channel/UCxtFY31vVXX6_zO3j3qDXBQ" },
  @{ name="Jack Rants";             url="https://youtube.com/channel/UCkJLzlgCp7yGU0XbztBOAMA" },
  @{ name="JonyRoblox";             url="https://youtube.com/channel/UCnOsymos737S20p22hRKscA" },
  @{ name="Major Meowzer - Roblox"; url="https://youtube.com/channel/UCGK_6O8NFL44wN2IVcG6OHg" },
  @{ name="Roblox Crash Cam";       url="https://youtube.com/channel/UCeFyhECmAeKzl2mnD9uwGzQ" },
  @{ name="AndyRants";              url="https://youtube.com/channel/UCj_-MuLnLxMTQZslsirwxJw" },
  @{ name="EdiPlaysRoblox";         url="https://youtube.com/channel/UC4YTjs-Jn6pr2QZyGVmdilw" },
  @{ name="ZyroBlox";               url="https://youtube.com/channel/UCC4rxjdKrS_VmyUZ0kk214w" },
  @{ name="ELGATO GAMING";          url="https://youtube.com/channel/UC3Ly59N-1VdKSBINCfBnb2g" },
  @{ name="PandaRants";             url="https://youtube.com/channel/UC1fK6HxzI8sX6ehfs8i7nGg" },
  @{ name="Cyber Roblox";           url="https://youtube.com/channel/UCTfQkWaOHV5eiHplxXKa3VA" },
  @{ name="Danny Roblox";           url="https://youtube.com/channel/UCdgerHgRm1Mm9Kb5FMFlEtg" },
  @{ name="Dominik Roblox";         url="https://youtube.com/channel/UCN9sim-dfACVzhqTBw6xUkg" },
  @{ name="Carlos";                 url="https://youtube.com/channel/UCqEAJoxEpxB0vAIuIJODGvQ" },
  @{ name="KicksRobloxian";         url="https://youtube.com/channel/UCPh45wm-vHCWoLdAQ7xEXdA" },
  @{ name="TinyBlox";               url="https://youtube.com/channel/UCDH5JgbQwTrzcxOeixdHkEQ" },
  @{ name="mjbroblox";              url="https://youtube.com/channel/UCMAOxswwF9cErZLcl62U7nw" },
  @{ name="KittyRants";             url="https://youtube.com/channel/UC3jI96VvTGqzJW6b7IE7pPw" },
  @{ name="Backward Roblox";        url="https://youtube.com/channel/UCtRVyT3DpSE2yo3bPvhzpzw" },
  @{ name="SushiBoyRoblox";         url="https://youtube.com/channel/UCVi8VPPNSMIjxJUTQxb1d7Q" },
  @{ name="Boop Roblox";            url="https://youtube.com/channel/UCSyC7tTxT4aYtlska2EBUew" },
  @{ name="Phuong TV";              url="https://youtube.com/channel/UCLKzbiGdBxLGfJGi9pIRmnw" },
  @{ name="AmyyRoblox";             url="https://youtube.com/channel/UCi6rh0ehJ1M7-SaGO-Y3stw" },
  @{ name="FroyoRoblox";            url="https://youtube.com/channel/UC_9sNgDJdVSEEMnzM6j1jyQ" },
  @{ name="Turbo";                  url="https://youtube.com/channel/UCJLCT8h5Hvwjz0bL4RtMU7A" },
  @{ name="LorenzoRoblox";          url="https://youtube.com/channel/UClqejOkUnIQQmoFxWrK3jgw" },
  @{ name="Roblox Noob";            url="https://youtube.com/channel/UCBuNmnxOzVL_dy7HmO0Mz8Q" },
  @{ name="TanRox Roblox";          url="https://youtube.com/channel/UC4XY9C-ZViMEIXT4mDk_h_w" },
  @{ name="EliteScopez";            url="https://youtube.com/channel/UCBcitNEBpiG4Npj1kDtGAlQ" },
  @{ name="Unclaim";                url="https://youtube.com/channel/UCYHEM_U6A1QqOrveCX5wY0Q" },
  @{ name="Ninja Roblox";           url="https://youtube.com/channel/UC5_QJxDeFiHo5u9PXERSI_Q" },
  @{ name="RobloxOfficial";         url="https://youtube.com/channel/UC-Q8I-FFpp1aQKUb-GsJ4hg" },
  @{ name="AdooRoblox";             url="https://youtube.com/channel/UC6i-XQa2MHf64gdITrArdCw" },
  @{ name="MIXU";                   url="https://youtube.com/channel/UChiwFLpJaQRNv0qD_mKD99Q" },
  @{ name="SpideyRants";            url="https://youtube.com/channel/UCW7EMu1a0LORiELLqL9eRrQ" },
  @{ name="OvidiuROBLOX";           url="https://youtube.com/channel/UCv1ju0EgUqc9IUKMT79GM-Q" },
  @{ name="Mr. Carecaroblox";       url="https://youtube.com/channel/UCo8HwSigAfhn5s_DVfvvoSQ" },
  @{ name="HuhCat Gaming";          url="https://youtube.com/channel/UCKyo6fA_V0cEuD8rdp4vutA" },
  @{ name="Lucia Roblox";           url="https://youtube.com/channel/UCs4dUH_SFFBEU-9t7hyeHpA" },
  @{ name="Noxy Roblox";            url="https://youtube.com/channel/UCJEUFDoX4M3p_GFByTxi25g" },
  @{ name="Battle Bacon";           url="https://youtube.com/channel/UC9-KArir6d7i7Yxj6UPoPUw" },
  @{ name="Luna Heart";             url="https://youtube.com/channel/UCeV_RF141I4JkWV3sBQE5SQ" },
  @{ name="Pippin Roblox";          url="https://youtube.com/channel/UCm67FGT3eIrYPKt1oQ1P7aw" },
  @{ name="Lana's Life";            url="https://youtube.com/@Lanaslifeee" },
  @{ name="RealRosa";               url="https://youtube.com/@RealRosa" },
  @{ name="Ray";                    url="https://youtube.com/@Ray-y6s4t" },
  @{ name="AmyyRoblox (TT)";        url="https://youtube.com/@AmyyRoblox1" },
  @{ name="nobrainjames";           url="https://youtube.com/@nobrainjames" },
  @{ name="Banksy";                 url="https://youtube.com/@BanksyRoblox" },
  @{ name="Nizarisaqt";             url="https://youtube.com/@Nizarisacutie" },
  @{ name="Rihana";                 url="https://youtube.com/@Rihana-k2i" },
  @{ name="NitroNuke";              url="https://youtube.com/@TheNitroNuke" },
  @{ name="SteamGirl";              url="https://youtube.com/@SteamGirl01" },
  @{ name="Spizee";                 url="https://youtube.com/@spizee" },
  @{ name="toonz CRAFT";            url="https://youtube.com/@toonzcraft" },
  @{ name="chikinbanana";           url="https://youtube.com/@chikinbanana" },
  @{ name="TOOMANS";                url="https://youtube.com/@TOOMANS" },
  @{ name="Janruary";               url="https://youtube.com/@Janruary" },
  @{ name="GameAnimania";           url="https://youtube.com/@GameAnimania" },
  @{ name="BlazeBlox Shorts";       url="https://youtube.com/@BlazeBloxShorts" },
  @{ name="Soonrok";                url="https://youtube.com/@Soonrok_95" },
  @{ name="Li Li";                  url="https://youtube.com/@SnapSnipsOfficial" }
)

# ── Helpers ───────────────────────────────────────────────────────────────────
function Get-YtRef($url) {
    if ($url -match '/channel/(UC[^/?&#]+)') { return @{ type='id';     value=$Matches[1] } }
    if ($url -match '/@([^/?&#]+)')          { return @{ type='handle'; value='@'+$Matches[1] } }
    return $null
}

function Escape-JS([string]$s) {
    $s = $s -replace '\\', '\\'   # \ → \\ (one literal backslash → two, for JS)
    $s = $s -replace "'",  "\'"   # ' → \' (apostrophe → escaped, for JS single-quoted strings)
    $s = $s -replace "`n", ' '
    $s = $s -replace "`r", ''
    return $s
}

function Parse-ISODuration([string]$dur) {
    if ($dur -match 'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?') {
        return ([int]($Matches[1]) * 3600) + ([int]($Matches[2]) * 60) + [int]($Matches[3])
    }
    return 9999
}

function Get-BestThumb($item) {
    $t = $item.snippet.thumbnails
    foreach ($k in @('maxres','standard','high','medium','default')) {
        if ($t.$k) { return $t.$k.url }
    }
    return ''
}

function Invoke-YT([string]$uri) {
    try {
        return Invoke-RestMethod -Uri $uri -ErrorAction Stop
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
        Write-Host ("      YT API error ($code): " + $_.Exception.Message) -ForegroundColor Yellow
        return $null
    }
}

# ── Main ──────────────────────────────────────────────────────────────────────
$allVideos    = [System.Collections.Generic.List[object]]::new()
$downChannels = [System.Collections.Generic.List[string]]::new()
$seenVidIds   = [System.Collections.Generic.HashSet[string]]::new()

$total = $CHANNELS.Count
$i = 0

foreach ($ch in $CHANNELS) {
    $i++
    $ytRef = Get-YtRef $ch.url
    if (-not $ytRef) {
        Write-Host ("[$i/$total] SKIP bad URL: " + $ch.name) -ForegroundColor Gray
        continue
    }

    # Decide cutoff — all channels here are "existing" (were in data.js before May 11)
    $cutoff = $EXISTING_CUTOFF

    # Resolve channel ID
    $channelId = $null
    $uploadsId = $null

    if ($ytRef.type -eq 'id') {
        $channelId = $ytRef.value
        $uploadsId = 'UU' + $channelId.Substring(2)
    } else {
        $r = Invoke-YT ("https://www.googleapis.com/youtube/v3/channels?part=contentDetails&forHandle=" + $ytRef.value + "&key=$YT_KEY")
        if (-not $r -or @($r.items).Count -eq 0) {
            Write-Host ("[$i/$total] NOT FOUND: " + $ch.name) -ForegroundColor Red
            $downChannels.Add($ch.name)
            continue
        }
        $channelId = @($r.items)[0].id
        $uploadsId = @($r.items)[0].contentDetails.relatedPlaylists.uploads
    }

    Write-Host ("[$i/$total] $($ch.name)") -NoNewline

    # Walk uploads playlist, newest first, until we hit the cutoff
    $pageToken     = $null
    $pageNum       = 0
    $newCount      = 0
    $reachedCutoff = $false
    $isDown        = $false

    do {
        $plUri = "https://www.googleapis.com/youtube/v3/playlistItems?part=contentDetails&playlistId=$uploadsId&maxResults=50&key=$YT_KEY"
        if ($pageToken) { $plUri += "&pageToken=$pageToken" }

        $plResp = Invoke-YT $plUri
        if (-not $plResp) {
            # Check if 404 (channel gone) vs other error
            $isDown = $true
            $downChannels.Add($ch.name)
            break
        }

        $items = @($plResp.items)
        if ($items.Count -eq 0) { break }

        # Collect IDs published on/after cutoff
        $batchIds = @()
        foreach ($item in $items) {
            $pubAt = $item.contentDetails.videoPublishedAt
            if (-not $pubAt) { continue }
            $pubDt = [datetime]::Parse($pubAt, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AssumeUniversal).ToUniversalTime()
            if ($pubDt -lt $cutoff) { $reachedCutoff = $true; break }
            $vid = $item.contentDetails.videoId
            if ($vid -and -not $seenVidIds.Contains($vid)) { $batchIds += $vid }
        }

        # Fetch details for this batch
        if ($batchIds.Count -gt 0) {
            $dUri  = "https://www.googleapis.com/youtube/v3/videos?part=snippet,statistics,contentDetails&id=" + ($batchIds -join ',') + "&key=$YT_KEY"
            $dResp = Invoke-YT $dUri
            if ($dResp) {
                foreach ($item in @($dResp.items)) {
                    $vid  = $item.id
                    [void]$seenVidIds.Add($vid)
                    $dur  = Parse-ISODuration $item.contentDetails.duration
                    $vidUrl = if ($dur -le 180) { "https://www.youtube.com/shorts/$vid" } else { "https://www.youtube.com/watch?v=$vid" }
                    $allVideos.Add([ordered]@{
                        title         = $item.snippet.title
                        channelName   = $ch.name
                        channelUrl    = $ch.url
                        views         = if ($item.statistics.viewCount) { [long]$item.statistics.viewCount } else { 0 }
                        publishedDate = $item.snippet.publishedAt.Substring(0,10)
                        thumbnailUrl  = Get-BestThumb $item
                        url           = $vidUrl
                        niche         = $null
                    })
                    $newCount++
                }
            }
        }

        $pageToken = $plResp.nextPageToken
        $pageNum++
        Start-Sleep -Milliseconds 80

    } while ($pageToken -and -not $reachedCutoff -and $pageNum -lt 10)

    if (-not $isDown) {
        Write-Host (" → $newCount video(s)") -ForegroundColor $(if ($newCount -gt 0) { 'Green' } else { 'Gray' })
    }
    Start-Sleep -Milliseconds 50
}

# ── Build updated VIDEOS block ────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Writing $($allVideos.Count) videos to data.js ===" -ForegroundColor Cyan

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('')
$lines.Add('  // ============================================================')
$lines.Add('  // SYNCED: ' + (Get-Date -Format 'yyyy-MM-dd') + ' via YouTube Data API v3')
$lines.Add('  // Cutoff: ' + $EXISTING_CUTOFF.ToString('yyyy-MM-dd') + ' | niche = null (unassigned)')
$lines.Add('  // ============================================================')
$lines.Add('')

$sorted = $allVideos | Sort-Object channelName, { [datetime]$_.publishedDate } -Descending
$curCh = ''
foreach ($v in $sorted) {
    if ($v.channelName -ne $curCh) {
        if ($curCh -ne '') { $lines.Add('') }
        $curCh = $v.channelName
        $lines.Add("  // -- $curCh --")
    }
    $t   = Escape-JS $v.title
    $th  = Escape-JS $v.thumbnailUrl
    $cn  = Escape-JS $v.channelName
    $lines.Add("  { title: '$t', channelName: '$cn', channelUrl: '$($v.channelUrl)', views: $($v.views), publishedDate: '$($v.publishedDate)', thumbnailUrl: '$th', url: '$($v.url)', niche: null },")
}
$lines.Add('')

$raw     = Get-Content $DATA_JS -Raw -Encoding UTF8
# Update date header via regex (safe — date format is unique)
$raw     = [regex]::Replace($raw, '// Last updated: \d{4}-\d{2}-\d{2}', ('// Last updated: ' + (Get-Date -Format 'yyyy-MM-dd')))

# Replace VIDEOS block using string index split — avoids regex matching titles
$marker  = 'const VIDEOS = ['
$idx     = $raw.IndexOf($marker)
if ($idx -lt 0) { Write-Host 'ERROR: VIDEOS marker not found in data.js'; exit 1 }
$prefix  = $raw.Substring(0, $idx)
$newBlock = $lines -join "`n"
$newFile  = $prefix + $marker + "`n" + $newBlock + "`n];"
[System.IO.File]::WriteAllText($DATA_JS, $newFile, [System.Text.Encoding]::UTF8)

# ── Summary ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Videos added to data.js : $($allVideos.Count)"
Write-Host "  Channels processed      : $($total - $downChannels.Count) / $total"
if ($downChannels.Count -gt 0) {
    Write-Host "  DOWN / not found ($($downChannels.Count)):" -ForegroundColor Red
    foreach ($d in $downChannels) { Write-Host "    - $d" -ForegroundColor Red }
}
Write-Host "============================================" -ForegroundColor Cyan
