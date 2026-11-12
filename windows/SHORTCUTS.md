# Windows app shortcuts

Hold **Shift + Alt** and press the app's letter:

| Shortcut | App |
| --- | --- |
| **Shift + Alt + C** | Google Chrome |
| **Shift + Alt + V** | Visual Studio Code |
| **Shift + Alt + X** | JaimieOS |
| **Shift + Alt + E** | Doom Emacs |

## Switching and returning

1. From any other app, press the shortcut to bring the target app forward. A minimized window is restored; if several windows match, the topmost matching window is selected, usually the one most recently used.
2. If the app has no open window, the shortcut launches it.
3. Press the same shortcut while in the target app to return to the window you came from. For example: ChatGPT → **Shift + Alt + V** → VS Code → **Shift + Alt + V** → ChatGPT.

Each app remembers its own return window. The return window must still exist. If you started in the target app without first switching to it with its shortcut, there is no saved return destination yet. Restarting the shortcut script clears the saved destinations. These shortcuts switch between app windows; they do not select browser tabs.

## Install or update

From this dotfiles checkout, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\setup-shortcuts.ps1
```

The installer runs for the current user without administrator access. It downloads the official portable [AutoHotkey 2.0.31 release](https://github.com/AutoHotkey/AutoHotkey/releases/tag/v2.0.31) if needed, verifies the ZIP's SHA-256, validates the script, backs up a differing installed script, enables sign-in startup, and starts the shortcuts. It can be rerun after pulling changes. Use `-WhatIf` to preview without changing files or downloading anything.

This setup installs the shortcut runner. The target apps must already be installed at these locations:

| App | Launch target |
| --- | --- |
| Chrome | `%ProgramFiles%\Google\Chrome\Application\chrome.exe` |
| VS Code | `%LOCALAPPDATA%\Programs\Microsoft VS Code\Code.exe` |
| JaimieOS | `%LOCALAPPDATA%\Programs\jaimieos\JaimieOS.exe` |
| Doom Emacs | `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Doom Emacs.lnk` |

The Doom shortcut comes from [Windows setup](README.md). Using it preserves Doom's environment and init directory when launching Emacs. If an app is installed elsewhere, update its launch target in [app-shortcuts.ahk](app-shortcuts.ahk) and rerun the installer.

## Files and maintenance

- Tracked source: `windows/app-shortcuts.ahk`.
- Installed copy: `%LOCALAPPDATA%\Programs\ChromeSwitcher\Chrome.ahk`.
- Portable runtime: `%LOCALAPPDATA%\Programs\ChromeSwitcher\AutoHotkey`.
- Sign-in shortcut: `Chrome Switcher.lnk` in the current user's Startup folder.
- Downloads and backups: `%LOCALAPPDATA%\dotfiles-windows`.

The `ChromeSwitcher` names are retained from the original Chrome-only setup; one process handles all four shortcuts. Edit the tracked source and rerun `setup-shortcuts.ps1` to apply changes. The installer replaces the running instance so duplicate shortcut handlers are not left behind.

To temporarily disable all four shortcuts, exit the AutoHotkey script from its system tray icon. To stop them at sign-in, remove `Chrome Switcher.lnk` from your Startup folder. Rerun the installer to enable them again.

If a key also launches an extra window, clear that combination from the app's desktop shortcut **Properties → Shortcut key** field. The old **Shift + Alt + J** binding for JaimieOS is no longer used. Like other shortcuts running as your normal user, these may not work while an administrator app is focused.
