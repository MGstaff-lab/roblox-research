$SB_URL = 'https://ahpzdwemvunyaumrnxal.supabase.co/rest/v1'
$SB_KEY = 'sb_publishable_NPPdURwPz_DEt6JG--haaw_CThnEoQF'
$sbHdr  = @{ apikey = $SB_KEY; Authorization = "Bearer $SB_KEY" }

Write-Host '=== Finding duplicate channels ==='

# Load channels - use JavaScriptSerializer to avoid PS 5.1 ConvertFrom-Json quirks
$r = Invoke-WebRequest -Uri ($SB_URL + '/channels?select=id,name,url,niche,subscribers&limit=1000') -Headers $sbHdr -UseBasicParsing

[void][System.Reflection.Assembly]::LoadWithPartialName('System.Web.Extensions')
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$ser.MaxJsonLength = [int]::MaxValue
$raw = $ser.DeserializeObject($r.Content)

# Convert ArrayList of Hashtables to PSCustomObjects
$channels = @($raw | ForEach-Object {
    [PSCustomObject]@{
        id          = $_['id']
        name        = $_['name']
        url         = $_['url']
        niche       = $_['niche']
        subscribers = $_['subscribers']
    }
})

Write-Host ('Total channels in Supabase: ' + $channels.Count)

# Group by lowercased name to find duplicates
$groups = $channels | Group-Object { $_.name.Trim().ToLower() } | Where-Object { $_.Count -gt 1 } | Sort-Object Name

if ($groups.Count -eq 0) {
    Write-Host 'No duplicate channel names found.'
    exit 0
}

Write-Host ("`nFound " + $groups.Count + ' duplicate group(s):')
Write-Host ('=' * 70)

foreach ($g in $groups) {
    Write-Host ("`nDUPLICATE: [" + $g.Group[0].name + "]  (" + $g.Count + " entries)")
    $i = 1
    foreach ($ch in $g.Group) {
        Write-Host ("  [$i] ID   : " + $ch.id)
        Write-Host ("      URL  : " + $ch.url)
        Write-Host ("      Niche: " + $ch.niche)
        Write-Host ("      Subs : " + $ch.subscribers)
        $i++
    }
}

Write-Host ''
Write-Host ('=' * 70)
$extraCount = ($groups | ForEach-Object { $_.Count - 1 } | Measure-Object -Sum).Sum
Write-Host ("$extraCount duplicate row(s) to remove across $($groups.Count) channel(s)")
