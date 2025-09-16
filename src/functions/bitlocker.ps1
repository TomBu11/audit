Write-Out "`n=== Checking Bitlocker ===`n" -ForegroundColor DarkYellow

if ($bitlocker.ProtectionStatus -eq 1) {
  Write-Out "Bitlocker is enabled" -ForegroundColor Green
  $bitlockerOn = "Yes"

  $protector = $bitlocker.KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' }

  $bitlockerID = "$($protector.KeyProtectorId)".Trim('{}')
  $bitlockerKey = "$($protector.RecoveryPassword)"
}
else {
  Write-Error "Bitlocker is not enabled"
  $bitlockerOn = "No"
}
