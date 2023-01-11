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

-- Keymaps
local wk = require("which-key")

wk.register({
	["<C-f>"] = { "<cmd>Telescope live_grep theme=get_dropdown<cr>", "Find in files" },
	["<C-S-f>"] = {
		[[<cmd>lua require('telescope.builtin').live_grep({search_dirs={vim.fn.expand("%:p")}})<CR>]],
		"Find in current file",
	},
	["<leader>"] = {
		["<space>"] = { "<cmd>Telescope find_files theme=get_dropdown<cr>", "Go to File" },
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
			s = { "<cmd>Telescope git_status<cr>", "Go to Modified files" },
			l = { "<cmd>Telescope git_commits<cr>", "Go to Commit" },
			c = { "<cmd>Telescope git_bcommits<cr>", "Go to Commit for file" },
		},
	},
})
