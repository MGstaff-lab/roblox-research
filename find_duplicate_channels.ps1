$SB_URL = 'https://ahpzdwemvunyaumrnxal.supabase.co/rest/v1'
$SB_KEY = 'sb_publishable_NPPdURwPz_DEt6JG--haaw_CThnEoQF'
$sbHdr  = @{ apikey = $SB_KEY; Authorization = "Bearer $SB_KEY" }

Write-Host '=== Finding duplicate channels ==='

$r = Invoke-WebRequest -Uri ($SB_URL + '/channels?select=id,name,url,niche,subscribers&limit=1000') -Headers $sbHdr -UseBasicParsing
[void][System.Reflection.Assembly]::LoadWithPartialName('System.Web.Extensions')
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$ser.MaxJsonLength = [int]::MaxValue
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

Write-Host ('Total channels: ' + $channels.Count)

# Load video counts per channel_id
Write-Host 'Loading video counts per channel...'
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

# Group duplicates
$groups = $channels | Group-Object { $_.name.Trim().ToLower() } | Where-Object { $_.Count -gt 1 } | Sort-Object Name

Write-Host ('Duplicate groups: ' + $groups.Count)
Write-Host ''

foreach ($g in $groups) {
    Write-Host ('Channel: ' + $g.Group[0].name)
    foreach ($ch in $g.Group) {
        $vc = if ($vidCount.ContainsKey($ch.id)) { $vidCount[$ch.id] } else { 0 }
        Write-Host ('  ID=' + $ch.id + '  videos=' + $vc + '  niche=' + $ch.niche + '  url=' + $ch.url)
    }
}
