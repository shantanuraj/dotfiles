-- set leader key to space
vim.g.mapleader = " "

local git_cmd = require("user.git.cmd")
local which_key_status, which_key = pcall(require, "which-key")

if not which_key_status then
  return
end

which_key.setup({})

which_key.register({
  ["<c-\\>"] = { "<cmd>ToggleTerm<cr>", "Toggle terminal" },
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
      m = { "<cmd>MaximizerToggle<cr>", "Maximize current split window" },
    },
    t = {
      name = "+tab",
      t = { "<cmd>tabnew<cr>", "Open new tab" },
      x = { "<cmd>tabclose<cr>", "Close current tab" },
      n = { "<cmd>tabn<cr>", "Go to next tab" },
      p = { "<cmd>tabp<cr>", "Go to previous tab" },
    },
    u = {
      name = "+update",
      -- Clear search, diff update and redraw taken from runtime/lua/_editor.lua
      u = { "<cmd>nohlsearch<bar>diffupdate<bar>normal! <C-L><cr>", "Clear search, diff update and redraw" },
    },
    z = { "<cmd>ZenMode<cr>", "Toggle Zen mode" },
  },
  g = {
    r = { git_cmd.open_file_on_remote, "Open file on remote" },
    R = { "<cmd>GitBlameOpenCommitURL<cr>", "Open commit on remote" },
  },
})

which_key.register({
  ["<"] = { "<gv", "Tab back" },
  [">"] = { ">gv", "Tab forward" },
  ["gr"] = { git_cmd.open_file_on_remote, "Open selection on remote" },
}, { mode = "v" })
