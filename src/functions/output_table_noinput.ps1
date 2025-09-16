

$outTable = [PSCustomObject]@{
  Date            = $date
  PCName          = $env:COMPUTERNAME
  Manufacturer    = $manufacturer
  Model           = $model
  Type            = $type
  SerialNumber    = $serialNumber
  OS              = $os
  Win11Compatible = $win11Comp
  Updates         = $lastUpdate
  RocksaltExists  = $rocksaltExists
  ClientAdmin     = "$Admins"
  UserName        = "$Users"
  DomainName      = $domainName
  Processor       = $processor
  RAM             = $ram
  RAMType         = $ramType
  DiskSize        = $disk1Size
  DiskType        = $disk1Type
  Disk2Size       = $disk2Size
  Disk2Type       = $disk2Type
  Bitlocker       = $bitlockerOn
  BitlockerID     = $bitlockerID
  BitlockerKey    = $bitlockerKey
  TeamViewer      = $teamviewer
  BruteForce      = "Yes"
  ChromeVersion   = $chromeVersion
  FirefoxVersion  = $firefoxVersion
  EdgeVersion     = $edgeVersion
  Notes           = $notes
}
