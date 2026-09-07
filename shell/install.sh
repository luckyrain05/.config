#!/bin/sh
#
# Non-destructive shell-config installer.
#
# Appends the blocks in shell/fragments/* to the matching file in $HOME,
# creating the file only when it is missing. Nothing is ever overwritten or
# removed, and a block that is already present anywhere in the target file is
# skipped, so running this repeatedly is a no-op.
#
#   sh shell/install.sh            # install
#   sh shell/install.sh --dry-run  # show what would change
#
# A "block" is a run of non-blank lines in a fragment (blank lines separate
# them). Matching ignores leading/trailing whitespace but is otherwise exact,
# and a single-line block matches a whole line only -- so `export EDITOR=nvim`
# will not be re-added just because it sits next to a different line upstream.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
FRAG_DIR="$SCRIPT_DIR/fragments"
DEST_DIR=${HOME:?HOME is not set}
DRY_RUN=0

# fragment file name : destination file name (relative to $HOME)
FRAGMENT_MAP='zshrc:.zshrc
zprofile:.zprofile'

SEP=$(printf '\036')

usage() {
	cat <<EOF
usage: sh install.sh [-n|--dry-run] [-h|--help]

Appends missing shell config blocks to the files in \$HOME. Existing content is
never modified or removed; blocks already present are skipped.
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		-n|--dry-run) DRY_RUN=1 ;;
		-h|--help) usage; exit 0 ;;
		*) printf 'install.sh: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
	esac
	shift
done

# Collapse a file (stdin) into one SEP-delimited line with per-line whitespace
# trimmed, so blocks can be matched as whole-line runs via shell globbing.
flatten() {
	sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | tr '\n' "$SEP"
}

added_total=0
created_total=0

for pair in $FRAGMENT_MAP; do
	frag_name=${pair%%:*}
	dest_name=${pair#*:}
	frag="$FRAG_DIR/$frag_name"
	dest="$DEST_DIR/$dest_name"

	[ -f "$frag" ] || { printf 'install.sh: missing fragment: %s\n' "$frag" >&2; exit 1; }

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

	# Haystack: the destination as it currently stands, plus anything we append
	# during this run (so a fragment cannot add the same block twice).
	if [ -f "$dest" ]; then
		hay=$SEP$(flatten < "$dest")
	else
		hay=$SEP
	fi

	tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/shellinstall.XXXXXX")
	# shellcheck disable=SC2064
	trap "rm -rf '$tmpdir'" EXIT INT TERM

	# Split the fragment into blocks, one temp file each (awk paragraph mode).
	awk -v d="$tmpdir" 'BEGIN { RS = ""; n = 0 } { n++; printf "%s\n", $0 > sprintf("%s/block.%04d", d, n) }' "$frag"

	backed_up=0
	for block in "$tmpdir"/block.*; do
		[ -e "$block" ] || continue
		needle=$SEP$(flatten < "$block")

		case "$hay" in
			*"$needle"*)
				continue
				;;
		esac

		printf 'append  %s <- %s\n' "$dest" "$(head -n 1 "$block")"
		added_total=$((added_total + 1))
		hay="$hay${needle#"$SEP"}"

		[ "$DRY_RUN" -eq 0 ] || continue

		# One backup per pre-existing file per run, before the first append.
		if [ "$backed_up" -eq 0 ] && [ "$fresh" -eq 0 ] && [ -s "$dest" ]; then
			cp -p "$dest" "$dest.bak.$(date +%Y%m%d%H%M%S)"
			backed_up=1
		fi

		# Keep exactly one blank line between what is there and what we add.
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
	printf 'Everything already in place; nothing to do.\n'
elif [ "$DRY_RUN" -eq 1 ]; then
	printf '\nDry run: %d block(s) would be appended, %d file(s) created.\n' "$added_total" "$created_total"
else
	printf '\nDone: %d block(s) appended, %d file(s) created. Restart your shell or run: exec zsh\n' "$added_total" "$created_total"
fi
