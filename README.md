# .config

Personal config for macOS. This repo *is* `~/.config`.

Everything under `~/.config` is tracked directly. The two shell files that live
outside it (`~/.zshrc`, `~/.zprofile`) are embedded in [`install.sh`](install.sh),
which appends only what a machine is missing.

---

## New machine setup

### 1. Command line tools + Homebrew

```sh
xcode-select --install
```

Homebrew is installed by `install.sh` in step 3 if it is missing, so you can
skip it here.

### 2. Clone this repo into `~/.config`

`~/.config` almost always already exists, so a plain `git clone` into it will
fail. Attach the repo to the existing directory instead:

```sh
git clone --no-checkout https://github.com/luckyrain05/.config.git /tmp/dotfiles
mv /tmp/dotfiles/.git ~/.config/
rmdir /tmp/dotfiles
git -C ~/.config checkout main
```

If `~/.config` already holds a file this repo also tracks, the `checkout`
**refuses and names the conflicts** rather than overwriting them. Move the
machine's copy aside (`mv ~/.config/nvim ~/.config/nvim.local`) and re-run the
checkout.

If `~/.config` does not exist yet, the whole step is just:

```sh
git clone https://github.com/luckyrain05/.config.git ~/.config
```

> HTTPS avoids needing an SSH key on a fresh machine. Switch later with
> `git -C ~/.config remote set-url origin git@github.com:luckyrain05/.config.git`.

### 3. Run the installer

```sh
sh ~/.config/install.sh --dry-run   # see exactly what it would do
sh ~/.config/install.sh             # do it
exec zsh
```

It installs Homebrew if missing, taps `felixkratz/formulae` and
`nikitabobko/tap`, installs the CLI tools, apps and fonts these configs drive,
then appends the `~/.zshrc` and `~/.zprofile` blocks this machine is missing.

Flags: `--dry-run` / `-n`, `--no-brew`, `--no-shell`.

**It is safe to re-run.** `brew install` skips what is present; shell files are
created only when absent, existing lines are never edited or removed, and a
block already present is skipped — so a machine that already has
`export EDITOR=nvim` keeps its own copy instead of getting a second one. A
pre-existing file gets a one-time `~/.zshrc.bak.<timestamp>` before its first
append. The Homebrew line written to `~/.zprofile` uses the machine's real brew
prefix, so it is correct on both Apple Silicon and Intel.

### 4. Per-machine identity and credentials

Deliberately **not** in the repo (see `.gitignore`); the installer prints these
as reminders when it finishes:

```sh
git config --global user.name  "luckyrain05"
git config --global user.email "you@example.com"

gh auth login            # writes gh/hosts.yml
ssh-keygen -t ed25519    # if you want SSH remotes
gh ssh-key add ~/.ssh/id_ed25519.pub
```

GitHub Copilot credentials (`github-copilot/`) are ignored too — sign in from
inside the editor.

### 5. First run of each app

- **nvim** — just run `nvim`. `lua/config/lazy.lua` bootstraps lazy.nvim on
  first launch and installs everything. `:Lazy restore` pins plugins to the
  exact versions in `nvim/lazy-lock.json`. LSP servers install via Mason on
  first use of a filetype.
- **AeroSpace** — launch it once, then grant Accessibility permission in
  *System Settings → Privacy & Security → Accessibility*. It is configured with
  `start-at-login = true` and launches `borders` on startup.
- **Ghostty** — reads `ghostty/config` and the `old-world` theme automatically.
- **tmux** — no plugin manager; `tmux/tmux.conf` is read as-is. Prefix + `r`
  reloads it.

### 6. Verify

```sh
which nvim tmux yazi brew        # all resolve
sh ~/.config/install.sh          # should report 0 blocks appended
```

---

## Editing the shell config

`~/.zshrc` and `~/.zprofile` content lives in the `fragment_zshrc` and
`fragment_zprofile` functions in `install.sh`. Keep **one blank line between
independent statements** — that is what makes per-statement deduplication work.
Multi-line things (a function, an `if`) must stay in one block with no blank
lines inside. To manage another file, add a function and a `FRAGMENT_MAP` entry.

## Known gaps

- `neofetch/config.conf` is tracked but `neofetch` is not installed and is not
  in the install list.
