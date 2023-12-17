## Cloning this repository
- Clone the dotfiles into a [bare](https://www.saintsjd.com/2011/01/what-is-a-bare-git-repository/) in a "dot" folder of `$HOME`:

```
git clone --bare <git-repo-url> $HOME/.cfg
```

- Define the alias in the current shell scope:
```
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
```

- Checkout the actual content from the bare repository to your `$HOME`:
```
config checkout
```

- The step above might fail with a message like:
```
error: The following untracked working tree files would be overwritten by checkout:
    .bashrc
    .gitignore
Please move or remove them before you can switch branches.
Aborting
```

This is because your $HOME folder might already have some stock configuration files which would be overwritten by Git. The solution is simple: back up the files if you care about them, remove them if you don't care. I provide you with a possible rough shortcut to move all the offending files automatically to a backup folder:
```
mkdir -p .config-backup && \
config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | \
xargs -I{} mv {} .config-backup/{}
```

- Re-run the check out if you had problems:
```
config checkout
```

- Set the flag showUntrackedFiles to no on this specific (local) repository:
```
config config --local status.showUntrackedFiles no
```

- You're done, from now on you can now type config commands to add and update your dotfiles:
```
config status
config add .vimrc
config commit -m "Add vimrc"
config add .bashrc
config commit -m "Add bashrc"
config push
```
