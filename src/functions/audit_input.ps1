Write-Out "`n=== Audit information ===`n" -ForegroundColor DarkYellow

$auditer = Read-Host "RS (initials)"
$name = Read-Host "Name"
$gi = "GI$((Read-Host "GI") -replace '\D', '')"
if ($gi.Length -ge 5 -and (Read-Y "Rename computer from $env:COMPUTERNAME to $gi?")) {
  Rename-Computer -NewName "$gi"
}
Write-Out "`nLast update:`n$lastUpdate"
$updates = Read-No "Updates"
$drivers = Read-No "Drivers"
$antiVirus = Read-No "Antivirus"

Write-Out "`nClient Admin:"
for ($i = 0; $i -lt $Admins.Count; $i++) {
  Write-Out " [$($i + 1)] $($Admins[$i])"
}
$clientAdmin = Read-Host "Enter number or custom"
if ($clientAdmin -as [int] -and $clientAdmin -gt 0 -and $clientAdmin -le $Admins.Count) {
  $clientAdmin = $Admins[$clientAdmin - 1]
}

Write-Out "`nUsername (Account they use):"
for ($i = 0; $i -lt $Users.Count; $i++) {
  Write-Out " [$($i + 1)] $($Users[$i])"
}
$userName = Read-Host "Enter number or custom"
if ($userName -as [int] -and $userName -gt 0 -and $userName -le $Users.Count) {
  $userName = $Users[$userName - 1]
}

Write-Out "`nChrome version: $chromeVersion`nFirefox version: $firefoxVersion`nEdge version: $edgeVersion"

$otherBrowsers = Read-Host "Other browsers"
$softwareValid = Read-No "Software valid?"
$notes = Read-Host "Notes"
