# Windows setup

Installs native Doom Emacs using the repo's `.config/doom` files directly and sets Caps Lock to Escape on tap / Control on hold. No WSL or keyboard driver is needed.

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

Keep this checkout in a permanent location: setup links `%USERPROFILE%\.config\doom` to its `.config\doom` directory using a Windows directory junction, and points Doom directly at that repo path. Editing the normal Doom config in Emacs therefore edits the tracked files. A junction does not require Developer Mode or an administrator terminal. Keep the checkout in place after installation.

The first Doom installation can take 10-20 minutes. New Doom checkouts start at tested revision `7ccac7f643ad67baa25b216717cf8617a0903c69`; an existing Doom checkout is reused without upgrading it. Downloaded archives are pinned and checked against SHA-256 hashes; the WinGet tools use WinGet's package checksums.

## What it installs

- GNU Emacs 31.1, Doom, Git Bash launchers, and a Start menu shortcut.
- LLVM (`clangd`, `clang-format`), CMake, ripgrep with PCRE2, fd, ShellCheck, shfmt, MultiMarkdown, and Nerd Font symbols.
- [Kanata 1.11.0](https://github.com/jtroo/kanata/releases/tag/v1.11.0), using the Windows hooks build with a tray icon. It starts at sign-in. Version 1.12 is deliberately avoided because of its [Windows key-state regression](https://github.com/jtroo/kanata/issues/2115), including repeated Quote/Backslash errors on UK layouts. The config explicitly disables optional key-state synchronization in 1.11.

The Doom One theme, size 16 text, Evil, Corfu/Vertico, Treemacs, Spawn syntax highlighting, and hidden Eglot inlay hints come from the shared config. Windows uses Eshell; macOS keeps vterm and its Homebrew LLVM paths. LLVM provides editor tooling; C++ projects may also need their own build toolchain and `compile_commands.json`.

Caps Lock taps under 500 ms send Escape. Holding it past 500 ms, or pressing another processed key while it is down, activates Left Control. Normal Escape stays Escape. The physical Left Control and AltGr keys are passed through for compatibility.

## Locations and reruns

| Item | Location |
| --- | --- |
| Doom core | `%USERPROFILE%\.config\emacs` |
| Doom config | `.config\doom` in this checkout, also accessible through `%USERPROFILE%\.config\doom` |
| Generated GUI launcher | `%LOCALAPPDATA%\dotfiles-windows\launchers` |
| Emacs and portable tools | `%LOCALAPPDATA%\Programs` |
| Terminal commands | `%USERPROFILE%\.local\bin` (added to user PATH) |
| Caps Lock config | `%USERPROFILE%\.config\kanata\kanata.kbd` |
| Caps Lock auto-start | Current user's Startup folder |
| Downloads and config backups | `%LOCALAPPDATA%\dotfiles-windows` |

The setup script is for installing or repairing Windows integration, not routine Doom config syncing. Run it from the same permanent checkout if needed. It reuses an existing correct junction; a link to another checkout is left untouched with an explanatory error. If an older copied Doom config directory exists, the whole directory is moved to the timestamped backup folder before creating the junction. Check that backup for local changes you want to merge into the repo. Generated launchers stay outside the shared config.

Differing launcher files and the copied Caps Lock config are backed up before replacement. An existing Kanata 1.12 installation from this setup is backed up and replaced with 1.11; only its own running GUI process is stopped, then the remapper is restarted. Other unexpected program versions stop setup rather than being overwritten. Existing unrelated configuration files are left in place. Existing unrelated Emacs configurations are not moved; the launchers explicitly select Doom's init directory. `HOME` and tool-specific paths are set only inside the launchers.

```powershell
.\setup-windows.ps1 -WhatIf          # Preview paths and actions without changes/downloads
.\setup-windows.ps1 -SkipCapsLock    # Only set up Doom
.\setup-windows.ps1 -SkipDoom        # Only set up Caps Lock
.\setup-windows.ps1 -SkipSync        # Link/configure Doom without running its package sync
```

## Editing and syncing Doom

Use `SPC f p` in Doom to open your private config, or open `~/.config/doom/config.el`. Saving changes edits this checkout immediately. `M-x magit-status` from a config file can commit and push them. You can also use PowerShell:

```powershell
Set-Location "$env:USERPROFILE\dotfiles"
git pull --ff-only                  # Before editing; commit your own changes first if necessary
# Edit and save your Doom config in Emacs.
git add .config/doom
git commit -m "Update Doom config"
git push
```

On the Mac's existing bare-repo setup:

```sh
cd ~
config pull --ff-only
# After editing on Mac:
config add .config/doom
config commit -m "Update Doom config"
config push
```

Back on Windows, just `git pull --ff-only` from this checkout; the live config is already updated. Restart Emacs or reload the config after pulling `config.el` changes. Changes to `init.el` or `packages.el` still require `doom sync` and an Emacs restart on each machine; the Windows setup script is not needed. Doom's installation, package caches, and generated Windows launchers remain local to each machine.

## Maintenance and removal

- Run `doom doctor` for diagnostics and `doom upgrade` when you want to update Doom and its pinned packages.
- This pinned Windows Emacs distribution may report native compilation unavailable. Byte compilation works. Fontconfig detection and Bash's `.exe` name can also produce doctor warnings on Windows even when fonts, shell commands, and search work.
- To temporarily disable the remapping, quit Kanata from its tray menu. The physical **Left Control + Space + Escape** combination also exits Kanata.
- To stop auto-start, remove **Caps Lock - Escape and Control.lnk** from your user's Startup folder. To re-enable it, rerun setup.
- The hook-based remapper runs with your user privileges; administrator applications and some games may not accept the remapped keys. This setup does not install a driver or elevate the remapper.
- If an older setup reports `Unexpected keycode is pressed in kanata but not in Windows`, pull this repo and run `setup-windows.ps1 -SkipDoom` once. This replaces Kanata 1.12 with pinned 1.11 and keeps the 500 ms Escape/Control mapping.

To change the timing, edit both `500` values in `.config/kanata/kanata.kbd`, rerun setup, and reload its configuration from Kanata's tray menu (or quit and rerun setup). Keep the edited config in this repo so the next Windows machine gets it too.
