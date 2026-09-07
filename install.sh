#!/bin/sh

set -eu

say() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }

if ! command -v brew >/dev/null 2>&1; then
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    say "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ -x /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
fi

BREW=$(command -v brew)

say "Tapping"
brew tap felixkratz/formulae
brew tap nikitabobko/tap

say "Installing command line tools"
brew install neovim tmux yazi fzf ripgrep fd zoxide gh git lazygit jq node \
  tree-sitter-cli sevenzip poppler resvg imagemagick-full ffmpeg-full borders

say "Installing apps and fonts"
brew install --cask ghostty aerospace font-jetbrains-mono-nerd-font \
  font-symbols-only-nerd-font

say "Shell config"

ZSHRC="$HOME/.zshrc"
ZPROFILE="$HOME/.zprofile"
touch "$ZSHRC" "$ZPROFILE"

grep -q 'yazi-cwd' "$ZSHRC" || cat >>"$ZSHRC" <<'EOF'

function y() {
	local tmp cwd; tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || builtin true
	command rm -f -- "$tmp"
}
EOF

grep -q 'EDITOR=nvim' "$ZSHRC" || echo 'export EDITOR=nvim' >>"$ZSHRC"
grep -q '.local/bin' "$ZSHRC" || echo 'export PATH="$HOME/.local/bin:$PATH"' >>"$ZSHRC"
grep -q 'shellenv' "$ZPROFILE" || printf 'eval "$(%s shellenv zsh)"\n' "$BREW" >>"$ZPROFILE"

say "Done"

cat <<'EOF'
Left to do by hand:
  git config --global user.name  "luckyrain05"
  git config --global user.email "you@example.com"
  gh auth login
  open AeroSpace once, grant Accessibility in System Settings

Then: exec zsh
EOF
