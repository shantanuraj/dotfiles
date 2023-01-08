-- set leader key to space
vim.g.mapleader = " "

local keymap = vim.keymap -- for conciseness

local which_key_status, which_key = pcall(require, "which-key")
if not which_key_status then
	-- if which-key is not installed, log a message
	print("which-key is not installed")
else
	which_key.setup({})
end

-- Replace word under cursor
vim.api.nvim_set_keymap("n", "<Leader>w", ":%s/\\<<C-r><C-w>\\>//", { noremap = true })

-- window management
keymap.set("n", "<leader>sv", "<C-w>v") -- split window vertically
keymap.set("n", "<leader>sh", "<C-w>s") -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=") -- make split windows equal width & height
keymap.set("n", "<leader>sx", ":close<CR>") -- close current split window

keymap.set("n", "<leader>to", ":tabnew<CR>") -- open new tab
keymap.set("n", "<leader>tx", ":tabclose<CR>") -- close current tab
keymap.set("n", "<leader>tn", ":tabn<CR>") --  go to next tab
keymap.set("n", "<leader>tp", ":tabp<CR>") --  go to previous tab
