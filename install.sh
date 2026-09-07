#!/bin/sh
#
# One-shot setup for a new macOS machine.
#
#   sh install.sh              # install everything
#   sh install.sh --dry-run    # show what would happen, change nothing
#   sh install.sh --no-brew    # skip package installation
#   sh install.sh --no-shell   # skip ~/.zshrc and ~/.zprofile
#
# Package installs are idempotent (brew skips what is present). Shell config is
# appended only where missing: files are created only if absent, existing lines
# are never edited or removed, and a block already present is skipped. Running
# this twice is a no-op.

set -eu

DRY_RUN=0
DO_BREW=1
DO_SHELL=1

usage() {
	cat <<EOF
usage: sh install.sh [-n|--dry-run] [--no-brew] [--no-shell] [-h|--help]

Installs the packages these configs drive, then appends the shell config in
\$HOME that this machine is missing. Never overwrites existing content.
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		-n|--dry-run) DRY_RUN=1 ;;
		--no-brew) DO_BREW=0 ;;
		--no-shell) DO_SHELL=0 ;;
		-h|--help) usage; exit 0 ;;
		*) printf 'install.sh: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
	esac
	shift
done

say() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
run() { if [ "$DRY_RUN" -eq 1 ]; then printf '   would run: %s\n' "$*"; else "$@"; fi; }

# ---------------------------------------------------------------- packages ---

BREW_TAPS='felixkratz/formulae nikitabobko/tap'

# CLI. poppler/resvg/imagemagick/ffmpeg back yazi's file previews;
# borders is launched by AeroSpace.
BREW_FORMULAE='neovim tmux yazi fzf ripgrep fd zoxide gh git lazygit jq node
tree-sitter-cli sevenzip poppler resvg imagemagick-full ffmpeg-full borders'

BREW_CASKS='ghostty aerospace obsidian zen spotify
font-jetbrains-mono-nerd-font font-symbols-only-nerd-font'

# Where brew is, or where it will be once installed.
if command -v brew >/dev/null 2>&1; then
	BREW_BIN=$(command -v brew)
elif [ -x /opt/homebrew/bin/brew ]; then
	BREW_BIN=/opt/homebrew/bin/brew
elif [ -x /usr/local/bin/brew ]; then
	BREW_BIN=/usr/local/bin/brew
elif [ "$(uname -m)" = arm64 ]; then
	BREW_BIN=/opt/homebrew/bin/brew   # Apple Silicon default prefix
else
	BREW_BIN=/usr/local/bin/brew      # Intel default prefix
fi

brew_failed=0

if [ "$DO_BREW" -eq 1 ]; then
	if [ ! -x "$BREW_BIN" ]; then
		say "Installing Homebrew"
		if [ "$DRY_RUN" -eq 1 ]; then
			printf '   would install Homebrew to %s\n' "$BREW_BIN"
		else
			/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		fi
	else
		say "Homebrew already installed ($BREW_BIN)"
	fi

	if [ -x "$BREW_BIN" ]; then
		eval "$("$BREW_BIN" shellenv sh)" 2>/dev/null || eval "$("$BREW_BIN" shellenv)"

		say "Tapping"
		for tap in $BREW_TAPS; do
			run "$BREW_BIN" tap "$tap" || brew_failed=1
		done

		say "Installing command line tools"
		# shellcheck disable=SC2086
		run "$BREW_BIN" install $BREW_FORMULAE || brew_failed=1

		say "Installing apps and fonts"
		# shellcheck disable=SC2086
		run "$BREW_BIN" install --cask $BREW_CASKS || brew_failed=1
	elif [ "$DRY_RUN" -eq 0 ]; then
		printf 'install.sh: Homebrew still not found at %s; skipping packages\n' "$BREW_BIN" >&2
		brew_failed=1
	fi
fi

# ----------------------------------------------------------- shell config ---
#
# Each fragment below is split into blocks on blank lines. A block is appended
# only if it is not already somewhere in the destination, so a machine that
# already has `export EDITOR=nvim` keeps its own copy instead of getting a
# second one. Keep one blank line between independent statements; keep
# multi-line things (a function, an if) in a single block.

fragment_zshrc() {
	cat <<'EOF'
# --- managed by ~/.config/install.sh ---

function y() {
	local tmp cwd; tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || builtin true
	command rm -f -- "$tmp"
}

export EDITOR=nvim

export PATH="$HOME/.local/bin:$PATH"
EOF
}

fragment_zprofile() {
	# Emitted with this machine's actual brew prefix, so it is correct on both
	# Apple Silicon (/opt/homebrew) and Intel (/usr/local).
	printf '%s\n\n' '# --- managed by ~/.config/install.sh ---'
	printf 'eval "$(%s shellenv zsh)"\n' "$BREW_BIN"
}

# fragment function suffix : destination file, relative to $HOME
FRAGMENT_MAP='zshrc:.zshrc
zprofile:.zprofile'

SEP=$(printf '\036')

# Collapse stdin into one SEP-delimited line with per-line whitespace trimmed,
# so blocks can be matched as whole-line runs with shell globbing.
flatten() {
	sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | tr '\n' "$SEP"
}

added_total=0
created_total=0

if [ "$DO_SHELL" -eq 1 ]; then
	say "Shell config"

	for pair in $FRAGMENT_MAP; do
		frag_name=${pair%%:*}
		dest=${HOME:?HOME is not set}/${pair#*:}

		fresh=0
		if [ ! -e "$dest" ]; then
			printf 'create  %s\n' "$dest"
			created_total=$((created_total + 1))
			fresh=1
			if [ "$DRY_RUN" -eq 0 ]; then
				: > "$dest"
				chmod 644 "$dest"
			fi
		elif [ ! -f "$dest" ]; then
			printf 'install.sh: %s exists but is not a regular file; skipping\n' "$dest" >&2
			continue
		fi

		# Haystack: the file as it stands, plus whatever we append this run, so
		# a fragment cannot add the same block twice.
		if [ -f "$dest" ]; then
			hay=$SEP$(flatten < "$dest")
		else
			hay=$SEP
		fi

		tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/configinstall.XXXXXX")
		# shellcheck disable=SC2064
		trap "rm -rf '$tmpdir'" EXIT INT TERM

		"fragment_$frag_name" > "$tmpdir/fragment"
		# One temp file per block (awk paragraph mode splits on blank lines).
		awk -v d="$tmpdir" 'BEGIN { RS = ""; n = 0 } { n++; printf "%s\n", $0 > sprintf("%s/block.%04d", d, n) }' "$tmpdir/fragment"

		backed_up=0
		for block in "$tmpdir"/block.*; do
			[ -e "$block" ] || continue
			needle=$SEP$(flatten < "$block")

			case "$hay" in
				*"$needle"*) continue ;;
			esac

			printf 'append  %s <- %s\n' "$dest" "$(head -n 1 "$block")"
			added_total=$((added_total + 1))
			hay="$hay${needle#"$SEP"}"

			[ "$DRY_RUN" -eq 0 ] || continue

			# One backup per pre-existing file per run, before its first append.
			if [ "$backed_up" -eq 0 ] && [ "$fresh" -eq 0 ] && [ -s "$dest" ]; then
				cp -p "$dest" "$dest.bak.$(date +%Y%m%d%H%M%S)"
				backed_up=1
			fi

			# Exactly one blank line between what is there and what we add.
			if [ -s "$dest" ]; then
				if [ "$(tail -c 1 "$dest" | od -An -c | tr -d ' ')" != '\n' ]; then
					printf '\n' >> "$dest"
				fi
				if [ -n "$(tail -n 1 "$dest")" ]; then
					printf '\n' >> "$dest"
				fi
			fi
			cat "$block" >> "$dest"
		done

		rm -rf "$tmpdir"
		trap - EXIT INT TERM
	done

	if [ "$added_total" -eq 0 ] && [ "$created_total" -eq 0 ]; then
		printf 'Everything already in place.\n'
	fi
fi

# ------------------------------------------------------------------ wrap up --

say "Summary"
if [ "$DRY_RUN" -eq 1 ]; then
	printf 'Dry run: %d shell block(s) would be appended, %d file(s) created.\n' \
		"$added_total" "$created_total"
	exit 0
fi

printf '%d shell block(s) appended, %d file(s) created.\n' "$added_total" "$created_total"
[ "$brew_failed" -eq 0 ] || printf 'Some brew steps failed - scroll up and re-run those by hand.\n' >&2

cat <<'EOF'

Still to do by hand:
  git config --global user.name  "luckyrain05"
  git config --global user.email "you@example.com"
  gh auth login
  nvim                 # bootstraps lazy.nvim; :Lazy restore to pin versions
  open AeroSpace, then grant Accessibility in System Settings

Then: exec zsh
EOF
