Write-Out "`n=== Getting system information ===`n" -ForegroundColor DarkYellow

$ComputerInfo = Get-CommandStatus -Command { Get-ComputerInfo } -Message 'computer info'
$RamInfo = Get-CommandStatus -Command { Get-WmiObject -Class Win32_PhysicalMemory } -Message 'RAM'
$Admins = @( Get-CommandStatus -Command { Get-LocalGroupMember -Group "Administrators" | Select-Object -ExpandProperty Name } -Message 'admins' )
$Users = @( Get-CommandStatus -Command { Get-LocalGroupMember -Group "Users" | Where-Object {
      $Admins -notcontains $_.Name -and
      $_.Name -notmatch "^NT AUTHORITY" -and
      $_.Name -notmatch "^BUILTIN"
    } | Select-Object -ExpandProperty Name } -Message 'users' )
$PhysicalDisks = Get-CommandStatus -Command { Get-PhysicalDisk } -Message 'disks'
$InstalledSoftware = Get-CommandStatus -Command { Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* } -Message 'software'
$HardwareReadiness = Get-CommandStatus -Command { Invoke-Expression $hardwareReadinessScript 2>&1 | Out-String | ConvertFrom-Json } -Message 'hardware readiness'

$date = Get-Date -Format "yyyy-MM-dd"
$manufacturer = $ComputerInfo.CsManufacturer
$model = "$($ComputerInfo.CsSystemFamily), $($ComputerInfo.CsModel)"
$type = if ($ComputerInfo.CsPCSystemType -eq 2) { "Laptop" } else { "Desktop" }
$serialNumber = $ComputerInfo.BiosSeralNumber
$os = $ComputerInfo.OSName
$lastUpdate = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 1 InstalledOn, HotFixID, Description | Out-String
$domainName = $ComputerInfo.CsDomain
$processor = $ComputerInfo.CsProcessors.Name -join ', '
$ram = "$([math]::Round($ComputerInfo.CsTotalPhysicalMemory / 1GB))GB"
try {
  $ramType = Convert-RamMemoryType -MemoryTypeDecimal ($RamInfo[0].SMBIOSMemoryType)
}
catch {
  $ramType = "Unknown"
}
$disk1Size = "$([math]::Round($PhysicalDisks[0].Size / 1GB))GB"
$disk1Type = "$($PhysicalDisks[0].MediaType) $($PhysicalDisks[0].BusType)"
if ($PhysicalDisks.Count -gt 1) {
  $disk2Size = "$([math]::Round($PhysicalDisks[1].Size / 1GB))GB"
  $disk2Type = "$($PhysicalDisks[1].MediaType) $($PhysicalDisks[1].BusType)"
}
else {
  $disk2Size = "N/A"
  $disk2Type = "N/A"
}
$chromeVersion = ($InstalledSoftware | Where-Object { $_.DisplayName -eq "Google Chrome" }).DisplayVersion
$firefoxVersion = ($InstalledSoftware | Where-Object { $_.DisplayName -eq "Mozilla Firefox" }).DisplayVersion
$edgeVersion = ($InstalledSoftware | Where-Object { $_.DisplayName -eq "Microsoft Edge" }).DisplayVersion

if ($physicalDisks.Count -gt 2) {
  Write-Warning "More than 2 disks detected"
}
