$lineTable = [PSCustomObject]@{
  Auditer         = $auditer
  Date            = $date
  Done            = "Part"
  Users           = $name
  GI              = $gi
  PCName          = $env:COMPUTERNAME
  Manufacturer    = $manufacturer
  Model           = $model
  Type            = $type
  SerialNumber    = $serialNumber
  OS              = $os
  Win11Compatible = $win11Comp
  Updates         = $updates
  Drivers         = $drivers
  AntiVirus       = $antiVirus
  RocksaltExists  = $rocksaltExists
  ClientAdmin     = $clientAdmin
  UserName        = $userName
  DomainName      = $domainName
  Processor       = $processor
  RAM             = $ram
  RAMType         = $ramType
  DiskSize        = $disk1Size
  DiskType        = $disk1Type
  Disk2Size       = $disk2Size
  Disk2Type       = $disk2Type
  Bitlocker       = $bitlockerOn
  TeamViewer      = $teamviewer
  BruteForce      = "Yes"
  ChromeVersion   = $chromeVersion
  FirefoxVersion  = $firefoxVersion
  EdgeVersion     = $edgeVersion
  OtherBrowsers   = $otherBrowsers
  SoftwareValid   = $softwareValid
  Notes           = $notes
}

$line = ($lineTable.PSObject.Properties | ForEach-Object { $_.Value }) -join "`t"

Write-Out "`nTab-separated Line:`n" -ForegroundColor DarkYellow
Write-Out $line

Write-Out "`n=== Vertical Table ===`n" -ForegroundColor DarkYellow
$lineTable | Format-List