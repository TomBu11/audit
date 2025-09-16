Write-Out "`n=== Checking Bitlocker ===`n" -ForegroundColor DarkYellow

if ($bitlocker.ProtectionStatus -eq 1) {
  Write-Out "Bitlocker is enabled" -ForegroundColor Green
  $bitlockerOn = "Yes"

  $protector = $bitlocker.KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' }

  //ifdef NO_INPUT
  $bitlockerFilename += "$env:COMPUTERNAME Bitlocker $($protector.KeyProtectorId).txt"
  //else
  $bitlockerFilename += "$gi $name $env:COMPUTERNAME Bitlocker $($protector.KeyProtectorId).txt"
  //endif

  $bitlockerInfo = "$($protector.KeyProtectorId)`n$($protector.RecoveryPassword)"
}
else {
  Write-Error "Bitlocker is not enabled"
  $bitlockerOn = "No"
}
