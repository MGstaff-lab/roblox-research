$SB_URL = 'https://ahpzdwemvunyaumrnxal.supabase.co/rest/v1'
$SB_KEY = 'sb_publishable_NPPdURwPz_DEt6JG--haaw_CThnEoQF'
$sbHdr  = @{ apikey = $SB_KEY; Authorization = "Bearer $SB_KEY"; 'Content-Type' = 'application/json' }

[void][System.Reflection.Assembly]::LoadWithPartialName('System.Web.Extensions')
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$ser.MaxJsonLength = [int]::MaxValue

Write-Host '=== Deduplicating channels ==='

# -- 1. Load all channels --
$r = Invoke-WebRequest -Uri ($SB_URL + '/channels?select=id,name,url,niche,subscribers&limit=1000') -Headers $sbHdr -UseBasicParsing
$raw = $ser.DeserializeObject($r.Content)
$channels = @($raw | ForEach-Object {
    [PSCustomObject]@{
        id          = $_['id']
        name        = $_['name']
        url         = $_['url']
        niche       = $_['niche']
        subscribers = $_['subscribers']
    }
})
Write-Host ('Total channels loaded: ' + $channels.Count)

# -- 2. Load video counts per channel_id --
Write-Host 'Loading video counts...'
$vcR = Invoke-WebRequest -Uri ($SB_URL + '/videos?select=channel_id&limit=50000') -Headers $sbHdr -UseBasicParsing
$vcRaw = $ser.DeserializeObject($vcR.Content)
$vidCount = @{}
foreach ($v in $vcRaw) {
    $cid = $v['channel_id']
    if ($cid) {
        if (-not $vidCount.ContainsKey($cid)) { $vidCount[$cid] = 0 }
        $vidCount[$cid]++
    }
}
Write-Host ('Video count map built for ' + $vidCount.Count + ' channels')

# -- 3. Group duplicates --
$groups = $channels | Group-Object { $_.name.Trim().ToLower() } | Where-Object { $_.Count -gt 1 }
Write-Host ('Duplicate groups: ' + $groups.Count)
Write-Host ''

$totalDeleted  = 0
$totalReassigned = 0
$errors = 0

foreach ($g in $groups) {
    $members = @($g.Group)

    # Pick winner: most videos, then has real niche, then first
    $winner = $null
    foreach ($ch in $members) {
        $vc = if ($vidCount.ContainsKey($ch.id)) { $vidCount[$ch.id] } else { 0 }
        $ch | Add-Member -NotePropertyName vidCount -NotePropertyValue $vc -Force
    }
    $winner = $members | Sort-Object -Property @(
        @{ Expression = 'vidCount'; Descending = $true },
        @{ Expression = { if ($_.niche -and $_.niche -ne 'Unnasign') { 1 } else { 0 } }; Descending = $true }
    ) | Select-Object -First 1

    $losers = $members | Where-Object { $_.id -ne $winner.id }

    Write-Host ('=== ' + $winner.name + ' ===')
    Write-Host ('  KEEP  -> ID=' + $winner.id + '  videos=' + $winner.vidCount + '  niche=' + $winner.niche)

    foreach ($loser in $losers) {
        Write-Host ('  DELETE -> ID=' + $loser.id + '  videos=' + $loser.vidCount + '  niche=' + $loser.niche)

        # Reassign videos: UPDATE videos SET channel_id = winner WHERE channel_id = loser
        if ($loser.vidCount -gt 0) {
            $patchBody = [System.Text.Encoding]::UTF8.GetBytes(('{"channel_id":"' + $winner.id + '"}'))
            $patchHdr  = $sbHdr.Clone()
            try {
                Invoke-RestMethod -Uri ($SB_URL + '/videos?channel_id=eq.' + $loser.id) `
                    -Method Patch -Headers $patchHdr -Body $patchBody | Out-Null
                Write-Host ('    Reassigned ' + $loser.vidCount + ' videos to winner')
                $totalReassigned += $loser.vidCount
            } catch {
                Write-Host ('    ERROR reassigning videos: ' + $_.Exception.Message)
                $errors++
                continue
            }
        }

        # Delete the loser channel
        try {
            Invoke-RestMethod -Uri ($SB_URL + '/channels?id=eq.' + $loser.id) `
                -Method Delete -Headers $sbHdr | Out-Null
            Write-Host ('    Deleted channel ' + $loser.id)
            $totalDeleted++
        } catch {
            Write-Host ('    ERROR deleting channel: ' + $_.Exception.Message)
            $errors++
        }
    }
}

Write-Host ''
Write-Host ('=== DONE ===')
Write-Host ('  Channels deleted : ' + $totalDeleted)
Write-Host ('  Videos reassigned: ' + $totalReassigned)
Write-Host ('  Errors           : ' + $errors)

# Final count
$hdrC = $sbHdr.Clone(); $hdrC['Prefer'] = 'count=exact'
try {
    $fc = Invoke-WebRequest -Uri ($SB_URL + '/channels?select=id&limit=1') -Headers $hdrC -UseBasicParsing
    Write-Host ('  Channels remaining in Supabase: ' + $fc.Headers['Content-Range'])
} catch {}
