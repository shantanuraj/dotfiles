vim.g.mapleader = " "
vim.g.netrw_list_hide = "^\\./\\=$"
vim.g.netrw_banner = 0
vim.o.termguicolors = true
vim.o.background = "dark"
vim.cmd.colorscheme("quiet")
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
vim.o.signcolumn = "yes"

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

vim.filetype.add({ extension = { mdx = "mdx" } })

vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "<C-c>", "<cmd>normal! ciw<cr>a", { silent = true })
vim.keymap.set({ "n", "i" }, "<esc>", "<cmd>noh<cr><esc>", { silent = true })
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { silent = true })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { silent = true })
vim.keymap.set("x", "<leader>p", '"_dP')
vim.keymap.set("n", "-", "<cmd>Explore %:p:h<cr>")

local saved_layout = nil
vim.keymap.set("n", "<C-w>m", function()
	if saved_layout then
		vim.cmd.wincmd("=")
		saved_layout = nil
	else
		saved_layout = true
		vim.cmd.wincmd("_")
		vim.cmd.wincmd("|")
	end
end)

local function fzf_pick(cmd, sink, fzf_flags)
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
	vim.fn.jobstart(cmd .. " | fzf " .. (fzf_flags or "") .. " > " .. tempfile, {
		term = true,
		on_exit = function()
			vim.schedule(function()
				vim.cmd.bdelete({ bang = true })
				local lines = vim.fn.readfile(tempfile)
				vim.fn.delete(tempfile)
				if #lines > 0 and lines[1] ~= "" then
					sink(lines)
				end
			end)
		end,
	})
	vim.cmd.startinsert()
end

vim.keymap.set("n", "<leader><space>", function()
	fzf_pick("fd --type f --hidden --exclude .git", function(lines)
		vim.cmd.edit(lines[1])
	end)
end)

vim.keymap.set("n", "<leader>/", function()
	local rg = "rg --vimgrep --smart-case --color=always"
	fzf_pick(":", function(lines)
		local items = {}
		for _, line in ipairs(lines) do
			local l = line:gsub("\27%[[%d;]*m", "")
			local f, ln, c, t = l:match("([^:]+):(%d+):(%d+):(.*)")
			if f then
				items[#items + 1] = { filename = f, lnum = tonumber(ln), col = tonumber(c), text = t }
			end
		end
		if #items == 0 then
			return
		end
		if #items == 1 then
			vim.cmd.edit(items[1].filename)
			vim.api.nvim_win_set_cursor(0, { items[1].lnum, items[1].col - 1 })
		else
			vim.fn.setqflist(items, "r")
			vim.cmd.copen()
		end
	end, "--ansi --disabled --multi --bind 'change:reload:" .. rg .. " -- {q} || true' --bind 'ctrl-q:select-all+accept'")
end)

vim.keymap.set("n", "<leader>t", function()
	fzf_pick("awk -F'\\t' '!/^!/ {print $1}' tags | sort -u", function(lines)
		vim.cmd.tjump(lines[1])
	end)
end)

vim.api.nvim_create_user_command("MakeTags", function()
	vim.fn.jobstart("gotags -R -exclude=vendor -exclude=.git -exclude=node_modules . > tags", {
		on_exit = function(_, code)
			vim.schedule(function()
				vim.notify(
					code == 0 and "tags regenerated" or "gotags failed",
					code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
				)
			end)
		end,
	})
end, {})

vim.keymap.set("n", "<leader>T", "<cmd>MakeTags<cr>")

vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*",
	command = [[%s/\s\+$//e]],
})
