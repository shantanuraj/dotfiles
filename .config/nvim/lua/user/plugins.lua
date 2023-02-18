local fzf_make_cmd = "make"
if vim.loop.os_uname().machine == "arm64" then
  fzf_make_cmd = " arch -arm64 make"
end

return require("lazy").setup({
  -- Theme
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("tokyonight-night")
    end,
  },

  -- GitHub CoPilot
  "github/copilot.vim",

  -- Fzf native
  { "nvim-telescope/telescope-fzf-native.nvim", build = fzf_make_cmd },

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.0",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },

  -- Telescope orthogonal deps
  {
    "nvim-treesitter/nvim-treesitter",
    build = function()
      require("nvim-treesitter.install").update({ with_sync = true })
    end,
  },

  -- Lualine
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons", opt = true },
  },

  -- Tmux navigator
  "christoomey/vim-tmux-navigator",

  -- File explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    tag = "nightly",
  },

  -- Maximizes and restores current window
  "szw/vim-maximizer",

  -- Add, delete, change surroundings
  "tpope/vim-surround",

  -- Commenting with gc
  "numToStr/Comment.nvim",

  -- Autocompletion
  "hrsh7th/nvim-cmp", -- completion plugin
  "hrsh7th/cmp-buffer", -- source for text in buffer
  "hrsh7th/cmp-path", -- source for file system paths

  -- Snippets
  "L3MON4D3/LuaSnip", -- snippet engine
  "saadparwaiz1/cmp_luasnip", -- for autocompletion
  "rafamadriz/friendly-snippets", -- useful snippets

  -- Managing & installing lsp servers, linters & formatters
  "williamboman/mason.nvim", -- in charge of managing lsp servers, linters & formatters
  "williamboman/mason-lspconfig.nvim", -- bridges gap b/w mason & lspconfig

  -- Configuring lsp servers
  "neovim/nvim-lspconfig", -- easily configure language servers
  "hrsh7th/cmp-nvim-lsp", -- for autocompletion
  {
    "glepnir/lspsaga.nvim", -- enhanced lsp uis
    branch = "main",
    dependencies = {
      { "nvim-tree/nvim-web-devicons" },
      { "nvim-treesitter/nvim-treesitter" },
    },
  },
  "jose-elias-alvarez/typescript.nvim", -- additional functionality for typescript server (e.g. rename file & update imports)
  "onsails/lspkind.nvim", -- vs-code like icons for autocompletion

  -- Formatting & linting
  "jose-elias-alvarez/null-ls.nvim", -- configure formatters & linters
  "jayp0521/mason-null-ls.nvim", -- bridges gap b/w mason & null-ls

  -- Git blame
  "f-person/git-blame.nvim",

  -- Highlight TODOs
  {
    "folke/todo-comments.nvim",
    dependencies = "nvim-lua/plenary.nvim",
    config = function()
      require("todo-comments").setup({})
    end,
  },

  -- Show indent lines
  "lukas-reineke/indent-blankline.nvim",

  -- Which key
  "folke/which-key.nvim",

  -- Zen Mode
  {
    "folke/zen-mode.nvim",
    config = function()
      require("zen-mode").setup({
        plugins = {
          tmux = { enabled = true },
          alacritty = { enabled = true, font = "16" },
        },
      })
    end,
  },

  -- Floating terminal
  {
    "akinsho/toggleterm.nvim",
    tag = "2.3.0",
    config = function()
      require("toggleterm").setup({
        open_mapping = [[<c-\>]],
        hide_numbers = true,
        shade_filetypes = {},
        shade_terminals = true,
        start_in_insert = true,
        persist_size = true,
        direction = "float",
        close_on_exit = true,
      })
    end,
  },
})
