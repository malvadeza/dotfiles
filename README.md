# dotfiles

Personal dotfiles managed with symlinks.

## What's included

- **zsh** — `.zshrc`, oh-my-zsh (submodule), and zsh-syntax-highlighting
- **Ghostty** — terminal emulator config
- **LazyVim** — Neovim config

## Setup

```bash
git clone --recursive <repo-url> ~/dotfiles
cd ~/dotfiles
./setup.sh
```

This creates symlinks for:
- `~/.zshrc` → `~/dotfiles/zshrc`
- `~/.oh-my-zsh` → `~/dotfiles/oh-my-zsh`
- `~/.config/ghostty` → `~/dotfiles/ghostty`
- `~/.config/nvim` → `~/dotfiles/nvim`

## Updating oh-my-zsh

```bash
cd ~/dotfiles
git submodule update --remote oh-my-zsh
```
