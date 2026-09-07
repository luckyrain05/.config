# shell/

Shell config that lives outside `~/.config`, kept here so it can be shared
across machines without clobbering whatever each machine already has.

```sh
git clone git@github.com:luckyrain05/.config.git ~/.config
sh ~/.config/shell/install.sh --dry-run   # see what would change
sh ~/.config/shell/install.sh             # apply
exec zsh
```

## How it works

`fragments/<name>` maps to `~/.<name>`:

| fragment            | destination   |
| ------------------- | ------------- |
| `fragments/zshrc`    | `~/.zshrc`    |
| `fragments/zprofile` | `~/.zprofile` |

The installer **only ever appends**:

- A destination file is created only when it does not exist.
- Existing content is never edited, reordered, or removed.
- Each fragment is split into blocks on blank lines; a block is appended only
  if it is not already somewhere in the destination. So a machine that already
  has `export EDITOR=nvim` keeps its own copy and does not get a second one.
- Re-running is a no-op. A pre-existing destination gets a one-time
  `~/.zshrc.bak.<timestamp>` before its first append.

Matching trims leading/trailing whitespace and compares whole lines, so
re-indented copies count as present but `export EDITOR=nvimx` does not.

## Adding to it

Add or edit a file under `fragments/`, keeping **one blank line between
independent statements** — that is what makes per-statement deduplication
work. Multi-line things (a function, an `if`) must stay in one block with no
blank lines inside them. To cover a new file, add a `fragment:destination`
pair to `FRAGMENT_MAP` in `install.sh`.

## Caveats

- Fragments are copied verbatim from this machine, so `~/.zprofile` hardcodes
  the Apple Silicon Homebrew prefix (`/opt/homebrew`). On an Intel Mac, edit
  that line to `/usr/local/bin/brew` after installing.
- `~/.gitconfig` is deliberately not managed here: it holds a per-machine
  identity, not productivity setup.
