-- set leader key to space
vim.g.mapleader = " "

local git_cmd = require("user.git.cmd")
local which_key_status, which_key = pcall(require, "which-key")

if not which_key_status then
  return
end

which_key.setup({})

which_key.register({
  ["<c-space>"] = "Increment selection",
  ["<bs>"] = { "Decrement selection", mode = "x" },
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
      n = { vim.cmd.tabn, "Go to next tab" },
      p = { vim.cmd.tabp, "Go to previous tab" },
    },
    u = {
      name = "+update",
      -- Clear search, diff update and redraw taken from runtime/lua/_editor.lua
      u = { "<cmd>nohlsearch<bar>diffupdate<bar>normal! <C-L><cr>", "Clear search, diff update and redraw" },
    },
    z = { vim.cmd.ZenMode, "Toggle Zen mode" },
  },
  g = {
    r = { git_cmd.open_file_on_remote, "Open file on remote" },
    R = { vim.cmd.GitBlameOpenCommitURL, "Open commit on remote" },
  },
})

which_key.register({
  ["<"] = { "<gv", "Tab back" },
  [">"] = { ">gv", "Tab forward" },
  ["gr"] = { git_cmd.open_file_on_remote, "Open selection on remote" },
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
