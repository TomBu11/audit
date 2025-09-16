Write-Out "`n=== Checking Teamviewer ===`n" -ForegroundColor DarkYellow

function Install-TeamViewer {
  Write-Out "Installing TeamViewer..."
  $teamviewerInstaller = Join-Path -Path $rocksaltPath -ChildPath "TeamViewer_Host_Setup.exe"

  # Download TeamViewer
  Invoke-WebRequest -Uri "https://customdesignservice.teamviewer.com/download/windows/v15/65v9fp5/TeamViewer_Host_Setup.exe" -OutFile $teamviewerInstaller
  if (-not (Test-Path $teamviewerInstaller) -or ((Get-Item $teamviewerInstaller).Length -lt 1MB)) {
    Write-Out "Failed to download Rocksalt teamviwer installer" -ForegroundColor DarkYellow
    Write-Out "Trying generic download link..."
    Invoke-WebRequest -Uri "https://download.teamviewer.com/download/TeamViewer_Host_Setup.exe" -OutFile $teamviewerInstaller

    if (-not (Test-Path $teamviewerInstaller) -or ((Get-Item $teamviewerInstaller).Length -lt 1MB)) {
      Write-Error "Failed to download teamviewer from generic link"
      return $null
    }
  }

  Write-Out "TeamViewer installer downloaded to $teamviewerInstaller"

  # Install TeamViewer silently
  Start-Process $teamviewerInstaller -ArgumentList "/S", "/ACCEPTEULA=1" -WindowStyle Hidden -Wait
  if (!$?) {
    Write-Error "Failed to install TeamViewer"
    return $null
  }

  Write-Out "TeamViewer installed successfully"
  return Get-TeamViewerInfo
}

if (-not $TeamViewerInfo) {
  Write-Error "TeamViewer not installed"
  if (Read-Y "Install TeamViewer?") {
    $TeamViewerInfo = Install-TeamViewer
  }
}

$teamViewer = $TeamViewerInfo.ClientID
