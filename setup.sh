#!/bin/bash

dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Array of files to symlink
FILES=(
  "zshrc"
  "oh-my-zsh"
)

# Create symlinks
for file in "${FILES[@]}"; do
  src="${dotfiles_dir}/${file}"
  dest="${HOME}/.${file}"

  if [ -e "$dest" ]; then
    echo "Dotfiles: Skipping $dest, already exists."
  else
    ln -sf "$src" "$dest"
    echo "Dotfiles: Created symlink for $file."
  fi
done

# Config dirs to symlink into ~/.config/
CONFIG_DIRS=(
  "ghostty"
  "nvim"
)

mkdir -p "${HOME}/.config"
for dir in "${CONFIG_DIRS[@]}"; do
  src="${dotfiles_dir}/${dir}"
  dest="${HOME}/.config/${dir}"

  if [ -e "$dest" ]; then
    echo "Dotfiles: Skipping $dest, already exists."
  else
    ln -sf "$src" "$dest"
    echo "Dotfiles: Created symlink for .config/$dir."
  fi
done

# Install zsh-syntax-highlighting
ZSH_SYNTAX_DIR="${dotfiles_dir}/oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
if [ -d "$ZSH_SYNTAX_DIR" ]; then
  echo "Dotfiles: Skipping zsh-syntax-highlighting, already installed."
else
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_SYNTAX_DIR"
  rm -rf "$ZSH_SYNTAX_DIR/.git"
  echo "Dotfiles: Installed zsh-syntax-highlighting."
fi

# Create .zsh_overrides file
zsh_overrides_file="${HOME}/.zsh_overrides"
if [ -e "$zsh_overrides_file" ]; then
  echo "Dotfiles: Skipping $zsh_overrides_file, already exists."
else
  touch "$zsh_overrides_file"
  echo "Dotfiles: Created $zsh_overrides_file."
fi

echo "Dotfiles: Setup complete."

