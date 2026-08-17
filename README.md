# Dotfiles

My basic environment setup: zsh + oh-my-zsh + powerlevel10k, aliases, nano and screen config.
Work in progress. Always.

## Quick start

```bash
git clone https://github.com/morkertis/.files.git ~/.files
~/.files/install.sh
```

Then open a new terminal. That's it.

Re-running is safe: anything already installed is skipped, and any file the script replaces
is backed up to `<name>.backup-<timestamp>` first. `~/.files` is only a convention —
nothing here hardcodes it, so the clone can live anywhere.

## What the script does

1. Installs packages — see your system below.
2. Installs [uv](https://docs.astral.sh/uv/) (brew on macOS, the official installer on Linux).
3. Installs oh-my-zsh, the autosuggestions and syntax-highlighting plugins, and the
   powerlevel10k theme.
4. Symlinks `.zshrc`, `.screenrc` and `.nanorc` into `$HOME`.
5. Sets zsh as the default shell — last, and never fatal, so a failed `chsh` can't cost you
   the rest of the setup.

## Supported systems

| System | Packages via | Notes |
| --- | --- | --- |
| macOS — Intel and Apple Silicon | Homebrew | tested end to end |
| Debian, Ubuntu, Mint, Pop!_OS, Raspberry Pi OS, WSL | `apt` | package logic tested with stubbed package managers, not on a live box |
| Fedora, Amazon Linux 2023, RHEL, CentOS Stream, Rocky, AlmaLinux | `dnf` | same |
| Arch, Alpine, openSUSE, Gentoo, NixOS | — | package step is skipped, everything else still runs |

### macOS

- Install [Homebrew](https://brew.sh) first. The script stops if it's missing.
- brew installs `nano`, `uv` and `zsh`.
- No password prompts: brew needs no `sudo`, and `chsh` is skipped because zsh is already
  the default shell on macOS.

### Linux with apt or dnf

- Asks for your `sudo` password for the package installs. `chsh` may ask again.
- `zsh`, `git` and `curl` are required — a failure there stops the script.
- Everything else is best-effort: Python build dependencies (for `uv python install`), plus
  `nano`, `screen`, `htop`, `ncdu` and friends. Package names drift between releases, and
  both apt and dnf fail a whole transaction over one unknown name, so on failure the
  script retries package by package and reports only the ones that are genuinely
  unavailable.
- On dnf systems `chsh` comes from `util-linux-user`, which the script installs.

### Any other Linux

- No apt and no dnf: the script warns, skips the package step and carries on — everything
  after it is distro-agnostic.
- Install `zsh`, `git` and `curl` with your own package manager first. If they're missing
  the script stops and lists them.

## After installing

- Run `p10k configure` once to generate `~/.p10k.zsh` (not tracked here).
- Syntax highlighting in nano comes from the nano package's own system nanorc, not from this
  repo: `/etc/nanorc` on Linux distros, `$(brew --prefix)/etc/nanorc` under Homebrew.

  Seeing plain grey text? Check, in order:
  1. **The file type.** nano only colours what it has a syntax file for — `.py`, `.js`,
     `.sh`, `.json`, `.md` and friends. A `.txt`, `.log`, `.env` or extensionless file has
     no definition and renders plain. `ls $(brew --prefix)/share/nano` (or
     `/usr/share/nano`) lists what is covered.
  2. **Which binary you got.** `which nano` must not be `/usr/bin/nano` — on macOS that is
     pico, which has no highlighting at all and ignores `~/.nanorc`. Real GNU nano comes
     from `brew install nano`, which the script does.
  3. **The system nanorc.** On a distro where highlighting is off, uncomment the
     `include ".../share/nano/*.nanorc"` line in `/etc/nanorc`.

## Secrets and machine-local config

Everything in this repo is public, so nothing secret goes in a tracked file. Two gitignored
files are sourced automatically if they exist:

| File | For |
| --- | --- |
| `zsh/.private.zsh` | env exports: API keys, tokens, work-only `PATH` entries |
| `aliases/.private.aliases` | aliases you don't want to publish |

Set up the first one:

```bash
cp ~/.files/zsh/.private.zsh.example ~/.files/zsh/.private.zsh
chmod 600 ~/.files/zsh/.private.zsh
```

Both are covered by the `.private.*` rule in [.gitignore](.gitignore), so `git status` will
never offer to commit them. `zsh/.private.zsh` is sourced at the end of `.zshrc`, so it can
also override anything set earlier.

## Layout

```
aliases/    shell aliases (shared, linux-only, private)
nano/       nano settings
screen/     GNU screen config
zsh/        .zshrc
install.sh  one-shot setup
```
