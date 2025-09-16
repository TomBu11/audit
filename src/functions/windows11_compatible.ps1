Write-Out "`n=== Checking Windows 11 compatibility ===`n" -ForegroundColor DarkYellow

$onWin11 = $os -match "11"

if ($HardwareReadiness.returnResult -eq "CAPABLE") {
  Write-Out "Windows 11 compatible" -ForegroundColor Green
  $win11Comp = "Yes"

  if (-not $onWin11) {
    Write-Warning "Computer is Windows 11 compatible but not updated"
  }
}
else {
  Write-Error "Not Windows 11 compatible"
  $win11Comp = "No"
  Write-Error "Reason: $($HardwareReadiness.returnReason)"

  if ($onWin11) {
    Write-Warning "Windows 11 is installed but not compatible"
  }
}