# Dotfiles

## Setup

- macOS: `bash setup.sh`
- Windows 10/11 (x64): see [Windows setup](windows/README.md) for native Doom Emacs and Caps Lock as Escape/Control.

## Syncing Doom config between Mac and Windows

Both machines use the same tracked `.config/doom` files. On the Mac, the `config` alias manages the bare dotfiles repo with your home folder as its working tree. On Windows, `~/.config/doom` links to the permanent `~/dotfiles/.config/doom` checkout, so saving config changes in Emacs edits the Git-tracked files directly.

Pull before editing on either machine. If you already have local edits, commit them before pulling. Use `SPC f p` in Doom to open your config.

### Pull changes on Mac

```sh
cd ~
config pull --ff-only origin main
```

After editing and saving your config on Mac, commit and push it:

```sh
cd ~
config add .config/doom
config commit -m "Update Doom config"
config push origin main
```

### Pull changes on Windows

```powershell
Set-Location "$env:USERPROFILE\dotfiles"
git pull --ff-only origin main
```

After editing and saving your config in Emacs, commit and push it from that checkout:

```powershell
Set-Location "$env:USERPROFILE\dotfiles"
git add .config/doom
git commit -m "Update Doom config"
git push origin main
```

You can also use `M-x magit-status` from a config file on Windows to commit, pull, and push. Then pull on the other machine to receive those changes.

### Apply config changes in Emacs

For the first sync after setting up a machine, run `doom sync` in its terminal and restart Emacs. For later changes:

- `config.el` or loaded Lisp files: reload the config or restart Emacs.
- `init.el` or `packages.el`: run `doom sync` on each machine after pulling, then restart Emacs.

The Windows setup script does not need to be rerun for routine Doom config changes. Each machine keeps its own Doom installation, package caches, and generated launchers. The Kanata Caps Lock remapper and its compatibility fixes apply only to Windows.
