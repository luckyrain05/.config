# .config

Personal macOS config. This repo *is* `~/.config`.

## New machine

Delete any existing `~/.config` first, then:

```sh
git clone https://github.com/luckyrain05/.config.git ~/.config
sh ~/.config/install.sh
```

That installs Homebrew if missing, the packages these configs drive, and the
`~/.zshrc` / `~/.zprofile` bits that live outside this repo. `--dry-run` to
preview, `--no-brew` to skip packages. Safe to re-run.

Left over, because it can't be scripted:

```sh
git config --global user.name  "luckyrain05"
git config --global user.email "you@example.com"
gh auth login
```

Plus: open AeroSpace once and grant it Accessibility in System Settings, and
run `nvim` once to let lazy.nvim bootstrap (`:Lazy restore` pins to
`nvim/lazy-lock.json`).

## Editing the shell config

`~/.zshrc` and `~/.zprofile` content lives in the `fragment_zshrc` and
`fragment_zprofile` functions in `install.sh`. Keep one blank line between
independent statements — blocks are deduplicated against the destination, so
nothing gets added twice.
