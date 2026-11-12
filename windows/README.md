# Windows setup

Installs native Doom Emacs with the shared `.config/doom` files and sets Caps Lock to Escape on tap / Control on hold. No WSL or keyboard driver is needed.

## Install

Use Windows 10 or 11 on an x64 PC with [WinGet](https://learn.microsoft.com/windows/package-manager/winget/). In PowerShell:

```powershell
# If Git is not installed yet:
winget install --id Git.Git --exact --source winget --scope user
# Open a fresh PowerShell after installing Git.
git clone https://github.com/jaimielovett/dotfiles.git "$env:USERPROFILE\dotfiles"
Set-Location "$env:USERPROFILE\dotfiles"
powershell -NoProfile -ExecutionPolicy Bypass -File .\setup-windows.ps1
```

The execution-policy flag applies only to that PowerShell process. Git for Windows must include Git Bash (the standard installation does). LLVM and CMake installation may show a Windows administrator prompt if they are missing; the rest installs for the current user.

Open **Doom Emacs** in the Start menu. In a new terminal, `emacs` opens it and `doom sync` synchronizes packages after editing `init.el` or `packages.el`.

The first Doom installation can take 10-20 minutes. New Doom checkouts start at tested revision `7ccac7f643ad67baa25b216717cf8617a0903c69`; an existing Doom checkout is reused without upgrading it. Downloaded archives are pinned and checked against SHA-256 hashes; the WinGet tools use WinGet's package checksums.

## What it installs

- GNU Emacs 31.1, Doom, Git Bash launchers, and a Start menu shortcut.
- LLVM (`clangd`, `clang-format`), CMake, ripgrep with PCRE2, fd, ShellCheck, shfmt, MultiMarkdown, and Nerd Font symbols.
- [Kanata 1.12.0](https://github.com/jtroo/kanata/releases/tag/v1.12.0), using the Windows hooks build with a tray icon. It starts at sign-in.

The Doom One theme, size 16 text, Evil, Corfu/Vertico, Treemacs, Spawn syntax highlighting, and hidden Eglot inlay hints come from the shared config. Windows uses Eshell; macOS keeps vterm and its Homebrew LLVM paths. LLVM provides editor tooling; C++ projects may also need their own build toolchain and `compile_commands.json`.

Caps Lock taps under 500 ms send Escape. Holding it past 500 ms, or pressing another processed key while it is down, activates Left Control. Normal Escape stays Escape. The physical Left Control and AltGr keys are passed through for compatibility.

## Locations and reruns

| Item | Location |
| --- | --- |
| Doom core | `%USERPROFILE%\.config\emacs` |
| Doom config | `%USERPROFILE%\.config\doom` |
| Emacs and portable tools | `%LOCALAPPDATA%\Programs` |
| Terminal commands | `%USERPROFILE%\.local\bin` (added to user PATH) |
| Caps Lock config | `%USERPROFILE%\.config\kanata\kanata.kbd` |
| Caps Lock auto-start | Current user's Startup folder |
| Downloads and config backups | `%LOCALAPPDATA%\dotfiles-windows` |

Rerun the same script after pulling dotfile changes. Differing destination config files and launchers are backed up before replacement. Existing unrelated configuration files are left in place. If a target program folder contains a different version, setup stops rather than overwriting it. Existing unrelated Emacs configurations are not moved; the launchers explicitly select Doom's init directory. `HOME` and tool-specific paths are set only inside the launchers.

```powershell
.\setup-windows.ps1 -WhatIf          # Preview paths and actions without changes/downloads
.\setup-windows.ps1 -SkipCapsLock    # Only set up Doom
.\setup-windows.ps1 -SkipDoom        # Only set up Caps Lock
.\setup-windows.ps1 -SkipSync        # Copy/configure Doom without running its package sync
```

## Maintenance and removal

- Run `doom doctor` for diagnostics and `doom upgrade` when you want to update Doom and its pinned packages.
- This pinned Windows Emacs distribution may report native compilation unavailable. Byte compilation works. Fontconfig detection and Bash's `.exe` name can also produce doctor warnings on Windows even when fonts, shell commands, and search work.
- To temporarily disable the remapping, quit Kanata from its tray menu. The physical **Left Control + Space + Escape** combination also exits Kanata.
- To stop auto-start, remove **Caps Lock - Escape and Control.lnk** from your user's Startup folder. To re-enable it, rerun setup.
- The hook-based remapper runs with your user privileges; administrator applications and some games may not accept the remapped keys. This setup does not install a driver or elevate the remapper.

To change the timing, edit both `500` values in `.config/kanata/kanata.kbd`, rerun setup, and reload its configuration from Kanata's tray menu (or quit and rerun setup). Keep the edited config in this repo so the next Windows machine gets it too.
