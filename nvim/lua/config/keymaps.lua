-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Copy visual selection to system clipboard
vim.keymap.set("v", "<D-c>", '"+y', { desc = "Copy" })

-- Paste from system clipboard (belt-and-suspenders; usually already works)
vim.keymap.set({ "n", "v" }, "<D-v>", '"+p', { desc = "Paste" })
vim.keymap.set("i", "<D-v>", "<C-r>+", { desc = "Paste" })

-- Undo, in whatever mode you're in when you mess up
vim.keymap.set("n", "<D-z>", "u", { desc = "Undo" })
vim.keymap.set("i", "<D-z>", "<C-o>u", { desc = "Undo" }) -- run one normal-mode cmd, stay in insert
vim.keymap.set("v", "<D-z>", "<Esc>u", { desc = "Undo" })

-- Bonus: Cmd+Shift+Z as redo, matching mac convention
vim.keymap.set({ "n", "i", "v" }, "<D-S-z>", "<C-r>", { desc = "Redo" })

local run_cmd = {
  python = "python3",
  javascript = "node",
  typescript = "npx tsx",
  sh = "bash",
  lua = "lua",
  go = "go run",
}

vim.keymap.set("n", "<leader>rr", function()
  local runner = run_cmd[vim.bo.filetype]
  if not runner then
    vim.notify("No run command for filetype: " .. vim.bo.filetype, vim.log.levels.WARN)
    return
  end
  vim.cmd("write") -- save first
  local file = vim.fn.shellescape(vim.fn.expand("%:p"))
  vim.cmd("botright split")
  vim.cmd("resize 15")
  vim.cmd("terminal " .. runner .. " " .. file)
  vim.cmd("startinsert")
end, { desc = "Run current file" })
