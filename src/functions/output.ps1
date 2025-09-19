Write-Out "`n=== Saving output ===`n" -ForegroundColor DarkYellow

$scriptPath = Split-Path -Parent ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
Write-Out "Script directory: $scriptPath"
$outPaths = @(
  $scriptPath
  $rocksaltPath
) | Select-Object -Unique

$bitlockerFile = (
  $(if ($gi ) { "GI$gi " } else { "" }) +
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