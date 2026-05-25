$SB_URL = 'https://ahpzdwemvunyaumrnxal.supabase.co/rest/v1'
$SB_KEY = 'sb_publishable_NPPdURwPz_DEt6JG--haaw_CThnEoQF'
$sbHdr  = @{ apikey = $SB_KEY; Authorization = "Bearer $SB_KEY" }

Write-Host '=== Finding duplicate channels ==='

$r        = Invoke-WebRequest -Uri ($SB_URL + '/channels?select=id,name,url,niche,subscribers&limit=1000') -Headers $sbHdr -UseBasicParsing
$channels = @($r.Content | ConvertFrom-Json)
Write-Host ('Total channels in Supabase: ' + $channels.Count)

# Group by lowercased name
$byName = @{}
foreach ($ch in $channels) {
    $key = $ch.name.Trim().ToLower()
    if (-not $byName.ContainsKey($key)) { $byName[$key] = [System.Collections.Generic.List[object]]::new() }
    $byName[$key].Add($ch)
}

$dupes = $byName.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 } | Sort-Object { $_.Value[0].name }

if ($dupes.Count -eq 0) {
    Write-Host 'No duplicate channel names found.'
} else {
    Write-Host ("`nFound " + $dupes.Count + ' duplicate group(s):')
    Write-Host ('=' * 70)
    foreach ($g in $dupes) {
        Write-Host ("`nName: [" + $g.Value[0].name + "]")
        foreach ($ch in $g.Value) {
            Write-Host ('  ID       : ' + $ch.id)
            Write-Host ('  URL      : ' + $ch.url)
            Write-Host ('  Niche    : ' + $ch.niche)
            Write-Host ('  Subs     : ' + $ch.subscribers)
            Write-Host ''
        }
    }
    Write-Host ('=' * 70)
    Write-Host ("`nTotal duplicate entries: " + ($dupes | ForEach-Object { $_.Value.Count - 1 } | Measure-Object -Sum).Sum + ' extra row(s) to remove')
}
