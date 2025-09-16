Write-Out "`n=== Checking for Rocksalt User ===`n" -ForegroundColor DarkYellow

function Add-RocksaltUser {
  //ifdef INPUT
  if (Read-Y "Create local Rocksalt user?") {
    $password = Read-Host "Enter password" -AsSecureString
    New-LocalUser -Name "Rocksalt" -Password $password -FullName "Rocksalt" -Description "Rocksalt" | Out-Null
    Add-LocalGroupMember -Group "Administrators" -Member "Rocksalt" | Out-Null
    Write-Out "Rocksalt user created"
    return "Yes"
  }
  //endif
  return "No"
}

if ($Admins -contains "$env:COMPUTERNAME\Rocksalt") {
  Write-Out "Local Rocksalt user exits and is administrator"
  $rocksaltExists = "Yes"
}
elseif ($Admins -match '\\Rocksalt$') {
  Write-Out "Warning: Rocksalt is an administrator, but it's a domain account" -ForegroundColor Yellow

  $rocksaltExists = Add-RocksaltUser
}
elseif (Get-LocalUser -Name "Rocksalt" -ErrorAction SilentlyContinue) {
  Write-Error "Local Rocksalt user is not administrator"

  if (Read-Y "Make Rocksalt admin?") {
    Add-LocalGroupMember -Group "Administrators" -Member "Rocksalt"
    Write "Local Rocksalt user added to Administrators group"
    $rocksaltExists = "Yes"
  }
  else {
    $rocksaltExists = "No"
  }
}
else {
  Write-Error "Local Rocksalt user does not exist"

  $rocksaltExists = Add-RocksaltUser
}
