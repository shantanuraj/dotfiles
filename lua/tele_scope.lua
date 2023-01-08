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
	["<C-p>"] = { "<cmd>Telescope find_files theme=get_dropdown<cr>", "Go to File" },
	["<C-f>"] = { "<cmd>Telescope live_grep theme=get_dropdown<cr>", "Find in files" },
	["<C-S-f>"] = {
		[[<cmd>lua require('telescope.builtin').live_grep({search_dirs={vim.fn.expand("%:p")}})<CR>]],
		"Find in current file",
	},
	["<C-t>"] = { "<cmd>lua require('telescope.builtin').tags{ only_current_buffer = true }<CR>", "Find tags" },
})

-- map('n', '<C-i>', [[lua require'telescope.builtin'.live_grep({search_dirs={vim.fn.expand("%:p")}})<cr>]], silent)
