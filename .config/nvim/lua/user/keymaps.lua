local which_key_status, which_key = pcall(require, "which-key")

if not which_key_status then
  return
end

which_key.setup({})

which_key.register({
  ["<c-space>"] = "Increment selection",
  ["<bs>"] = { "Decrement selection", mode = "x" },
  ["gn"] = { vim.cmd.tabn, "Go to next tab" },
  ["gp"] = { vim.cmd.tabp, "Go to previous tab" },
  ["<leader>"] = {
    name = "+leader",
    R = { "<cmd>source $MYVIMRC<cr>", "Reload config" },
    w = { ":%s/\\<<C-r><C-w>\\>//g<Left><Left>", "Replace word under cursor" },
    s = {
      name = "+split",
      v = { "<C-w>v", "Split window vertically" },
      h = { "<C-w>s", "Split window horizontally" },
      e = { "<C-w>=", "Make split windows equal width & height" },
      x = { ":close<CR>", "Close current split window" },
      m = { vim.cmd.MaximizerToggle, "Maximize current split window" },
    },
    t = {
      name = "+tab",
      t = { vim.cmd.tabnew, "Open new tab" },
      x = { vim.cmd.tabclose, "Close current tab" },
    },
    z = { vim.cmd.ZenMode, "Toggle Zen mode" },
  },
})

which_key.register({
  ["<"] = { "<gv", "Tab back" },
  [">"] = { ">gv", "Tab forward" },
  ["gr"] = { vim.cmd.GitOpenFileOnRemote, "Open selection on remote" },
  ["J"] = { ":m '>+1<CR>gv=gv", "Move line down" },
  ["K"] = { ":m '<-2<CR>gv=gv", "Move line up" },
}, { mode = "v" })

which_key.register({
  ["<leader>"] = {
    name = "+leader",
    p = { '"_dP', "Paste without overwriting clipboard" },
  },
}, { mode = "x" })

which_key.register({
  ["<esc>"] = { "<cmd>noh<cr><esc>", "Escape and clear hlsearch" },
}, { mode = { "n", "i" } })
