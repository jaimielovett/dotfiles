#!/bin/bash

# Exit on first error
set -e

echo "🚀 Starting Mac setup..."

# --- Install Homebrew ---
if ! command -v brew &>/dev/null; then
  echo "🍺 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add Homebrew to PATH
  if [[ "$(uname -m)" == "arm64" ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    echo 'eval "$(/usr/local/bin/brew shellenv)"' >>~/.zprofile
    eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  echo "✅ Homebrew already installed."
fi

brew update
brew upgrade

# --- macOS settings ---
echo "⚙️  Configuring macOS settings..."
# Disable natural scrolling (swiping up scrolls up)
defaults write -g com.apple.swipescrolldirection -bool false
killall Finder SystemUIServer || true

# --- Essential CLI tools ---
brew install git wget tree zsh tmux neovim ripgrep fd

# --- GUI Apps via Homebrew Cask ---
brew install --cask ghostty
brew install --cask google-chrome
brew install --cask raycast
brew install --cask 1password
brew install --cask notion
brew install --cask karabiner-elements
brew install --cask love
brew install --cask font-jetbrains-mono-nerd-font
brew install lazygit

# --- Avast Antivirus ---
echo "🛡️  Installing Avast Security..."
brew install --cask avast-security

# The Avast cask only downloads the .pkg; it must be manually confirmed by the user.
AVAST_INSTALLER=$(find /opt/homebrew/Caskroom/avast-security -name "Install Avast Security.pkg" | sort | tail -n 1)
if [ -f "$AVAST_INSTALLER" ]; then
  echo "📦 Launching Avast installer..."
  open "$AVAST_INSTALLER"
  echo "⚠️ Please follow the on-screen installer to complete Avast setup."
else
  echo "❌ Avast installer not found. Please check if the cask name changed."
fi

# --- Keyboard speed tuning ---
echo "⌨️  Increasing key repeat speed..."
defaults write -g KeyRepeat -int 2
defaults write -g InitialKeyRepeat -int 10
killall SystemUIServer || true

# --- Oh My Zsh ---
echo "🐚 Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  echo "✅ Oh My Zsh installed."
else
  echo "✅ Oh My Zsh already installed."
fi

# --- Oh My Zsh plugins & theme ---
echo "✨ Installing Oh My Zsh plugins and Powerlevel10k theme..."

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# zsh-autosuggestions
if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
fi

# zsh-syntax-highlighting
if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting
fi

# powerlevel10k theme
if [ ! -d "${ZSH_CUSTOM}/themes/powerlevel10k" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM}/themes/powerlevel10k
fi

echo "✅ Plugins and theme installed successfully!"

# --- Dotfiles setup (bare repo method) ---
echo "📂 Setting up dotfiles (bare repo method)..."

# If .cfg already exists, skip clone
if [ ! -d "$HOME/.cfg" ]; then
  git clone --bare https://github.com/jaimielovett/dotfiles "$HOME/.cfg"
else
  echo "✅ Existing dotfiles repo found at ~/.cfg"
fi

# Define alias for convenience
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

# Backup any conflicting files
mkdir -p "$HOME/.config-backup"
/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME checkout 2>&1 | egrep "\s+\." | awk '{print $1}' |
  xargs -I{} mv {} "$HOME/.config-backup"/{} || true

# Check out dotfiles
/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME checkout

# Don’t show untracked files in status
/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME config --local status.showUntrackedFiles no

echo "✅ Dotfiles installed successfully!"

# --- Neovim alias ---
# (Your dotfiles likely already handle this, but we'll make sure.)
if ! grep -q 'alias vim="nvim"' ~/.zshrc 2>/dev/null; then
  echo 'alias vim="nvim"' >>~/.zshrc
fi

echo 'Remember to run the command "source ~/.zshrc".'

# --- Cleanup ---
brew cleanup

echo "🎉 Setup complete!"
echo "🪄 Restart your Mac or log out/in for all settings to apply."
