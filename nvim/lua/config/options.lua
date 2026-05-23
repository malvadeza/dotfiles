-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Disable legacy Python 3 provider — takes ~6s scanning for Python on startup.
-- Not needed for LSP, treesitter, ruff, or ty (they run as separate processes).
vim.g.loaded_python3_provider = 0

-- Dark/Light theme based on macOS system appearance
local function set_theme()
  local handle = io.popen("defaults read -g AppleInterfaceStyle 2>/dev/null")
  local result = handle:read("*a"):gsub("\n", "")
  handle:close()

  if result == "Dark" then
    vim.cmd("colorscheme tokyonight")
  else
    vim.cmd("colorscheme tokyonight-day")
  end
end

vim.api.nvim_create_autocmd({ "User", "FocusGained" }, {
  pattern = "LazyDone",
  callback = set_theme,
})
