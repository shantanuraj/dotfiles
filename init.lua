-- Author: Shantanu Raj <s@sraj.me> [https://sraj.me]

-- styles
vim.o.termguicolors = true
vim.o.syntax = 'on'
vim.o.errorbells = false
vim.o.smartcase = true
vim.o.showmode = false
vim.o.number = true
vim.o.relativenumber = true

-- encoding
vim.o.encoding = "utf-8"
vim.o.fileencoding = "utf-8"

-- cursor
vim.o.cursorline = true -- highlight current line
vim.o.scrolloff = 10 -- keep at least 8 lines after the cursor when scrolling
vim.o.sidescrolloff = 10 -- (same as `scrolloff` about columns during side scrolling)
vim.o.virtualedit = "block" -- allow the cursor to go in to virtual places

-- indentation
vim.o.expandtab = true -- replace tabs by spaces
vim.o.shiftwidth = 2 -- number of space to use for indent
vim.o.smarttab = true -- insert `shiftwidth` spaces instead of tabs
vim.o.softtabstop = 2 -- n spaces when using <Tab>
vim.o.tabstop = 2 -- n spaces when using <Tab>
vim.o.autoindent = true -- copy indent from current line when starting a new line

-- search and replace
vim.o.ignorecase = true -- ignore case when searching
vim.o.smartcase = true -- smarter search case
vim.o.wildignorecase = true -- ignore case in file completion
vim.o.wildignore = "" -- remove default ignores
vim.o.wildignore = vim.o.wildignore .. "*.o,*.obj,*.so,*.a,*.dylib,*.pyc,*.hi" -- ignore compiled files
vim.o.wildignore = vim.o.wildignore .. "*.zip,*.gz,*.xz,*.tar,*.rar" -- ignore compressed files
vim.o.wildignore = vim.o.wildignore .. "*/.git/*,*/.hg/*,*/.svn/*" -- ignore SCM files
vim.o.wildignore = vim.o.wildignore .. "*.png,*.jpg,*.jpeg,*.gif" -- ignore image files
vim.o.wildignore = vim.o.wildignore .. "*.pdf,*.dmg" -- ignore binary files
vim.o.wildignore = vim.o.wildignore .. ".*.sw*,*~" -- ignore editor files
vim.o.wildignore = vim.o.wildignore .. ".DS_Store" -- ignore OS files

-- clipboard
vim.o.clipboard = "unnamedplus" -- copy to system clipboard

-- Split config
vim.o.splitbelow = true -- put new windows below current
vim.o.splitright = true -- put new windows right of current

-- trim trailing whitespace
vim.cmd [[
  autocmd BufWritePre * %s/\s\+$//e
]]

-- include packer
require('plugins') -- lua/plugins.lua
require('keymaps') -- lua/keymaps.lua
require('tele_scope') -- lua/tele_scope.lua
require('treesitter') -- lua/treesitter.lua
require('colorscheme') -- lua/colorscheme.lua
require('statusline') -- lua/statusline.lua
require('nvimtree') -- lua/nvimtree.lua
require('splits') -- lua/splits.lua
