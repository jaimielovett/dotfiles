#Requires -Version 5.1
[CmdletBinding(SupportsShouldProcess = $true)]
param()

$ErrorActionPreference = 'Stop'
$localDir = [Environment]::GetFolderPath('LocalApplicationData')
$toolsDir = Join-Path $localDir 'dotfiles-windows'
$binDir = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.local\bin'
$nvimSource = Join-Path $PSScriptRoot '.config\nvim'
. (Join-Path $PSScriptRoot 'windows\winget.ps1')

function Add-UserBin([string] $Directory) {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($Directory -notin ($env:Path -split ';')) {
        [Environment]::SetEnvironmentVariable('Path', ("$Directory;$userPath").TrimEnd(';'), 'User')
        Refresh-ProcessPath
    }
}

function Install-PackageId([string] $Id, [string[]] $ExtraArgs = @()) {
    Invoke-Checked winget.exe (@('install', '--exact', '--id', $Id, '--source', 'winget', '--silent',
        '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity') + $ExtraArgs)
    Refresh-ProcessPath
}

if ($env:OS -ne 'Windows_NT' -or $env:PROCESSOR_ARCHITECTURE -ne 'AMD64') {
    throw 'Run this installer from 64-bit PowerShell on Windows x64.'
}
if (!$PSCmdlet.ShouldProcess($PSScriptRoot, 'Install Neovim, its tools and Windows Terminal, link the config and add the vim command')) { return }
if (!(Test-Path -LiteralPath (Join-Path $nvimSource 'init.lua'))) { throw "Missing Neovim config in $nvimSource" }
# Use the PATH that a new Windows terminal will inherit.
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
foreach ($tool in @(
    @('git.exe', 'Git.Git'), @('nvim.exe', 'Neovim.Neovim'), @('wt.exe', 'Microsoft.WindowsTerminal'),
    @('node.exe', 'OpenJS.NodeJS.LTS'), @('rg.exe', 'BurntSushi.ripgrep.MSVC'), @('fd.exe', 'sharkdp.fd'),
    @('tree-sitter.exe', 'tree-sitter.tree-sitter-cli'), @('lazygit.exe', 'JesseDuffield.lazygit'),
    @('fzf.exe', 'junegunn.fzf'), @('codex.exe', 'OpenAI.Codex')
)) {
    Ensure-Command $tool[0] $tool[1]
}
foreach ($tool in @(@('clangd.exe', 'LLVM.LLVM', 'LLVM\bin'), @('love.exe', 'Love2d.Love2d', 'LOVE'))) {
    $directory = Join-Path $env:ProgramFiles $tool[2]
    Ensure-Command $tool[0] $tool[1] (Join-Path $directory $tool[0])
    if (!(Get-Command $tool[0] -ErrorAction SilentlyContinue)) { Add-UserBin $directory }
}
foreach ($tool in @('clang.exe', 'clang-format.exe', 'npm.cmd', 'tar.exe', 'curl.exe')) {
    Get-Command $tool -CommandType Application -ErrorAction Stop | Out-Null
}
$version = & nvim.exe --version | Select-Object -First 1
if ($version -notmatch 'NVIM v(\d+\.\d+\.\d+)' -or [version]$Matches[1] -lt [version]'0.12.0') {
    throw 'The pinned plugins need Neovim 0.12+. Upgrade Neovim and rerun.'
}
if ((& tree-sitter.exe --version) -notmatch 'tree-sitter (\d+\.\d+\.\d+)' -or [version]$Matches[1] -lt [version]'0.26.1') {
    throw 'Upgrade the Tree-sitter CLI to 0.26.1 or later and rerun.'
}

$vsInstaller = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer'
$vswhere = Join-Path $vsInstaller 'vswhere.exe'
$component = 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64'
if (!(Test-Path $vswhere) -or !(& $vswhere -products '*' -requires $component -property installationPath)) {
    $workload = 'Microsoft.VisualStudio.Workload.VCTools'
    $buildTools = if (Test-Path $vswhere) {
        & $vswhere -latest -products Microsoft.VisualStudio.Product.BuildTools -property installationPath
    }
    if ($buildTools) {
        $result = Start-Process (Join-Path $vsInstaller 'setup.exe') -Verb RunAs -Wait -PassThru -WindowStyle Hidden -ArgumentList (
            "modify --installPath `"$buildTools`" --add $workload --includeRecommended --passive --norestart")
        if ($result.ExitCode -notin @(0, 3010)) { throw "C++ workload installation failed ($($result.ExitCode))." }
    } else {
        Install-PackageId 'Microsoft.VisualStudio.2022.BuildTools' @('--override', "--wait --passive --norestart --add $workload --includeRecommended")
    }
}
if (!(& $vswhere -products '*' -requires $component -property installationPath)) { throw 'The Visual C++ build tools are missing.' }

$font = 'JetBrainsMonoNerdFont-Regular.ttf'
if (!(Test-Path (Join-Path $env:WINDIR "Fonts\$font")) -and !(Test-Path (Join-Path $localDir "Microsoft\Windows\Fonts\$font"))) {
    Install-PackageId 'DEVCOM.JetBrainsMonoNerdFont'
}

$configPath = & nvim.exe --clean --headless "+lua io.write(vim.fn.stdpath('config'))" +qa
if ($LASTEXITCODE -ne 0 -or !$configPath) { throw 'Could not locate the Neovim config directory.' }
$existing = Get-Item -LiteralPath $configPath -Force -ErrorAction SilentlyContinue
if ($existing -and $existing.FullName -ne $nvimSource -and @($existing.Target) -notcontains $nvimSource) {
    throw "Existing Neovim config at $configPath. Move it aside to keep a backup, then rerun."
}
if (!$existing) {
    New-Item -ItemType Directory -Path (Split-Path $configPath) -Force | Out-Null
    New-Item -ItemType Junction -Path $configPath -Target $nvimSource | Out-Null
}

New-Item -ItemType Directory -Path $binDir -Force | Out-Null
$vimShim = Join-Path $binDir 'vim.cmd'
$shimSource = Join-Path $PSScriptRoot 'windows\vim.cmd'
if (!(Test-Path -LiteralPath $vimShim)) {
    Copy-Item -LiteralPath $shimSource -Destination $vimShim
} elseif ([IO.File]::ReadAllText($vimShim).TrimEnd() -cne [IO.File]::ReadAllText($shimSource).TrimEnd()) {
    throw "An existing $vimShim differs from the repo launcher. Move it aside and rerun."
}
Add-UserBin $binDir
if ((Get-Command vim -ErrorAction Stop).Source -ne $vimShim) { Write-Warning "Another vim command precedes $vimShim on PATH." }

# Microsoft's JSONC editor retains profile settings, comments and trailing commas.
$parser = Join-Path $toolsDir 'node_modules\jsonc-parser'
if (!(Test-Path "$parser\package.json") -or (Get-Content "$parser\package.json" -Raw | ConvertFrom-Json).version -ne '3.3.1') {
    Invoke-Checked npm.cmd @('install', '--prefix', $toolsDir, '--no-save', '--no-package-lock',
        '--ignore-scripts', '--no-audit', '--no-fund', 'jsonc-parser@3.3.1')
}
$settingsFile = Join-Path $localDir 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
Invoke-Checked node.exe @((Join-Path $PSScriptRoot 'windows\terminal-theme.cjs'), (Join-Path $PSScriptRoot '.config\ghostty'), $settingsFile, $parser)

# First-time Lazy installs can rewrite their lockfile while discovering extras.
# Stage the config so the tracked lock stays intact while plugins install into the real data directory.
$stage = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-nvim-' + [guid]::NewGuid().ToString('N'))
$oldConfigHome = $env:XDG_CONFIG_HOME
$oldLock = $env:DOTFILES_NVIM_LOCK
$oldBootstrap = $env:DOTFILES_NVIM_BOOTSTRAP
try {
    New-Item -ItemType Directory -Path $stage | Out-Null
    $env:XDG_CONFIG_HOME = $stage
    $appName = if ($env:NVIM_APPNAME) { $env:NVIM_APPNAME } else { 'nvim' }
    if ($appName -notmatch '^[\w.-]+$' -or $appName -in @('.', '..')) { throw 'Unsupported NVIM_APPNAME for Windows setup.' }
    Copy-Item -LiteralPath $nvimSource -Destination (Join-Path $stage $appName) -Recurse
    $env:DOTFILES_NVIM_LOCK = Join-Path $nvimSource 'lazy-lock.json'
    $env:DOTFILES_NVIM_BOOTSTRAP = Join-Path $PSScriptRoot 'windows\bootstrap-nvim.lua'
    Invoke-Checked nvim.exe @('--headless', '-i', 'NONE', '-n', '-c', 'lua dofile(vim.env.DOTFILES_NVIM_BOOTSTRAP)')
} finally {
    $env:XDG_CONFIG_HOME = $oldConfigHome
    $env:DOTFILES_NVIM_LOCK = $oldLock
    $env:DOTFILES_NVIM_BOOTSTRAP = $oldBootstrap
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')
    if ((Test-Path -LiteralPath $stage) -and (Split-Path (Resolve-Path -LiteralPath $stage).Path) -eq $tempRoot -and
        (Split-Path $stage -Leaf) -match '^dotfiles-nvim-[0-9a-f]{32}$') {
        Remove-Item -LiteralPath $stage -Recurse -Force
    }
}
Write-Host 'Open a new Windows Terminal and type vim or nvim.'
