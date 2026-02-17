vim.g.mapleader = " "
vim.o.termguicolors = true
vim.o.background = "dark"
vim.cmd.colorscheme("quiet")
vim.o.syntax = "on"
vim.o.errorbells = false
vim.o.number = true
vim.o.relativenumber = true
vim.o.cursorline = true
vim.o.cursorlineopt = "number"
vim.o.scrolloff = 10
vim.o.sidescrolloff = 10
vim.o.virtualedit = "block"
vim.o.showmode = true
vim.o.laststatus = 1

vim.o.expandtab = true
vim.o.shiftwidth = 2
vim.o.smarttab = true
vim.o.softtabstop = 2
vim.o.tabstop = 2
vim.o.autoindent = true

vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.wildignorecase = true
vim.o.grepprg = "rg --vimgrep --smart-case --glob=!.git"
vim.o.grepformat = "%f:%l:%c:%m"

vim.o.clipboard = "unnamedplus"
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.undofile = true
vim.o.timeoutlen = 500

vim.o.encoding = "utf-8"
vim.o.fileencoding = "utf-8"

vim.opt.guicursor = {
	"n-v-c:block",
	"i-ci-ve:ver25",
	"r-cr:hor20",
	"o:hor50",
}

vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "<C-c>", "<cmd>normal! ciw<cr>a", { silent = true })
vim.keymap.set({ "n", "i" }, "<esc>", "<cmd>noh<cr><esc>", { silent = true })
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { silent = true })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { silent = true })
vim.keymap.set("x", "<leader>p", '"_dP')
vim.keymap.set("n", "-", "<cmd>Explore %:p:h<cr>")

local function fzf_pick(cmd, sink)
	local tempfile = vim.fn.tempname()
	local buf = vim.api.nvim_create_buf(false, true)
	local width = math.floor(vim.o.columns * 0.6)
	local height = math.floor(vim.o.lines * 0.6)
	vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width) / 2),
		row = math.floor((vim.o.lines - height) / 2),
		style = "minimal",
		border = "single",
	})
	vim.api.nvim_buf_set_keymap(buf, "t", "<esc>", "<C-\\><C-n><cmd>bdelete!<cr>", { silent = true })
	vim.fn.jobstart(cmd .. " | fzf > " .. tempfile, {
		term = true,
		on_exit = function()
			vim.schedule(function()
				vim.cmd.bdelete({ bang = true })
				local lines = vim.fn.readfile(tempfile)
				vim.fn.delete(tempfile)
				if #lines > 0 and lines[1] ~= "" then
					sink(lines[1])
				end
			end)
		end,
	})
	vim.cmd.startinsert()
end

vim.keymap.set("n", "<leader><space>", function()
	fzf_pick("fd --type f --hidden --exclude .git", function(file)
		vim.cmd.edit(file)
	end)
end)

vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*",
	command = [[%s/\s\+$//e]],
})
