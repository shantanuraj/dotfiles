-- Telescope config
require("telescope").setup({
	extensions = {
		fzf = {
			fuzzy = true, -- false will only do exact matching
			override_generic_sorter = true, -- override the generic sorter
			override_file_sorter = true, -- override the file sorter
			case_mode = "smart_case", -- or "ignore_case" or "respect_case"
			-- the default case_mode is "smart_case"
		},
	},
})

require("telescope").load_extension("fzf")

local M = {}

M.project_files = function()
	local opts = require("telescope.themes").get_dropdown({})
	vim.fn.system("git rev-parse --is-inside-work-tree")
	if vim.v.shell_error == 0 then
		require("telescope.builtin").git_files(opts)
	else
		opts.hidden = true
		require("telescope.builtin").find_files(opts)
	end
end

-- Keymaps
local wk = require("which-key")

wk.register({
	["<C-f>"] = { "<cmd>Telescope live_grep theme=get_dropdown<cr>", "Find in files" },
	["<C-S-f>"] = {
		[[<cmd>lua require('telescope.builtin').live_grep({search_dirs={vim.fn.expand("%:p")}})<CR>]],
		"Find in current file",
	},
	["<leader>"] = {
		["<space>"] = { M.project_files, "Go to File" },
		["f"] = {
			name = "+Find",
			C = { "<cmd>Telescope commands theme=get_dropdown<cr>", "Find command" },
			h = { "<cmd>Telescope help_tags theme=get_dropdown<cr>", "Find help" },
			m = { "<cmd>Telescope marks theme=get_dropdown<cr>", "Go to Mark" },
			R = { "<cmd>Telescope registers theme=get_dropdown<cr>", "Find registers" },
			r = { "<cmd>Telescope oldfiles only_cwd=true theme=get_dropdown<cr>", "Find recent files" },
			t = { "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", "Go to Symbol in workspace" },
			T = { "<cmd>Telescope<cr>", "Telescope" },
			b = { "<cmd>Telescope buffers<cr>", "Go to Buffer" },
		},
		["g"] = {
			name = "+Git",
			m = { "<cmd>Telescope git_status<cr>", "Go to Modified files" },
			C = { "<cmd>Telescope git_commits<cr>", "Checkout commit" },
			c = { "<cmd>Telescope git_bcommits<cr>", "Checkout commit [file]" },
			b = { "<cmd>Telescope git_branches<cr>", "Checkout branch" },
			s = { "<cmd>Telescope git_stash<cr>", "Pop Stash" },
		},
	},
})
