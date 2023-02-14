-- Author: Shantanu Raj <s@sraj.me> [https://sraj.me]

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- options
require("user.options")

-- include lazy
require("user.plugins")

require("user.keymaps")
require("user.telescope")
require("user.treesitter")
require("user.colorscheme")
require("user.statusline")
require("user.nvimtree")
require("user.commentary")
require("user.completion")
require("user.lsp.mason")
require("user.lsp.lspsaga")
require("user.lsp.lspconfig")
require("user.lsp.null-ls")
