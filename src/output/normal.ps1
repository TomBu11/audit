$outTable = [PSCustomObject]@{
  Auditer          = "$auditer"
  Date             = "$date"
  Done             = "Part"
  Users            = "$name"
  GI               = "$gi"
  PCName           = "$computerName"
  Manufacturer     = "$manufacturer"
  Model            = "$model"
  Type             = "$type"
  SerialNumber     = "$serialNumber"
  OS               = "$os"
  Win11Compatible  = "$win11Comp"
  Updates          = "$updates"
  Drivers          = "$drivers"
  AntiVirus        = "$antiVirus"
  RocksaltExists   = "$rocksaltExists"
  ClientAdmin      = "$clientAdmin"
  UserName         = "$userName"
  DomainName       = "$domainName"
  Processor        = "$processor"
  RAM              = "$ram"
  RAMType          = "$ramType"
  DiskSize         = "$disk1Size"
  DiskType         = "$disk1Type"
  Disk2Size        = "$disk2Size"
  Disk2Type        = "$disk2Type"
  Bitlocker        = "$bitlockerOn"
  TeamViewer       = "$teamviewer"
  BruteForce       = "Yes"
  ChromeVersion    = "$chromeVersion"
  FirefoxVersion   = "$firefoxVersion"
  EdgeVersion      = "$edgeVersion"
  Office365Version = "$office365Version"
  OtherBrowsers    = "$otherBrowsers"
  SoftwareValid    = "$softwareValid"
  Notes            = "$notes"
}


$line = ($outTable.PSObject.Properties | ForEach-Object { $_.Value }) -join "`t"

Write-Out "`nTab-separated Line:`n" -ForegroundColor DarkYellow
Write-Out $line


Write-Out "`n=== Vertical Table ===`n" -ForegroundColor DarkYellow
$outTable | Format-List


Write-Out "`n=== Saving output ===`n" -ForegroundColor DarkYellow

$scriptPath = Split-Path -Parent ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
Write-Out "Script directory: $scriptPath"
$outPaths = @(
  $scriptPath
  $rocksaltPath
) | Select-Object -Unique

$bitlockerFile = (
  $(if ($gi ) { "$gi " } else { "" }) +
  $(if ($name) { "$name " } else { "" }) +
  "$env:COMPUTERNAME Bitlocker " +
  "$bitlockerID.txt"
)

foreach ($path in $outPaths) {
  $auditPath = Join-Path $path "Audit.txt"
  $line | Out-File -Append -FilePath $auditPath
  Write-Out "Audit information has been appended to $auditPath"

  if ($bitlocker) {
    $bitlockerPath = Join-Path $path $bitlockerFile
    "$bitlockerID`n$bitlockerKey" | Out-File -FilePath $bitlockerPath
    if (Test-Path $bitlockerPath) {
      Write-Out "Bitlocker saved to $bitlockerPath`n"
    }
    else {
      Write-Error "Failed to save Bitlocker info to $bitlockerPath`n"
    }
  }
}

Read-Host -Prompt "Press Enter to exit"
