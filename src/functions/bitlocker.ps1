Write-Out "`n=== Checking Bitlocker ===`n" -ForegroundColor DarkYellow

function Get-Bitlocker {
  $mount = "C:"

  # Get current BitLocker state
  $bitlockerVolume = Get-CommandStatus -Command { Get-BitLockerVolume -MountPoint $mount } -Message 'BitLocker'

  if (-not $bitlockerVolume.KeyProtector) {
    Write-Error "BitLocker is not enabled"
    return $null
  }

  # Report encryption progress
  if ($bitlockerVolume.EncryptionPercentage -lt 100) {
    Write-Host "BitLocker still encrypting ($($bitlockerVolume.EncryptionPercentage)%)" -ForegroundColor Yellow
  }
  else {
    Write-Host "BitLocker is fully enabled and protected" -ForegroundColor Green
  }

  return $bitlockerVolume.KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' }
}

$bitlocker = Get-Bitlocker

if ($bitlocker) {
  $bitlockerOn = "Yes"

  $bitlockerID = "$($bitlocker.KeyProtectorId)".Trim('{}')
  $bitlockerKey = "$($bitlocker.RecoveryPassword)"
}
else {
  $bitlockerOn = "No"
}
