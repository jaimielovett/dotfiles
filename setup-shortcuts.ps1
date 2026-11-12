#Requires -Version 5.1
<#
.SYNOPSIS
Install the Windows app shortcuts and enable them at sign-in.
.EXAMPLE
powershell -NoProfile -ExecutionPolicy Bypass -File .\setup-shortcuts.ps1
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param()

$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT' -or ![Environment]::Is64BitOperatingSystem -or
    $env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64') {
    throw 'This installer supports Windows x64.'
}

$localDir = [Environment]::GetFolderPath('LocalApplicationData')
$sourceScript = Join-Path $PSScriptRoot 'windows\app-shortcuts.ahk'
# Reuse the original installation paths so existing sign-in entries do not duplicate it.
$installDir = Join-Path $localDir 'Programs\ChromeSwitcher'
$runtimeDir = Join-Path $installDir 'AutoHotkey'
$runtime = Join-Path $runtimeDir 'AutoHotkey64.exe'
$installedScript = Join-Path $installDir 'Chrome.ahk'
$startupLink = Join-Path ([Environment]::GetFolderPath('Startup')) 'Chrome Switcher.lnk'
$cacheDir = Join-Path $localDir 'dotfiles-windows\downloads'
$backupDir = Join-Path $localDir ('dotfiles-windows\backups\shortcuts-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))

if (!(Test-Path -LiteralPath $sourceScript -PathType Leaf)) { throw "Missing $sourceScript" }
if (!$PSCmdlet.ShouldProcess($installDir, 'Install app shortcuts, enable at sign-in, and start')) { return }

function Backup-ShortcutFile {
    param([string] $Path)
    if (Test-Path -LiteralPath $Path) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        Copy-Item -LiteralPath $Path -Destination (Join-Path $backupDir ([IO.Path]::GetFileName($Path)))
    }
}

if (Test-Path -LiteralPath $runtime) {
    if ((Get-Item -LiteralPath $runtime).VersionInfo.FileVersion -ne '2.0.31') {
        throw "Existing $runtime is not the expected AutoHotkey 2.0.31. Leaving it untouched."
    }
} else {
    if ((Test-Path -LiteralPath $runtimeDir) -and @(Get-ChildItem -LiteralPath $runtimeDir -Force).Count -gt 0) {
        throw "Existing $runtimeDir is incomplete. Move it aside before rerunning."
    }
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
    $archive = Join-Path $cacheDir 'AutoHotkey_2.0.31.zip'
    $sha256 = 'CA1A595ACA4528755D8D4CD7FED23D497A37BD9A0B6892072612D68DEE1BD00A'
    if (!(Test-Path -LiteralPath $archive) -or (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $sha256) {
        Invoke-WebRequest -Uri 'https://github.com/AutoHotkey/AutoHotkey/releases/download/v2.0.31/AutoHotkey_2.0.31.zip' `
            -OutFile $archive -UseBasicParsing
    }
    if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $sha256) {
        throw 'AutoHotkey archive SHA-256 mismatch. Setup stopped.'
    }
    Expand-Archive -LiteralPath $archive -DestinationPath $runtimeDir -Force
}

# Validate without running the source script or replacing the active instance.
$validation = Start-Process -FilePath $runtime -ArgumentList @('/ErrorStdOut', '/Validate', ('"' + $sourceScript + '"')) `
    -WindowStyle Hidden -Wait -PassThru
if ($validation.ExitCode -ne 0) { throw 'AutoHotkey script validation failed.' }
if (!(Test-Path -LiteralPath $installedScript) -or
    (Get-FileHash -LiteralPath $sourceScript).Hash -ne (Get-FileHash -LiteralPath $installedScript).Hash) {
    Backup-ShortcutFile $installedScript
    Copy-Item -LiteralPath $sourceScript -Destination $installedScript -Force
}

$shortcutShell = New-Object -ComObject WScript.Shell
$shortcut = $shortcutShell.CreateShortcut($startupLink)
$arguments = '"' + $installedScript + '"'
if ((Test-Path -LiteralPath $startupLink) -and
    ($shortcut.TargetPath -ne $runtime -or $shortcut.Arguments -ne $arguments)) {
    Backup-ShortcutFile $startupLink
}
$shortcut.TargetPath = $runtime
$shortcut.Arguments = $arguments
$shortcut.WorkingDirectory = $installDir
$shortcut.WindowStyle = 7
$shortcut.Description = 'Shift + Alt + C/V/X/E toggles Chrome, VS Code, JaimieOS, or Emacs and returns to your previous window.'
$shortcut.Save()

$process = Start-Process -FilePath $runtime -ArgumentList @('/restart', '/ErrorStdOut', $arguments) `
    -WorkingDirectory $installDir -WindowStyle Hidden -PassThru
Start-Sleep -Milliseconds 750
$process.Refresh()
if ($process.HasExited) { throw "App shortcuts exited with code $($process.ExitCode)." }
Write-Host 'App shortcuts are running and will start at sign-in: Shift + Alt + C/V/X/E.'
Write-Host 'Shortcut reference: windows/SHORTCUTS.md'
