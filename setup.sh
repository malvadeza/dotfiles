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

    if [ -e "$dest" ]; then
        echo "Dotfiles: Skipping $dest, already exists."
    else
        ln -sf "$src" "$dest"
        echo "Dotfiles: Created symlink for $file."
    fi
done

# Create .zsh_overrides file
zsh_overrides_file="${HOME}/.zsh_overrides"
if [ -e "$zsh_overrides_file" ]; then
    echo "Dotfiles: Skipping $zsh_overrides_file, already exists."
else
    touch "$zsh_overrides_file"
    echo "Dotfiles: Created $zsh_overrides_file."
fi

echo "Dotfiles: Setup complete."