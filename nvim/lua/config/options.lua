-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Disable legacy Python 3 provider — takes ~6s scanning for Python on startup.
-- Not needed for LSP, treesitter, ruff, or ty (they run as separate processes).
vim.g.loaded_python3_provider = 0
