function Invoke-Checked {
    param([string] $File, [string[]] $Arguments)
    & $File @Arguments | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "$File failed with exit code $LASTEXITCODE" }
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
