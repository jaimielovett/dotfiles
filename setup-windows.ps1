#Requires -Version 5.1
<#
.SYNOPSIS
Install native Doom Emacs and Caps Lock Escape/Control on Windows x64.
.EXAMPLE
powershell -NoProfile -ExecutionPolicy Bypass -File .\setup-windows.ps1
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch] $SkipDoom,
    [switch] $SkipCapsLock,
    [switch] $SkipSync
)

$ErrorActionPreference = 'Stop'
$repoDir = $PSScriptRoot
$profileDir = [Environment]::GetFolderPath('UserProfile')
$localDir = [Environment]::GetFolderPath('LocalApplicationData')
$configDir = Join-Path $profileDir '.config'
$programsDir = Join-Path $localDir 'Programs'
$commandDir = Join-Path $profileDir '.local\bin'
$cacheDir = Join-Path $localDir 'dotfiles-windows\downloads'
$backupDir = Join-Path $localDir ('dotfiles-windows\backups\' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))

function Invoke-Checked {
    param([string] $File, [string[]] $Arguments)
    & $File @Arguments | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "$File failed with exit code $LASTEXITCODE" }
}

function Get-VerifiedArchive {
    param([string] $Name, [string] $Url, [string] $Sha256)
    New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
    $archivePath = Join-Path $cacheDir $Name
    if (!(Test-Path -LiteralPath $archivePath) -or
        (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash -ne $Sha256) {
        Write-Host "Downloading $Name..."
        Invoke-WebRequest -Uri $Url -OutFile $archivePath -UseBasicParsing
    }
    if ((Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash -ne $Sha256) {
        throw "SHA-256 mismatch for $Name. Setup stopped."
    }
    return $archivePath
}

function Expand-Tool {
    param([string] $Archive, [string] $Destination, [string] $Subdirectory = '')
    if ((Test-Path -LiteralPath $Destination) -and
        @(Get-ChildItem -LiteralPath $Destination -Force).Count -gt 0) {
        throw "Existing $Destination is not the expected version. Move it aside before rerunning."
    }
    $stagingDir = Join-Path $cacheDir ('unpack-' + [Guid]::NewGuid().ToString('N'))
    try {
        Expand-Archive -LiteralPath $Archive -DestinationPath $stagingDir
        $sourceDir = if ($Subdirectory) { Join-Path $stagingDir $Subdirectory } else { $stagingDir }
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
        Get-ChildItem -LiteralPath $sourceDir -Force | Copy-Item -Destination $Destination -Recurse
    }
    finally {
        # Only remove the unique extraction directory beneath our download cache.
        $resolvedStaging = [IO.Path]::GetFullPath($stagingDir)
        $resolvedCache = [IO.Path]::GetFullPath($cacheDir).TrimEnd('\') + '\'
        if (!$resolvedStaging.StartsWith($resolvedCache, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing cleanup outside $resolvedCache"
        }
        if (Test-Path -LiteralPath $resolvedStaging) { Remove-Item -LiteralPath $resolvedStaging -Recurse -Force }
    }
}

function Test-ToolVersion {
    param([string] $Executable, [string] $Pattern)
    if (!(Test-Path -LiteralPath $Executable)) { return $false }
    $versionText = & $Executable --version 2>&1 | Out-String
    return ($LASTEXITCODE -eq 0 -and $versionText -match $Pattern)
}

function Backup-File {
    param([string] $Path)
    if (Test-Path -LiteralPath $Path) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        $backupPath = Join-Path $backupDir ([Guid]::NewGuid().ToString('N') + '-' + [IO.Path]::GetFileName($Path))
        Copy-Item -LiteralPath $Path -Destination $backupPath
        Write-Host "Backed up $Path to $backupPath"
    }
}

function Copy-ConfigFile {
    param([string] $Source, [string] $Destination)
    if ([IO.Path]::GetFullPath($Source) -eq [IO.Path]::GetFullPath($Destination)) { return }
    if ((Test-Path -LiteralPath $Destination) -and
        (Get-FileHash -LiteralPath $Source).Hash -eq (Get-FileHash -LiteralPath $Destination).Hash) { return }
    Backup-File $Destination
    New-Item -ItemType Directory -Path (Split-Path $Destination) -Force | Out-Null
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
}

function Write-Launcher {
    param([string] $Template, [string] $Destination, [hashtable] $Values)
    $content = [IO.File]::ReadAllText($Template)
    foreach ($key in $Values.Keys) { $content = $content.Replace("@$key@", $Values[$key]) }
    if ($content -match '@[A-Z_]+@') { throw "Unresolved launcher placeholder in $Template" }
    $content = ($content -replace '\r?\n', "`r`n")
    if ((Test-Path -LiteralPath $Destination) -and [IO.File]::ReadAllText($Destination) -ceq $content) { return }
    Backup-File $Destination
    New-Item -ItemType Directory -Path (Split-Path $Destination) -Force | Out-Null
    [IO.File]::WriteAllText($Destination, $content, (New-Object Text.UTF8Encoding($false)))
}

function Refresh-ProcessPath {
    $env:Path = (@(
        (Join-Path $localDir 'Microsoft\WinGet\Links'),
        [Environment]::GetEnvironmentVariable('Path', 'Machine'),
        [Environment]::GetEnvironmentVariable('Path', 'User'),
        $env:Path
    ) | Where-Object { $_ }) -join ';'
}

function Ensure-Command {
    param([string] $Command, [string] $Package, [string] $KnownPath = '', [switch] $UserScope)
    if ($KnownPath -and (Test-Path -LiteralPath $KnownPath)) { return }
    # Do not mistake a tool bundled privately with Codex for a normal installation.
    $installed = Get-Command $Command -CommandType Application -ErrorAction SilentlyContinue |
        Where-Object { $_.Source -notmatch '\\(\.cache\\codex|\.codex\\|OpenAI\\Codex\\)' } |
        Select-Object -First 1
    if ($installed) { return }
    $installArgs = @('install', '--id', $Package, '--exact', '--source', 'winget', '--silent',
        '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity')
    if ($UserScope) { $installArgs += @('--scope', 'user') }
    Invoke-Checked 'winget.exe' $installArgs
    Refresh-ProcessPath
    if (!($KnownPath -and (Test-Path -LiteralPath $KnownPath)) -and
        !(Get-Command $Command -CommandType Application -ErrorAction SilentlyContinue)) {
        throw "$Package installed but $Command was not found. Open a fresh PowerShell and rerun."
    }
}

function New-Shortcut {
    param([string] $Path, [string] $Target, [string] $Arguments, [string] $WorkingDirectory, [string] $Icon = '')
    $shortcutShell = New-Object -ComObject WScript.Shell
    $shortcut = $shortcutShell.CreateShortcut($Path)
    if ((Test-Path -LiteralPath $Path) -and
        ($shortcut.TargetPath -ne $Target -or $shortcut.Arguments -ne $Arguments)) { Backup-File $Path }
    $shortcut.TargetPath = $Target
    $shortcut.Arguments = $Arguments
    $shortcut.WorkingDirectory = $WorkingDirectory
    if ($Icon) { $shortcut.IconLocation = $Icon }
    $shortcut.Save()
}

if ($env:OS -ne 'Windows_NT' -or ![Environment]::Is64BitOperatingSystem -or
    $env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64') {
    throw 'This installer supports Windows x64. See windows/README.md.'
}
if ($SkipDoom -and $SkipCapsLock) { throw 'Both components were skipped; nothing to install.' }
$requiredFiles = @()
if (!$SkipDoom) {
    $requiredFiles += @('.config\doom\init.el', '.config\doom\config.el', '.config\doom\packages.el',
        '.config\doom\lisp\spawn-mode.el', '.config\doom\assets\spawn-icon.png',
        'windows\doom.cmd.in', 'windows\emacs.cmd.in', 'windows\launch-doom.vbs.in')
}
if (!$SkipCapsLock) { $requiredFiles += '.config\kanata\kanata.kbd' }
foreach ($relativePath in $requiredFiles) {
    if (!(Test-Path -LiteralPath (Join-Path $repoDir $relativePath) -PathType Leaf)) {
        throw "Missing repository file: $relativePath"
    }
}
Write-Host "User config: $configDir"
Write-Host "Programs: $programsDir"
Write-Host "Commands: $commandDir"
if (!$PSCmdlet.ShouldProcess($profileDir, 'Set up native Doom Emacs and/or Caps Lock Escape/Control')) { return }
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

if (!$SkipDoom) {
    foreach ($prerequisite in @('git.exe', 'winget.exe')) {
        if (!(Get-Command $prerequisite -CommandType Application -ErrorAction SilentlyContinue)) {
            throw "Install $prerequisite first; see windows/README.md."
        }
    }
    $gitCommand = (Get-Command git.exe -CommandType Application | Select-Object -First 1).Source
    $gitRoots = @((Split-Path (Split-Path $gitCommand)), (Join-Path $env:ProgramFiles 'Git'),
        (Join-Path $programsDir 'Git'))
    $gitRoot = $gitRoots | Where-Object {
        (Test-Path -LiteralPath (Join-Path $_ 'bin\bash.exe')) -and
        (Test-Path -LiteralPath (Join-Path $_ 'usr\bin\find.exe'))
    } | Select-Object -First 1
    if (!$gitRoot) { throw 'Git Bash and GNU find were not found. Install standard Git for Windows.' }
    $doomCore = Join-Path $configDir 'emacs'
    if ((Test-Path -LiteralPath $doomCore) -and
        !(Test-Path -LiteralPath (Join-Path $doomCore 'bin\doom'))) {
        throw "$doomCore already exists and is not a Doom installation. Leaving it untouched."
    }

    Refresh-ProcessPath
    Ensure-Command 'rg.exe' 'BurntSushi.ripgrep.MSVC' -UserScope
    Ensure-Command 'fd.exe' 'sharkdp.fd' -UserScope
    Ensure-Command 'shellcheck.exe' 'koalaman.shellcheck' -UserScope
    Ensure-Command 'shfmt.exe' 'mvdan.shfmt' -UserScope
    Ensure-Command 'cmake.exe' 'Kitware.CMake' (Join-Path $env:ProgramFiles 'CMake\bin\cmake.exe')
    Ensure-Command 'clangd.exe' 'LLVM.LLVM' (Join-Path $env:ProgramFiles 'LLVM\bin\clangd.exe')
    Refresh-ProcessPath
    $clangd = Get-Command clangd.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    $llvmBin = if ($clangd) { Split-Path $clangd.Source } else { Join-Path $env:ProgramFiles 'LLVM\bin' }
    $cmake = Get-Command cmake.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    $cmakeBin = if ($cmake) { Split-Path $cmake.Source } else { Join-Path $env:ProgramFiles 'CMake\bin' }
    if (!(Test-Path -LiteralPath (Join-Path $llvmBin 'clang-format.exe'))) { throw "clang-format missing in $llvmBin" }

    $emacsDir = Join-Path $programsDir 'Emacs'
    if (!(Test-ToolVersion (Join-Path $emacsDir 'bin\emacs.exe') '^GNU Emacs 31\.1\b')) {
        $archive = Get-VerifiedArchive 'emacs-31.1-UCRT64.zip' `
            'https://ftp.gnu.org/gnu/emacs/windows/emacs-31/emacs-31.1-UCRT64.zip' `
            'FC728CA343E1B228A8BAAB39854F5E3FB657059F1917928F054E74E364BF6D79'
        Expand-Tool $archive $emacsDir
    }
    $markdownDir = Join-Path $programsDir 'MultiMarkdown'
    if (!(Test-ToolVersion (Join-Path $markdownDir 'bin\multimarkdown.exe') 'MultiMarkdown 6 v6\.7\.0\b')) {
        $archive = Get-VerifiedArchive 'multimarkdown-6.7.0.zip' `
            'https://github.com/fletcher/MultiMarkdown-6/releases/download/6.7.0/MultiMarkdown-Windows-6.7.0.zip' `
            '12163D418A7475032DF435FA5EBB4E48D9C99F78E0AA130093B0344CA7C0CF8B'
        Expand-Tool $archive $markdownDir 'MultiMarkdown-Windows-6.7.0'
    }

    $fontDir = Join-Path $localDir 'Microsoft\Windows\Fonts'
    $fontRegistry = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
    $fontNames = @('SymbolsNerdFont-Regular.ttf', 'SymbolsNerdFontMono-Regular.ttf')
    if (@($fontNames | Where-Object { !(Test-Path -LiteralPath (Join-Path $fontDir $_)) }).Count -gt 0) {
        $archive = Get-VerifiedArchive 'nerd-font-symbols-3.5.1.zip' `
            'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/NerdFontsSymbolsOnly.zip' `
            'FDCA3682534F6F65E1CCB2345B0362CCF67D9B8ECA7C8025330946E93E2473BC'
        $fontExtractDir = Join-Path $cacheDir 'nerd-font-symbols-3.5.1'
        if (!(Test-Path -LiteralPath $fontExtractDir)) { Expand-Archive -LiteralPath $archive -DestinationPath $fontExtractDir }
        New-Item -ItemType Directory -Path $fontDir -Force | Out-Null
        foreach ($fontName in $fontNames) { Copy-ConfigFile (Join-Path $fontExtractDir $fontName) (Join-Path $fontDir $fontName) }
    }
    if (!(Test-Path $fontRegistry)) { New-Item -Path $fontRegistry -Force | Out-Null }
    if (!('Dotfiles.Fonts' -as [type])) {
        Add-Type 'using System; using System.Runtime.InteropServices; namespace Dotfiles { public class Fonts { [DllImport("gdi32.dll", CharSet=CharSet.Unicode)] public static extern int AddFontResourceEx(string file, uint flags, IntPtr reserved); } }'
    }
    foreach ($fontName in $fontNames) {
        $fontPath = Join-Path $fontDir $fontName
        New-ItemProperty -Path $fontRegistry -Name ($fontName.Replace('.ttf', '') + ' (TrueType)') -Value $fontPath -PropertyType String -Force | Out-Null
        [Dotfiles.Fonts]::AddFontResourceEx($fontPath, 0, [IntPtr]::Zero) | Out-Null
    }

    if (!(Test-Path -LiteralPath $doomCore)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        Invoke-Checked 'git.exe' @('-c', 'core.autocrlf=false', 'clone', '--depth', '1', 'https://github.com/doomemacs/core.git', $doomCore)
        # Start new machines from the Doom revision tested with this config.
        $doomRevision = '7ccac7f643ad67baa25b216717cf8617a0903c69'
        Invoke-Checked 'git.exe' @('-C', $doomCore, 'fetch', '--depth', '1', 'origin', $doomRevision)
        Invoke-Checked 'git.exe' @('-C', $doomCore, 'checkout', '-B', 'master', $doomRevision)
    }
    foreach ($relativePath in $requiredFiles | Where-Object { $_ -like '.config\doom\*' }) {
        Copy-ConfigFile (Join-Path $repoDir $relativePath) (Join-Path $profileDir $relativePath)
    }
    $values = @{
        GIT_BASH = Join-Path $gitRoot 'bin\bash.exe'
        GIT_BIN = Join-Path $gitRoot 'bin'
        GIT_USR_BIN = Join-Path $gitRoot 'usr\bin'
        LLVM_BIN = $llvmBin
        CMAKE_BIN = $cmakeBin
    }
    Write-Launcher (Join-Path $repoDir 'windows\doom.cmd.in') (Join-Path $commandDir 'doom.cmd') $values
    Write-Launcher (Join-Path $repoDir 'windows\emacs.cmd.in') (Join-Path $commandDir 'emacs.cmd') $values
    $guiLauncher = Join-Path $configDir 'doom\windows\launch-doom.vbs'
    Write-Launcher (Join-Path $repoDir 'windows\launch-doom.vbs.in') $guiLauncher $values
    $userPath = [string] [Environment]::GetEnvironmentVariable('Path', 'User')
    if (@($userPath -split ';' | Where-Object { $_.TrimEnd('\') -eq $commandDir }).Count -eq 0) {
        [Environment]::SetEnvironmentVariable('Path', ($userPath.TrimEnd(';') + ';' + $commandDir).TrimStart(';'), 'User')
    }
    New-Shortcut (Join-Path ([Environment]::GetFolderPath('Programs')) 'Doom Emacs.lnk') `
        (Join-Path $env:SystemRoot 'System32\wscript.exe') ('"' + $guiLauncher + '"') $profileDir `
        ((Join-Path $emacsDir 'bin\runemacs.exe') + ',0')
    if (!$SkipSync) {
        Invoke-Checked (Join-Path $commandDir 'doom.cmd') @('install', '--force', '--no-config', '--no-env')
        Invoke-Checked (Join-Path $commandDir 'doom.cmd') @('doctor')
    }
}

if (!$SkipCapsLock) {
    $kanataDir = Join-Path $programsDir 'Kanata'
    $kanataCli = Join-Path $kanataDir 'kanata-cli.exe'
    $kanataGui = Join-Path $kanataDir 'kanata.exe'
    if (!(Test-ToolVersion $kanataCli '^kanata 1\.12\.0\b') -or !(Test-Path -LiteralPath $kanataGui)) {
        $archive = Get-VerifiedArchive 'kanata-1.12.0-windows-x64.zip' `
            'https://github.com/jtroo/kanata/releases/download/v1.12.0/windows-binaries-x64.zip' `
            '13947ED78CFA3284BFEF854E3C542C74AB366236B72FD9F7E039F8638DEEAD9D'
        $kanataExtractDir = Join-Path $cacheDir 'kanata-1.12.0'
        if (!(Test-Path -LiteralPath $kanataExtractDir)) { Expand-Archive -LiteralPath $archive -DestinationPath $kanataExtractDir }
        if ((Test-Path -LiteralPath $kanataDir) -and @(Get-ChildItem -LiteralPath $kanataDir -Force).Count -gt 0) {
            throw "Existing $kanataDir is not the expected version. Move it aside before rerunning."
        }
        New-Item -ItemType Directory -Path $kanataDir -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $kanataExtractDir 'kanata_windows_tty_winIOv2_x64.exe') -Destination $kanataCli
        Copy-Item -LiteralPath (Join-Path $kanataExtractDir 'kanata_windows_gui_winIOv2_x64.exe') -Destination $kanataGui
    }
    # Validate the new config before replacing the active one.
    Invoke-Checked $kanataCli @('--cfg', (Join-Path $repoDir '.config\kanata\kanata.kbd'), '--check', '--no-wait')
    $kanataConfig = Join-Path $configDir 'kanata\kanata.kbd'
    Copy-ConfigFile (Join-Path $repoDir '.config\kanata\kanata.kbd') $kanataConfig
    New-Shortcut (Join-Path ([Environment]::GetFolderPath('Startup')) 'Caps Lock - Escape and Control.lnk') `
        $kanataGui ('--cfg "' + $kanataConfig + '" --no-wait') (Split-Path $kanataConfig)
    $running = @(Get-CimInstance Win32_Process -Filter "Name = 'kanata.exe'" | Where-Object { $_.ExecutablePath -eq $kanataGui })
    if ($running.Count -eq 0) {
        Start-Process -FilePath $kanataGui -ArgumentList ('--cfg "' + $kanataConfig + '" --no-wait') `
            -WorkingDirectory (Split-Path $kanataConfig) -WindowStyle Hidden
    }
    else { Write-Host 'Kanata is already running. Reload its config from the tray, or quit and rerun setup.' }
}

Write-Host 'Windows setup complete. Config changes were backed up when needed.'
if (!$SkipDoom) { Write-Host 'Open Doom Emacs from Start, or use emacs/doom in a new terminal.' }
if (!$SkipCapsLock) { Write-Host 'Caps Lock: Escape on tap, Control on hold.' }
