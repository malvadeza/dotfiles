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

-- Toggle git blame for entire file
local function toggle_blame()
  local blame_win = nil
  -- Look for an existing gitsigns blame window
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == "gitsigns-blame" then
        blame_win = win
        break
      end
    end
  end

  if blame_win then
    -- Close the blame window if it exists
    vim.api.nvim_win_close(blame_win, true)
  else
    -- Open blame split
    require("gitsigns").blame()
  end
end

vim.keymap.set("n", "<leader>ga", toggle_blame, { desc = "Toggle git blame for file" })
