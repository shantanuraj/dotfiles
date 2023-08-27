-- Author: Shantanu Raj <s@sraj.me> [https://sraj.me]

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local uv = vim.uv or vim.loop
if not uv.fs_stat(lazypath) then
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

-- set leader key to space so lazy maps it correctly
vim.g.mapleader = " "

-- options
require("user.options")

-- include lazy
require("user.plugins")

require("user.keymaps")
require("user.telescope")
