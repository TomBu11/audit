Write-Out "`n=== Saving output ===`n" -ForegroundColor DarkYellow

$scriptPath = Split-Path -Parent ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
Write-Out "Script directory: $scriptPath"
$outPaths = @(
  $scriptPath
  $rocksaltPath
) | Select-Object -Unique

foreach ($path in $outPaths) {
  $auditFile = Join-Path $path "Audit.txt"
  $line | Out-File -Append -FilePath $auditFile
  Write-Out "Audit information has been appended to $auditFile"

  $bitlockerFile = Join-Path $path $bitlockerFilename
  "$bitlockerID`n$bitlockerKey" | Out-File -FilePath $bitlockerFile
  if (Test-Path $bitlockerFile) {
    Write-Out "Bitlocker saved to $bitlockerFile`n"
  }
  else {
    Write-Error "Failed to save Bitlocker info to $bitlockerFile`n"
  }
}

Read-Host -Prompt "Press Enter to exit"