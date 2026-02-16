#Requires -RunAsAdministrator

# Version: v1.1.5
# DateTime: 2026-02-16 16:58:08

$hardwareReadinessScript = @'
#=============================================================================================================================
#
# Script Name:     HardwareReadiness.ps1
# Description:     Verifies the hardware compliance. Return code 0 for success.
#                  In case of failure, returns non zero error code along with error message.

# This script is not supported under any Microsoft standard support program or service and is distributed under the MIT license

# Copyright (C) 2021 Microsoft Corporation

# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
# modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software
# is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#=============================================================================================================================

$exitCode = 0

[int]$MinOSDiskSizeGB = 64
[int]$MinMemoryGB = 4
[Uint32]$MinClockSpeedMHz = 1000
[Uint32]$MinLogicalCores = 2
[Uint16]$RequiredAddressWidth = 64

$PASS_STRING = "PASS"
$FAIL_STRING = "FAIL"
$FAILED_TO_RUN_STRING = "FAILED TO RUN"
$UNDETERMINED_CAPS_STRING = "UNDETERMINED"
$UNDETERMINED_STRING = "Undetermined"
$CAPABLE_STRING = "Capable"
$NOT_CAPABLE_STRING = "Not capable"
$CAPABLE_CAPS_STRING = "CAPABLE"
$NOT_CAPABLE_CAPS_STRING = "NOT CAPABLE"
$STORAGE_STRING = "Storage"
$OS_DISK_SIZE_STRING = "OSDiskSize"
$MEMORY_STRING = "Memory"
$SYSTEM_MEMORY_STRING = "System_Memory"
$GB_UNIT_STRING = "GB"
$TPM_STRING = "TPM"
$TPM_VERSION_STRING = "TPMVersion"
$PROCESSOR_STRING = "Processor"
$SECUREBOOT_STRING = "SecureBoot"
$I7_7820HQ_CPU_STRING = "i7-7820hq CPU"

# 0=name of check, 1=attribute checked, 2=value, 3=PASS/FAIL/UNDETERMINED
$logFormat = '{0}: {1}={2}. {3}; '

# 0=name of check, 1=attribute checked, 2=value, 3=unit of the value, 4=PASS/FAIL/UNDETERMINED
$logFormatWithUnit = '{0}: {1}={2}{3}. {4}; '

# 0=name of check.
$logFormatReturnReason = '{0}, '

# 0=exception.
$logFormatException = '{0}; '

# 0=name of check, 1= attribute checked and its value, 2=PASS/FAIL/UNDETERMINED
$logFormatWithBlob = '{0}: {1}. {2}; '

# return returnCode is -1 when an exception is thrown. 1 if the value does not meet requirements. 0 if successful. -2 default, script didn't run.
$outObject = @{ returnCode = -2; returnResult = $FAILED_TO_RUN_STRING; returnReason = ""; logging = "" }

# NOT CAPABLE(1) state takes precedence over UNDETERMINED(-1) state
function Private:UpdateReturnCode {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateRange(-2, 1)]
        [int] $ReturnCode
    )

    Switch ($ReturnCode) {

        0 {
            if ($outObject.returnCode -eq -2) {
                $outObject.returnCode = $ReturnCode
            }
        }
        1 {
            $outObject.returnCode = $ReturnCode
        }
        -1 {
            if ($outObject.returnCode -ne 1) {
                $outObject.returnCode = $ReturnCode
            }
        }
    }
}

$Source = @"
using Microsoft.Win32;
using System;
using System.Runtime.InteropServices;

    public class CpuFamilyResult
    {
        public bool IsValid { get; set; }
        public string Message { get; set; }
    }

    public class CpuFamily
    {
        [StructLayout(LayoutKind.Sequential)]
        public struct SYSTEM_INFO
        {
            public ushort ProcessorArchitecture;
            ushort Reserved;
            public uint PageSize;
            public IntPtr MinimumApplicationAddress;
            public IntPtr MaximumApplicationAddress;
            public IntPtr ActiveProcessorMask;
            public uint NumberOfProcessors;
            public uint ProcessorType;
            public uint AllocationGranularity;
            public ushort ProcessorLevel;
            public ushort ProcessorRevision;
        }

        [DllImport("kernel32.dll")]
        internal static extern void GetNativeSystemInfo(ref SYSTEM_INFO lpSystemInfo);

        public enum ProcessorFeature : uint
        {
            ARM_SUPPORTED_INSTRUCTIONS = 34
        }

        [DllImport("kernel32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        static extern bool IsProcessorFeaturePresent(ProcessorFeature processorFeature);

        private const ushort PROCESSOR_ARCHITECTURE_X86 = 0;
        private const ushort PROCESSOR_ARCHITECTURE_ARM64 = 12;
        private const ushort PROCESSOR_ARCHITECTURE_X64 = 9;

        private const string INTEL_MANUFACTURER = "GenuineIntel";
        private const string AMD_MANUFACTURER = "AuthenticAMD";
        private const string QUALCOMM_MANUFACTURER = "Qualcomm Technologies Inc";

        public static CpuFamilyResult Validate(string manufacturer, ushort processorArchitecture)
        {
            CpuFamilyResult cpuFamilyResult = new CpuFamilyResult();

            if (string.IsNullOrWhiteSpace(manufacturer))
            {
                cpuFamilyResult.IsValid = false;
                cpuFamilyResult.Message = "Manufacturer is null or empty";
                return cpuFamilyResult;
            }

            string registryPath = "HKEY_LOCAL_MACHINE\\Hardware\\Description\\System\\CentralProcessor\\0";
            SYSTEM_INFO sysInfo = new SYSTEM_INFO();
            GetNativeSystemInfo(ref sysInfo);

            switch (processorArchitecture)
            {
                case PROCESSOR_ARCHITECTURE_ARM64:

                    if (manufacturer.Equals(QUALCOMM_MANUFACTURER, StringComparison.OrdinalIgnoreCase))
                    {
                        bool isArmv81Supported = IsProcessorFeaturePresent(ProcessorFeature.ARM_SUPPORTED_INSTRUCTIONS);

                        if (!isArmv81Supported)
                        {
                            string registryName = "CP 4030";
                            long registryValue = (long)Registry.GetValue(registryPath, registryName, -1);
                            long atomicResult = (registryValue >> 20) & 0xF;

                            if (atomicResult >= 2)
                            {
                                isArmv81Supported = true;
                            }
                        }

                        cpuFamilyResult.IsValid = isArmv81Supported;
                        cpuFamilyResult.Message = isArmv81Supported ? "" : "Processor does not implement ARM v8.1 atomic instruction";
                    }
                    else
                    {
                        cpuFamilyResult.IsValid = false;
                        cpuFamilyResult.Message = "The processor isn't currently supported for Windows 11";
                    }

                    break;

                case PROCESSOR_ARCHITECTURE_X64:
                case PROCESSOR_ARCHITECTURE_X86:

                    int cpuFamily = sysInfo.ProcessorLevel;
                    int cpuModel = (sysInfo.ProcessorRevision >> 8) & 0xFF;
                    int cpuStepping = sysInfo.ProcessorRevision & 0xFF;

                    if (manufacturer.Equals(INTEL_MANUFACTURER, StringComparison.OrdinalIgnoreCase))
                    {
                        try
                        {
                            cpuFamilyResult.IsValid = true;
                            cpuFamilyResult.Message = "";

                            if (cpuFamily >= 6 && cpuModel <= 95 && !(cpuFamily == 6 && cpuModel == 85))
                            {
                                cpuFamilyResult.IsValid = false;
                                cpuFamilyResult.Message = "";
                            }
                            else if (cpuFamily == 6 && (cpuModel == 142 || cpuModel == 158) && cpuStepping == 9)
                            {
                                string registryName = "Platform Specific Field 1";
                                int registryValue = (int)Registry.GetValue(registryPath, registryName, -1);

                                if ((cpuModel == 142 && registryValue != 16) || (cpuModel == 158 && registryValue != 8))
                                {
                                    cpuFamilyResult.IsValid = false;
                                }
                                cpuFamilyResult.Message = "PlatformId " + registryValue;
                            }
                        }
                        catch (Exception ex)
                        {
                            cpuFamilyResult.IsValid = false;
                            cpuFamilyResult.Message = "Exception:" + ex.GetType().Name;
                        }
                    }
                    else if (manufacturer.Equals(AMD_MANUFACTURER, StringComparison.OrdinalIgnoreCase))
                    {
                        cpuFamilyResult.IsValid = true;
                        cpuFamilyResult.Message = "";

                        if (cpuFamily < 23 || (cpuFamily == 23 && (cpuModel == 1 || cpuModel == 17)))
                        {
                            cpuFamilyResult.IsValid = false;
                        }
                    }
                    else
                    {
                        cpuFamilyResult.IsValid = false;
                        cpuFamilyResult.Message = "Unsupported Manufacturer: " + manufacturer + ", Architecture: " + processorArchitecture + ", CPUFamily: " + sysInfo.ProcessorLevel + ", ProcessorRevision: " + sysInfo.ProcessorRevision;
                    }

                    break;

                default:
                    cpuFamilyResult.IsValid = false;
                    cpuFamilyResult.Message = "Unsupported CPU category. Manufacturer: " + manufacturer + ", Architecture: " + processorArchitecture + ", CPUFamily: " + sysInfo.ProcessorLevel + ", ProcessorRevision: " + sysInfo.ProcessorRevision;
                    break;
            }
            return cpuFamilyResult;
        }
    }
"@

# Storage
try {
    $osDrive = Get-WmiObject -Class Win32_OperatingSystem | Select-Object -Property SystemDrive
    $osDriveSize = Get-WmiObject -Class Win32_LogicalDisk -filter "DeviceID='$($osDrive.SystemDrive)'" | Select-Object @{Name = "SizeGB"; Expression = { $_.Size / 1GB -as [int] } }

    if ($null -eq $osDriveSize) {
        UpdateReturnCode -ReturnCode 1
        $outObject.returnReason += $logFormatReturnReason -f $STORAGE_STRING
        $outObject.logging += $logFormatWithBlob -f $STORAGE_STRING, "Storage is null", $FAIL_STRING
        $exitCode = 1
    }
    elseif ($osDriveSize.SizeGB -lt $MinOSDiskSizeGB) {
        UpdateReturnCode -ReturnCode 1
        $outObject.returnReason += $logFormatReturnReason -f $STORAGE_STRING
        $outObject.logging += $logFormatWithUnit -f $STORAGE_STRING, $OS_DISK_SIZE_STRING, ($osDriveSize.SizeGB), $GB_UNIT_STRING, $FAIL_STRING
        $exitCode = 1
    }
    else {
        $outObject.logging += $logFormatWithUnit -f $STORAGE_STRING, $OS_DISK_SIZE_STRING, ($osDriveSize.SizeGB), $GB_UNIT_STRING, $PASS_STRING
        UpdateReturnCode -ReturnCode 0
    }
}
catch {
    UpdateReturnCode -ReturnCode -1
    $outObject.logging += $logFormat -f $STORAGE_STRING, $OS_DISK_SIZE_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
    $outObject.logging += $logFormatException -f "$($_.Exception.GetType().Name) $($_.Exception.Message)"
    $exitCode = 1
}

# Memory (bytes)
try {
    $memory = Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum | Select-Object @{Name = "SizeGB"; Expression = { $_.Sum / 1GB -as [int] } }

    if ($null -eq $memory) {
        UpdateReturnCode -ReturnCode 1
        $outObject.returnReason += $logFormatReturnReason -f $MEMORY_STRING
        $outObject.logging += $logFormatWithBlob -f $MEMORY_STRING, "Memory is null", $FAIL_STRING
        $exitCode = 1
    }
    elseif ($memory.SizeGB -lt $MinMemoryGB) {
        UpdateReturnCode -ReturnCode 1
        $outObject.returnReason += $logFormatReturnReason -f $MEMORY_STRING
        $outObject.logging += $logFormatWithUnit -f $MEMORY_STRING, $SYSTEM_MEMORY_STRING, ($memory.SizeGB), $GB_UNIT_STRING, $FAIL_STRING
        $exitCode = 1
    }
    else {
        $outObject.logging += $logFormatWithUnit -f $MEMORY_STRING, $SYSTEM_MEMORY_STRING, ($memory.SizeGB), $GB_UNIT_STRING, $PASS_STRING
        UpdateReturnCode -ReturnCode 0
    }
}
catch {
    UpdateReturnCode -ReturnCode -1
    $outObject.logging += $logFormat -f $MEMORY_STRING, $SYSTEM_MEMORY_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
    $outObject.logging += $logFormatException -f "$($_.Exception.GetType().Name) $($_.Exception.Message)"
    $exitCode = 1
}

# TPM
try {
    $tpm = Get-Tpm

    if ($null -eq $tpm) {
        UpdateReturnCode -ReturnCode 1
        $outObject.returnReason += $logFormatReturnReason -f $TPM_STRING
        $outObject.logging += $logFormatWithBlob -f $TPM_STRING, "TPM is null", $FAIL_STRING
        $exitCode = 1
    }
    elseif ($tpm.TpmPresent) {
        $tpmVersion = Get-WmiObject -Class Win32_Tpm -Namespace root\CIMV2\Security\MicrosoftTpm | Select-Object -Property SpecVersion

        if ($null -eq $tpmVersion.SpecVersion) {
            UpdateReturnCode -ReturnCode 1
            $outObject.returnReason += $logFormatReturnReason -f $TPM_STRING
            $outObject.logging += $logFormat -f $TPM_STRING, $TPM_VERSION_STRING, "null", $FAIL_STRING
            $exitCode = 1
        }

        $majorVersion = $tpmVersion.SpecVersion.Split(",")[0] -as [int]
        if ($majorVersion -lt 2) {
            UpdateReturnCode -ReturnCode 1
            $outObject.returnReason += $logFormatReturnReason -f $TPM_STRING
            $outObject.logging += $logFormat -f $TPM_STRING, $TPM_VERSION_STRING, ($tpmVersion.SpecVersion), $FAIL_STRING
            $exitCode = 1
        }
        else {
            $outObject.logging += $logFormat -f $TPM_STRING, $TPM_VERSION_STRING, ($tpmVersion.SpecVersion), $PASS_STRING
            UpdateReturnCode -ReturnCode 0
        }
    }
    else {
        if ($tpm.GetType().Name -eq "String") {
            UpdateReturnCode -ReturnCode -1
            $outObject.logging += $logFormat -f $TPM_STRING, $TPM_VERSION_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
            $outObject.logging += $logFormatException -f $tpm
        }
        else {
            UpdateReturnCode -ReturnCode  1
            $outObject.returnReason += $logFormatReturnReason -f $TPM_STRING
            $outObject.logging += $logFormat -f $TPM_STRING, $TPM_VERSION_STRING, ($tpm.TpmPresent), $FAIL_STRING
        }
        $exitCode = 1
    }
}
catch {
    UpdateReturnCode -ReturnCode -1
    $outObject.logging += $logFormat -f $TPM_STRING, $TPM_VERSION_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
    $outObject.logging += $logFormatException -f "$($_.Exception.GetType().Name) $($_.Exception.Message)"
    $exitCode = 1
}

# CPU Details
$cpuDetails;
try {
    $cpuDetails = @(Get-WmiObject -Class Win32_Processor)[0]

    if ($null -eq $cpuDetails) {
        UpdateReturnCode -ReturnCode 1
        $exitCode = 1
        $outObject.returnReason += $logFormatReturnReason -f $PROCESSOR_STRING
        $outObject.logging += $logFormatWithBlob -f $PROCESSOR_STRING, "CpuDetails is null", $FAIL_STRING
    }
    else {
        $processorCheckFailed = $false

        # AddressWidth
        if ($null -eq $cpuDetails.AddressWidth -or $cpuDetails.AddressWidth -ne $RequiredAddressWidth) {
            UpdateReturnCode -ReturnCode 1
            $processorCheckFailed = $true
            $exitCode = 1
        }

        # ClockSpeed is in MHz
        if ($null -eq $cpuDetails.MaxClockSpeed -or $cpuDetails.MaxClockSpeed -le $MinClockSpeedMHz) {
            UpdateReturnCode -ReturnCode 1;
            $processorCheckFailed = $true
            $exitCode = 1
        }

        # Number of Logical Cores
        if ($null -eq $cpuDetails.NumberOfLogicalProcessors -or $cpuDetails.NumberOfLogicalProcessors -lt $MinLogicalCores) {
            UpdateReturnCode -ReturnCode 1
            $processorCheckFailed = $true
            $exitCode = 1
        }

        # CPU Family
        Add-Type -TypeDefinition $Source
        $cpuFamilyResult = [CpuFamily]::Validate([String]$cpuDetails.Manufacturer, [uint16]$cpuDetails.Architecture)

        $cpuDetailsLog = "{AddressWidth=$($cpuDetails.AddressWidth); MaxClockSpeed=$($cpuDetails.MaxClockSpeed); NumberOfLogicalCores=$($cpuDetails.NumberOfLogicalProcessors); Manufacturer=$($cpuDetails.Manufacturer); Caption=$($cpuDetails.Caption); $($cpuFamilyResult.Message)}"

        if (!$cpuFamilyResult.IsValid) {
            UpdateReturnCode -ReturnCode 1
            $processorCheckFailed = $true
            $exitCode = 1
        }

        if ($processorCheckFailed) {
            $outObject.returnReason += $logFormatReturnReason -f $PROCESSOR_STRING
            $outObject.logging += $logFormatWithBlob -f $PROCESSOR_STRING, ($cpuDetailsLog), $FAIL_STRING
        }
        else {
            $outObject.logging += $logFormatWithBlob -f $PROCESSOR_STRING, ($cpuDetailsLog), $PASS_STRING
            UpdateReturnCode -ReturnCode 0
        }
    }
}
catch {
    UpdateReturnCode -ReturnCode -1
    $outObject.logging += $logFormat -f $PROCESSOR_STRING, $PROCESSOR_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
    $outObject.logging += $logFormatException -f "$($_.Exception.GetType().Name) $($_.Exception.Message)"
    $exitCode = 1
}

# SecureBooot
try {
    $isSecureBootEnabled = Confirm-SecureBootUEFI
    $outObject.logging += $logFormatWithBlob -f $SECUREBOOT_STRING, $CAPABLE_STRING, $PASS_STRING
    UpdateReturnCode -ReturnCode 0
}
catch [System.PlatformNotSupportedException] {
    # PlatformNotSupportedException "Cmdlet not supported on this platform." - SecureBoot is not supported or is non-UEFI computer.
    UpdateReturnCode -ReturnCode 1
    $outObject.returnReason += $logFormatReturnReason -f $SECUREBOOT_STRING
    $outObject.logging += $logFormatWithBlob -f $SECUREBOOT_STRING, $NOT_CAPABLE_STRING, $FAIL_STRING
    $exitCode = 1
}
catch [System.UnauthorizedAccessException] {
    UpdateReturnCode -ReturnCode -1
    $outObject.logging += $logFormatWithBlob -f $SECUREBOOT_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
    $outObject.logging += $logFormatException -f "$($_.Exception.GetType().Name) $($_.Exception.Message)"
    $exitCode = 1
}
catch {
    UpdateReturnCode -ReturnCode -1
    $outObject.logging += $logFormatWithBlob -f $SECUREBOOT_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
    $outObject.logging += $logFormatException -f "$($_.Exception.GetType().Name) $($_.Exception.Message)"
    $exitCode = 1
}

# i7-7820hq CPU
try {
    $supportedDevices = @('surface studio 2', 'precision 5520')
    $systemInfo = @(Get-WmiObject -Class Win32_ComputerSystem)[0]

    if ($null -ne $cpuDetails) {
        if ($cpuDetails.Name -match 'i7-7820hq cpu @ 2.90ghz'){
            $modelOrSKUCheckLog = $systemInfo.Model.Trim()
            if ($supportedDevices -contains $modelOrSKUCheckLog){
                $outObject.logging += $logFormatWithBlob -f $I7_7820HQ_CPU_STRING, $modelOrSKUCheckLog, $PASS_STRING
                $outObject.returnCode = 0
                $exitCode = 0
            }
        }
    }
}
catch {
    if ($outObject.returnCode -ne 0){
        UpdateReturnCode -ReturnCode -1
        $outObject.logging += $logFormatWithBlob -f $I7_7820HQ_CPU_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
        $outObject.logging += $logFormatException -f "$($_.Exception.GetType().Name) $($_.Exception.Message)"
        $exitCode = 1
    }
}

Switch ($outObject.returnCode) {

    0 { $outObject.returnResult = $CAPABLE_CAPS_STRING }
    1 { $outObject.returnResult = $NOT_CAPABLE_CAPS_STRING }
    -1 { $outObject.returnResult = $UNDETERMINED_CAPS_STRING }
    -2 { $outObject.returnResult = $FAILED_TO_RUN_STRING }
}

$outObject | ConvertTo-Json -Compress
'@


<# HELPER FUNCTIONS #>

function Write-Out {
  param (
    [string]$Message,
    [ConsoleColor]$ForegroundColor = "White"
  )
    Write-Host $Message -ForegroundColor $ForegroundColor
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
  $global:warnings += $Message
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
    do {
    $response = Read-Host "$prompt (Y/n)"
  } while ($response -notmatch '^(y|n|)$')
  return $response -ne 'n'
  }

function Read-N($prompt) {
    do {
    $response = Read-Host "$prompt (y/N)"
  } while ($response -notmatch '^(y|n|)$')
  return $response -eq 'y'
  }

function Read-No($prompt) {
  if (Read-N($prompt)) {
    return "Yes"
  }
  else {
    return "No"
  }
}


<# INITIAL SETUP #>

Write-Out "Audit script version v1.1.5`n" -ForegroundColor Green

$global:warnings = @()

$rocksaltPath = "C:\Rocksalt"

# Ensure rocksalt directory exists
if (-not (Test-Path -Path $rocksaltPath)) {
  New-Item -ItemType Directory -Path $rocksaltPath | Out-Null
  Write-Out "Rocksalt directory created: $rocksaltPath"
}
else {
  Write-Out "Rocksalt directory already exists: $rocksaltPath"
}


<# AUDIT INFORMATION #>

Write-Out "`n=== Getting system information ===`n" -ForegroundColor DarkYellow

$ComputerInfo = Get-CommandStatus -Command { Get-ComputerInfo } -Message 'computer info'
$RamInfo = Get-CommandStatus -Command { Get-WmiObject -Class Win32_PhysicalMemory } -Message 'RAM'
$Admins = @( Get-CommandStatus -Command { Get-LocalGroupMember -Group "Administrators" | Select-Object -ExpandProperty Name } -Message 'admins' )
$Users = @( Get-CommandStatus -Command { Get-LocalGroupMember -Group "Users" | Where-Object {
      $Admins -notcontains $_.Name -and
      $_.Name -notmatch "^NT AUTHORITY" -and
      $_.Name -notmatch "^BUILTIN"
    } | Select-Object -ExpandProperty Name } -Message 'users' )
$PhysicalDisks = Get-CommandStatus -Command { Get-PhysicalDisk | Where-Object { $_.BusType -ne 'USB' } } -Message 'disks'
$InstalledSoftware = Get-CommandStatus -Command { Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* } -Message 'software'
$HardwareReadiness = Get-CommandStatus -Command { Invoke-Expression $hardwareReadinessScript 2>&1 | Out-String | ConvertFrom-Json } -Message 'hardware readiness'

$computerName = $env:COMPUTERNAME
$date = Get-Date -Format "yyyy-MM-dd HH:mm"
$manufacturer = $ComputerInfo.CsManufacturer
$model = "$($ComputerInfo.CsSystemFamily), $($ComputerInfo.CsModel)"
$type = if ($ComputerInfo.CsPCSystemType -eq 2) { "Laptop" } else { "Desktop" }
$serialNumber = $ComputerInfo.BiosSeralNumber
$os = "$($ComputerInfo.OSName) ($((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion)) Build $($ComputerInfo.OSBuildNumber) $($ComputerInfo.OSArchitecture)"
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

$officeProducts = $InstalledSoftware | Where-Object {
  $_.DisplayName -match "Office 365|Microsoft 365"
} | Select-Object DisplayName, DisplayVersion

if ($officeProducts) {
  $office365Version = ($officeProducts | ForEach-Object {
      "$($_.DisplayName): $($_.DisplayVersion)"
    }) -join "; "
}
else {
  $office365Version = "Not installed"
}

if ($physicalDisks.Count -gt 2) {
  Write-Warning "More than 2 disks detected"
}


<# BRUTE FORCE PROTECTION #>

Write-Out "`n=== Running brute force commands ===`n" -ForegroundColor DarkYellow
net accounts /lockoutthreshold:10 /lockoutwindow:5 /lockoutduration:30 | Out-Null


<# TEAMVIEWER #>

Write-Out "`n=== Checking Teamviewer ===`n" -ForegroundColor DarkYellow

function Get-TeamViewerInfo {
  $possiblePaths = @(
    "HKLM:\SOFTWARE\TeamViewer",
    "HKLM:\SOFTWARE\Wow6432Node\TeamViewer"
  )

  $TeamViewerInfo = $null
  foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
      $TeamViewerInfo = Get-CommandStatus -Command { Get-ItemProperty -Path $path } -Message "TeamViewer info from: $path"
    }
  }
  return $TeamViewerInfo
}

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

$TeamViewerInfo = Get-TeamViewerInfo

if (-not $TeamViewerInfo) {
  Write-Error "TeamViewer not installed"
  if (Read-N "Install TeamViewer?") {
    $TeamViewerInfo = Install-TeamViewer
  }
}

$teamViewer = $TeamViewerInfo.ClientID


<# ROCKSALT USER #>

Write-Out "`n=== Checking for Rocksalt User ===`n" -ForegroundColor DarkYellow

function Add-RocksaltUser {
    if (Read-Y "Create local Rocksalt user?") {
    $password = Read-Host "Enter password" -AsSecureString
    New-LocalUser -Name "Rocksalt" -Password $password -FullName "Rocksalt" -Description "Rocksalt" | Out-Null
    Add-LocalGroupMember -Group "Administrators" -Member "Rocksalt" | Out-Null
    Write-Out "Rocksalt user created"
    return "Yes"
  }
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

  if (Read-N "Make Rocksalt admin?") {
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


<# WINDOWS 11 COMPATIBLE #>

Write-Out "`n=== Checking Windows 11 compatibility ===`n" -ForegroundColor DarkYellow

$onWin11 = $os -match "11"

if ($HardwareReadiness.returnResult -eq "CAPABLE") {
  Write-Out "Windows 11 compatible" -ForegroundColor Green
  $win11Comp = "Yes"

  if (-not $onWin11) {
    Write-Warning "Computer is Windows 11 compatible but not updated"
  }
}
else {
  Write-Error "Not Windows 11 compatible"
  $win11Comp = "No"
  Write-Error "Reason: $($HardwareReadiness.returnReason)"

  if ($onWin11) {
    Write-Warning "Windows 11 is installed but not compatible"
  }
}

<# BITLOCKER #>

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
    Write-Out "BitLocker still encrypting ($($bitlockerVolume.EncryptionPercentage)%)" -ForegroundColor Yellow
  }
  else {
    Write-Out "BitLocker is fully enabled and protected" -ForegroundColor Green
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


<# AUDITER INPUT #>

Write-Out "`n=== Audit information ===`n" -ForegroundColor DarkYellow

$auditer = $(Read-Host "RS (initials)").ToUpper()
$name = Read-Host "Name"
$gi = "GI$((Read-Host "GI") -replace '\D', '')"
if ($gi -and $gi -ne "GI" -and $gi -ne $computerName -and (Read-N "Rename computer from $computerName to ${gi}?")) {
  Rename-Computer -NewName "$gi"
  $computerName = "$gi"
}
$updates = Read-No "Updates"
$drivers = Read-No "Drivers"
$antiVirus = Read-No "Antivirus"

Write-Out "`nClient Admin:"
for ($i = 0; $i -lt $Admins.Count; $i++) {
  Write-Out " [$($i + 1)] $($Admins[$i])"
}
$clientAdmin = Read-Host "Enter number or custom"
if ($clientAdmin -as [int] -and $clientAdmin -gt 0 -and $clientAdmin -le $Admins.Count) {
  $clientAdmin = $Admins[$clientAdmin - 1]
}

Write-Out "`nUsername (Account they use):"
for ($i = 0; $i -lt $Users.Count; $i++) {
  Write-Out " [$($i + 1)] $($Users[$i])"
}
$userName = Read-Host "Enter number or custom"
if ($userName -as [int] -and $userName -gt 0 -and $userName -le $Users.Count) {
  $userName = $Users[$userName - 1]
}

Write-Out "`nChrome version: $chromeVersion`nFirefox version: $firefoxVersion`nEdge version: $edgeVersion"

$otherBrowsers = Read-Host "Other browsers"
$softwareValid = Read-No "Software valid?"
$notes = Read-Host "`nNotes"


<# OUTPUT #>

Write-Out "`n=== Output ===`n" -ForegroundColor DarkYellow

if ($warnings.Count -gt 0 -and (Read-Y "Would you like to add warnings to notes?")) {
  $notes = if ($notes) { "$notes; " } else { "" }
  $notes += "Warnings: $($warnings -join ', ')"
}

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
