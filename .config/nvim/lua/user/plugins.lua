local fzf_make_cmd = "make"
if vim.loop.os_uname().machine == "arm64" then
  fzf_make_cmd = " arch -arm64 make"
end

return require("lazy").setup({
  defaults = {
    lazy = true,
  },
  -- Theme
  {
    "catppuccin/nvim",
    lazy = false,
    priority = 1000,
    name = "catppuccin",
    opts = {
      flavour = "latte",
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  -- GitHub CoPilot
  { "github/copilot.vim" },

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.0",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = fzf_make_cmd }, -- Fzf native
    },
  },

  -- Telescope orthogonal deps
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
    build = function()
      require("nvim-treesitter.install").update({ with_sync = true })
    end,
    dependencies = {
      {
        "nvim-treesitter/nvim-treesitter-textobjects",
        opts = function()
          return require("user.treesitter")
        end,
        config = function(_, opts)
          require("nvim-treesitter.configs").setup(opts)
          local ts_repeat_move = require("nvim-treesitter.textobjects.repeatable_move")
          local which_key_status, which_key = pcall(require, "which-key")
          if not which_key_status then
            return
          end
          which_key.register({
            [";"] = { ts_repeat_move.repeat_last_move_next, "move next" },
            [","] = { ts_repeat_move.repeat_last_move_previous, "move previous" },
            ["f"] = { ts_repeat_move.builtin_f, "move forward" },
            ["F"] = { ts_repeat_move.builtin_F, "move backward" },
            ["t"] = { ts_repeat_move.builtin_t, "move to" },
            ["T"] = { ts_repeat_move.builtin_T, "move to before" },
          }, { mode = { "n", "o", "x" } })
        end,
      },
    },
  },

  -- Lualine
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons", opt = true },
    opts = function()
      return {
        sections = {
          lualine_z = {
            "location",
            {
              "searchcount",
              maxcount = 999,
              timeout = 500,
            },
          },
        },
        options = {
          theme = "auto",
          globalstatus = true,
          disabled_filetypes = { statusline = { "dashboard", "alpha" } },
        },
        extensions = { "lazy" },
      }
    end,
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
    lazy = true,
  },

  -- Maximizes and restores current window
  { "szw/vim-maximizer", event = "VeryLazy" },

  -- Add, delete, change surroundings
  { "tpope/vim-surround", event = { "BufReadPost", "BufNewFile" } },

  -- Commenting with gc
  {
    "numToStr/Comment.nvim",
    event = "BufRead",
    dependencies = {
      -- context aware commentstring for TypeScript
      "JoosepAlviste/nvim-ts-context-commentstring",
    },
    config = function()
      local opts = {
        pre_hook = function(ctx)
          -- Only for TypeScript React
          if vim.bo.filetype == "typescriptreact" then
            local U = require("Comment.utils")

            -- Determine whether to use linewise or blockwise commentstring
            local type = ctx.ctype == U.ctype.linewise and "__default" or "__multiline"

            -- Determine the location where to calculate commentstring from
            local location = nil
            if ctx.ctype == U.ctype.blockwise then
              location = require("ts_context_commentstring.utils").get_cursor_location()
            elseif ctx.cmotion == U.cmotion.v or ctx.cmotion == U.cmotion.V then
              location = require("ts_context_commentstring.utils").get_visual_start_location()
            end

            return require("ts_context_commentstring.internal").calculate_commentstring({
              key = type,
              location = location,
            })
          end
        end,
      }
      require("Comment").setup(opts)
    end,
  },

  -- Autocompletion
  {
    "hrsh7th/nvim-cmp", -- completion plugin
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-buffer", -- source for text in buffer
      "hrsh7th/cmp-path", -- source for file system paths
      "saadparwaiz1/cmp_luasnip", -- for autocompletion
      "onsails/lspkind.nvim", -- vs-code like icons for autocompletion
      {
        "L3MON4D3/LuaSnip", -- snippet engine
        dependencies = {
          {
            "rafamadriz/friendly-snippets",
            config = function()
              -- load vs-code like snippets from plugins (e.g. friendly-snippets)
              require("luasnip.loaders.from_vscode").lazy_load()
            end,
          }, -- useful snippets
        },
      },
    },
    opts = function()
      local completion = require("user.completion")
      return completion
    end,
  },

  -- Better text-objects
  {
    "echasnovski/mini.ai",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter-textobjects" },
    opts = function()
      local ai = require("mini.ai")
      return {
        n_lines = 500,
        custom_textobjects = {
          o = ai.gen_spec.treesitter({
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }, {}),
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }, {}),
        },
      }
    end,
    config = function(_, opts)
      require("mini.ai").setup(opts)
      -- register all text objects with which-key

      local which_key_status, which_key = pcall(require, "which-key")
      if not which_key_status then
        return
      end

      ---@type table<string, string|table>
      local i = {
        [" "] = "Whitespace",
        ['"'] = 'Balanced "',
        ["'"] = "Balanced '",
        ["`"] = "Balanced `",
        ["("] = "Balanced (",
        [")"] = "Balanced ) including white-space",
        [">"] = "Balanced > including white-space",
        ["<lt>"] = "Balanced <",
        ["]"] = "Balanced ] including white-space",
        ["["] = "Balanced [",
        ["}"] = "Balanced } including white-space",
        ["{"] = "Balanced {",
        ["?"] = "User Prompt",
        _ = "Underscore",
        a = "Argument",
        b = "Balanced ), ], }",
        c = "Class",
        f = "Function",
        o = "Block, conditional, loop",
        q = "Quote `, \", '",
        t = "Tag",
      }
      local a = vim.deepcopy(i)
      for k, v in pairs(a) do
        ---@diagnostic disable-next-line: param-type-mismatch
        a[k] = v:gsub(" including.*", "")
      end

      local ic = vim.deepcopy(i)
      local ac = vim.deepcopy(a)
      for key, name in pairs({ n = "Next", l = "Last" }) do
        i[key] = vim.tbl_extend("force", { name = "Inside " .. name .. " textobject" }, ic)
        a[key] = vim.tbl_extend("force", { name = "Around " .. name .. " textobject" }, ac)
      end
      which_key.register({
        mode = { "o", "x" },
        i = i,
        a = a,
      })
    end,
  },

  -- Managing & installing lsp servers, linters & formatters
  {
    "williamboman/mason.nvim", -- in charge of managing lsp servers, linters & formatters
    event = "VeryLazy",
    opts = {},
  },

  -- Configuring lsp servers
  {
    "neovim/nvim-lspconfig", -- easily configure language servers
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason-lspconfig.nvim", -- bridges gap b/w mason & lspconfig
      "hrsh7th/cmp-nvim-lsp", -- for autocompletion
      "jose-elias-alvarez/typescript.nvim", -- additional functionality for typescript server (e.g. rename file & update imports)
    },
    config = require("user.lsp.lspconfig"),
  },
  {
    "nvimdev/lspsaga.nvim", -- enhanced lsp uis
    event = "LspAttach",
    branch = "main",
    dependencies = {
      { "nvim-tree/nvim-web-devicons" },
      { "nvim-treesitter/nvim-treesitter" },
    },
    opts = {
      -- keybinds for navigation in lspsaga window
      move_in_saga = { prev = "<C-k>", next = "<C-j>" },
      -- use enter to open file with finder
      finder_action_keys = {
        open = "<CR>",
      },
      -- use enter to open file with definition preview
      definition_action_keys = {
        edit = "<CR>",
      },
    },
  },

  -- Formatting & linting
  {
    "jose-elias-alvarez/null-ls.nvim", -- configure formatters & linters
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason.nvim",
      "jayp0521/mason-null-ls.nvim", -- bridges gap b/w mason & null-ls
    },
    config = function()
      require("user.lsp.null-ls")
    end,
  },

  -- Git blame
  { "f-person/git-blame.nvim", event = "BufRead" },

  -- Highlight TODOs
  {
    "folke/todo-comments.nvim",
    event = "BufReadPost",
    dependencies = "nvim-lua/plenary.nvim",
    config = function()
      require("todo-comments").setup({})
    end,
  },

  -- Show indent lines
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "BufReadPre",
    opts = {
      use_treesitter = true,
      -- show_current_context = true,
      buftype_exclude = { "terminal", "nofile" },
      filetype_exclude = {
        "help",
        "packer",
        "NvimTree",
      },
    },
  },

  -- Which key
  "folke/which-key.nvim",

  -- Zen Mode
  {
    "folke/zen-mode.nvim",
    event = "VeryLazy",
    config = function()
      require("zen-mode").setup({
        window = {
          width = 150,
        },
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
    event = "VeryLazy",
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
