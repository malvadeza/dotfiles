#!/bin/bash

dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Array of files to symlink
files=(
    "zshrc"
    "oh-my-zsh"
    "tmux.conf"
)

# Create symlinks
for file in "${files[@]}"; do
    src="${dotfiles_dir}/${file}"
    dest="${HOME}/.${file}"
    ln -sf "$src" "$dest"
done

# Create .zsh_overrides file
touch "${HOME}/.zsh_overrides"

echo "Dotfiles setup complete."