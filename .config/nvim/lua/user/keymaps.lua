-- better up/down movement
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- C-c to change word under cursor
vim.keymap.set({ "n" }, "<C-c>", "<cmd>normal! ciw<cr>a", { silent = true })

vim.keymap.set("n", "<C-space>", function()
  vim.cmd.normal({ "v", bang = true })
  require("vim.treesitter._select").select_parent(vim.v.count1)
end)

vim.keymap.set("x", "<C-space>", function()
  require("vim.treesitter._select").select_parent(vim.v.count1)
end)

vim.keymap.set("x", "<bs>", function()
  require("vim.treesitter._select").select_child(vim.v.count1)
end)

local which_key_status, which_key = pcall(require, "which-key")

if not which_key_status then
  return
end

which_key.setup({
  preset = "helix",
})

which_key.add({
  {
    group = "leader",
    { "<leader>R", "<cmd>source $MYVIMRC<cr>", desc = "Reload config" },
    { "<leader>w", ":%s/\\<<C-r><C-w>\\>//g<Left><Left>", desc = "Replace word under cursor" },
    {
      group = "tab",
      { "<leader>tt", vim.cmd.tabnew, desc = "Open new tab" },
      { "<leader>tx", vim.cmd.tabclose, desc = "Close current tab" },
    },
    { "<leader>z", function() Snacks.zen() end, desc = "Toggle Zen mode" },
    { "<leader>p", '"_dP', desc = "Paste without overwriting clipboard", mode = "x" },
  },
  {
    mode = "v",
    { "<", "<gv", desc = "Tab back" },
    { ">", ">gv", desc = "Tab forward" },
    { "gr", vim.cmd.GitOpenFileOnRemote, desc = "Open selection on remote" },
    { "J", ":m '>+1<CR>gv=gv", desc = "Move line down" },
    { "K", ":m '<-2<CR>gv=gv", desc = "Move line up" },
  },
  {
    "<esc>",
    "<cmd>noh<cr><esc>",
    desc = "Escape and clear hlsearch",
    mode = { "n", "i" },
  },
  { "<c-w>m", vim.cmd.MaximizerToggle, desc = "Maximize current split window" },
  { "[q", vim.cmd.cprev, desc = "Previous quickfix item" },
  { "]q", vim.cmd.cnext, desc = "Next quickfix item" },
})
