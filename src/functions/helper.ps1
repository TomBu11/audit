function Write-Out {
  param (
    [string]$Message,
    [ConsoleColor]$ForegroundColor = "White"
  )
  //ifdef OUTPUT
  Write-Host $Message -ForegroundColor $ForegroundColor
  //endif
}

function Write-Error {
  param (
    [string]$Message
  )
  Write-Out $Message -ForegroundColor Red
}

function Write-Warning {
  param (
    [string]$Message
  )
  Write-Out "Warning: $Message" -ForegroundColor Yellow
  $warnings += $Message
}

function Get-CommandStatus {
  param (
    [ScriptBlock]$Command,
    [string]$Message
  )

  try {
    $CommandResult = & $Command
    if ($?) {
      Write-Out "Got $Message"
    }
    else {
      Write-Error "Failed to get $Message"
    }
  }
  catch {
    Write-Error "Error while getting ${Message}: $_"
    $CommandResult = $null  # In case of an error, return $null
  }

  return $CommandResult
}

# (from https://www.dmtf.org/sites/default/files/standards/documents/DSP0134_3.4.0a.pdf)
Function Convert-RamMemoryType([Parameter(Mandatory = $true)]$MemoryTypeDecimal) {
  switch ($MemoryTypeDecimal) {
    00 { 'Unknown' }
    01 { 'Other' }
    02 { 'DRAM' }
    03 { 'Synchronous DRAM' }
    04 { 'Cache DRAM' }
    05 { 'EDO' }
    06 { 'EDRAM' }
    07 { 'VRAM' }
    08 { 'SRAM' }
    09 { 'RAM' }
    10 { 'ROM' }
    11 { 'FLASH' }
    12 { 'EEPROM' }
    13 { 'FEPROM' }
    14 { 'EPROM' }
    15 { 'CDRAM' }
    16 { '3DRAM' }
    17 { 'SDRAM' }
    18 { 'SGRAM' }
    19 { 'RDRAM' }
    20 { 'DDR' }
    21 { 'DDR2' }
    22 { 'DDR FB-DIMM' }
    24 { 'DDR3' }
    25 { 'FBD2' }
    26 { 'DDR4' }
    27 { 'LPDDR' }
    28 { 'LPDDR2' }
    29 { 'LPDDR3' }
    30 { 'LPDDR4' }
    31 { 'Logical non-volatile device' }
    32 { 'HBM' }
    33 { 'HBM2' }
    34 { 'DDR5' }
    35 { 'LPDDR5' }
    Default { 'Unknown' }
  }
}

function Read-Y($prompt) {
  //ifdef INPUT
  do {
    $response = Read-Host "$prompt (Y/n)"
  } while ($response -notmatch '^(y|n|)$')
  return $response -ne 'n'
  //else
  return $true
  //endif
}

function Read-N($prompt) {
  //ifdef INPUT
  do {
    $response = Read-Host "$prompt (y/N)"
  } while ($response -notmatch '^(y|n|)$')
  return $response -eq 'y'
  //else
  return $false
  //endif
}

function Read-No($prompt) {
  if (Read-N($prompt)) {
    return "Yes"
  }
  else {
    return "No"
  }
}
