-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Copy file paths
vim.keymap.set("n", "<leader>fy", function()
  local absolute = vim.fn.expand("%:p")
  local relative = vim.fn.fnamemodify(absolute, ":.")
  vim.fn.setreg("+", relative)
  vim.notify("Copied relative path: " .. relative, vim.log.levels.INFO)
end, { noremap = true, silent = true, desc = "Copy relative file path" })

vim.keymap.set("n", "<leader>fY", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify("Copied absolute path: " .. path, vim.log.levels.INFO)
end, { noremap = true, silent = true, desc = "Copy absolute file path" })
