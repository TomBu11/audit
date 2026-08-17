# Rocksalt Windows Audit Script

A PowerShell-based auditing tool for Rocksalt staff that performs a comprehensive audit of Windows systems, collecting system configuration, installed software, security settings, and other relevant information.

## Features

* Collects system information, including:

  * Windows version
  * Hardware details
  * TeamViewer ID
  * Windows 11 compatibility
* Lists installed software and their versions.
* Configures Windows account lockout settings.
* Checks for TeamViewer and optionally installs it.
* Checks for the required Rocksalt user account and administrator privileges.
* Creates a Rocksalt user when required.
* Outputs audit information in both machine-readable and human-readable formats.
* Performs BitLocker checks and outputs the results separately.

## Usage

### Option 1: Run the Executable

For standard use, download the latest `audit.exe` and run it.

The latest release is available on GitHub:

https://github.com/TomBu11/audit/releases

The executable is also available on the Rocksalt Google Drive:

```text
G:\Shared drives\Rocksalt Internal\Audit Script\v1.1.8\audit.exe
```

When prompted for administrator privileges, select **Yes** or provide administrator credentials.

### Option 2: Run the PowerShell Script

1. Open PowerShell with **administrative privileges**.
2. Navigate to the directory containing the script.
3. Run the script:

```powershell
.\audit_XXX.ps1
```

## Audit Process

When the audit starts, it will perform several checks and configuration tasks.

### System Information

The script collects relevant system information, including hardware and operating system details.

> **Note:** PowerShell can occasionally pause during this stage due to a Windows/PowerShell quirk. If execution appears to have stopped, focus the PowerShell window and press **Enter** to continue.

### Account Lockout Settings

The script configures the following account lockout settings:

```text
Lockout threshold: 10 attempts
Lockout window:    5 minutes
Lockout duration:  30 minutes
```

These correspond to:

```cmd
net accounts /lockoutthreshold:10
net accounts /lockoutwindow:5
net accounts /lockoutduration:30
```

### TeamViewer

The script checks whether TeamViewer is installed.

If TeamViewer is not detected, you will be asked whether you want the script to install it automatically.

### Rocksalt User

The script checks whether a Rocksalt user account exists and whether it has administrator privileges.

If the required account is not present, the script will ask whether you want to create it.

### Windows 11 Compatibility

The script checks whether the device meets the requirements for Windows 11.

If the device is not compatible, the script will report the reason.

## User Input

After the initial checks, the script will prompt for additional information.

All fields can be left blank. Where applicable, the capitalised option is the default. For example:

```text
y/N
```

means **No** is the default.

### Client Admin and Username

When entering the **Client Admin** and **Username**, the script displays the existing administrator and standard user accounts.

You can either:

* Enter the number corresponding to an account in the list.
* Enter a custom value.

## Output Files

The script writes its output to both:

* The directory from which the script was run.
* `C:\Rocksalt`

### Audit Output

The tab-separated audit data is appended to:

```text
audit.txt
```

This format is intended for copying and pasting into the standardised audit sheet.

### BitLocker Output

BitLocker information is written to a file named using the GI and username, for example:

```text
bitlocker_<GI>_<username>.txt
```

### Human-Readable Audit

The software list and table-formatted audit are saved to:

```text
AuditHR.txt
```

## Building

The PowerShell scripts are built using **GPP** and the repository's `Makefile`.

The executable is compiled using **PS2EXE**.

Example:

```powershell
Invoke-PS2EXE `
    -InputFile .\build\script\audit_NORMAL.ps1 `
    -OutputFile .\build\exe\audit.exe `
    -requireAdmin `
    -version ""
```

## Requirements

* Windows
* PowerShell
* Administrator privileges
* PS2EXE (for building the executable)

## Repository

The latest releases and source code are available on GitHub:

https://github.com/TomBu11/audit/releases
