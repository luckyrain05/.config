# .config

Personal config for macOS. This repo *is* `~/.config`.

Everything under `~/.config` is tracked directly. The two shell files that live
outside it (`~/.zshrc`, `~/.zprofile`) are stored in [`shell/`](shell/) and
installed by a script that only ever appends — see [shell/README.md](shell/README.md).

---

## New machine setup

### 1. Command line tools + Homebrew

```sh
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Then follow the "Next steps" Homebrew prints to get `brew` on `PATH` for this
first session (step 4 makes it permanent).

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

> Cloning over HTTPS avoids needing an SSH key on a fresh machine. Switch to SSH
> later with `git -C ~/.config remote set-url origin git@github.com:luckyrain05/.config.git`.

### 3. Install the tools these configs drive

```sh
brew tap felixkratz/formulae
brew tap nikitabobko/tap

# CLI
brew install neovim tmux yazi fzf ripgrep fd zoxide gh git lazygit jq node \
             tree-sitter-cli sevenzip poppler resvg imagemagick-full ffmpeg-full borders

# Apps + fonts
brew install --cask ghostty aerospace obsidian zen spotify \
                    font-jetbrains-mono-nerd-font font-symbols-only-nerd-font
```

`yazi` uses `poppler`, `resvg`, `imagemagick-full` and `ffmpeg-full` for file
previews; `borders` is launched by AeroSpace. Trim the list if you do not want a
given app.

### 4. Install the shell config

```sh
sh ~/.config/shell/install.sh --dry-run   # preview
sh ~/.config/shell/install.sh             # apply
exec zsh
```

This appends `~/.zshrc` and `~/.zprofile` blocks the machine is missing and
leaves anything already there untouched. Safe to re-run.

**On an Intel Mac**, edit the Homebrew line it added to `~/.zprofile` from
`/opt/homebrew/bin/brew` to `/usr/local/bin/brew`.

### 5. Per-machine identity and credentials

These are deliberately **not** in the repo (see `.gitignore`) and must be set up
by hand:

```sh
git config --global user.name  "luckyrain05"
git config --global user.email "you@example.com"

gh auth login            # writes gh/hosts.yml
ssh-keygen -t ed25519    # if you want SSH remotes
gh ssh-key add ~/.ssh/id_ed25519.pub
```

GitHub Copilot credentials (`github-copilot/`) are also ignored — sign in from
inside the editor.

### 6. First run of each app

- **nvim** — just run `nvim`. `lua/config/lazy.lua` bootstraps lazy.nvim on
  first launch and installs everything. To pin plugins to the exact versions in
  `nvim/lazy-lock.json`, run `:Lazy restore`. LSP servers install via Mason on
  first use of a filetype.
- **AeroSpace** — launch it once, then grant Accessibility permission in
  *System Settings → Privacy & Security → Accessibility*. It is configured with
  `start-at-login = true` and launches `borders` on startup.
- **Ghostty** — picks up `ghostty/config` and the `old-world` theme
  automatically.
- **tmux** — no plugin manager; `tmux/tmux.conf` is read as-is. Prefix + `r`
  reloads it.

### 7. Verify

```sh
which nvim tmux yazi brew   # all resolve
nvim --version | head -1
sh ~/.config/shell/install.sh   # should say "Everything already in place"
```

---

## Known gaps

- `ghostty/config` runs `fastfetch` on every new window, but `fastfetch` is not
  in the install list above and is not installed on the current machine — every
  new Ghostty window prints `command not found`. Either `brew install fastfetch`
  or drop the `command =` line.
- `ghostty/config` asks for `MesloLGS Nerd Font Mono`, which is not installed;
  the nerd font actually present is JetBrains Mono, so Ghostty silently falls
  back. Either install `font-meslo-lg-nerd-font` or point the config at
  `JetBrainsMono Nerd Font`.
- `neofetch/config.conf` is tracked but `neofetch` is not installed anywhere.
