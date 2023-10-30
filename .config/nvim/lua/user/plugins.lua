local fzf_make_cmd = "make"
-- Check if we have vim.uv otherwise use vim.loop
local uv = vim.uv or vim.loop

-- Fzf native build command for Apple Silicon
if uv.os_uname().machine == "arm64" then
  fzf_make_cmd = " arch -arm64 make"
end

return require("lazy").setup({
  defaults = {
    lazy = true,
  },
  -- Theme
  {
    "ramojus/mellifluous.nvim",
    lazy = false,
    priority = 1000,
    name = "mellifluous",
    opts = {
      styles = {
        keywords = { italic = true },
        conditionals = { italic = true },
      },
      plugins = {
        cmp = true,
        gitsigns = true,
        indent_blankline = true,
        telescope = {
          enabled = true,
          nvchad_like = true,
        },
      },
    },
    config = function(_, opts)
      require("mellifluous").setup(opts)
      vim.cmd.colorscheme("mellifluous")
    end,
  },

  -- GitHub CoPilot
  { "github/copilot.vim" },

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = fzf_make_cmd }, -- Fzf native
      "nvim-telescope/telescope-live-grep-args.nvim",
    },
  },

  -- Telescope orthogonal deps
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
    build = function()
      require("nvim-treesitter.install").update({ with_sync = true })
    end,
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
    dependencies = {
      {
        "nvim-treesitter/nvim-treesitter-textobjects",
      },
    },
  },

  -- Lualine
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons", opt = true },
    opts = function()
      local function show_macro_recording()
        local recording_register = vim.fn.reg_recording()
        if recording_register == "" then
          return ""
        else
          return "Recording @" .. recording_register
        end
      end

      local oil = {
        sections = {
          lualine_a = {
            "mode",
          },
          lualine_b = {
            {
              "path",
              fmt = function()
                local cwd = vim.fn.getcwd()
                local exp = vim.fn.expand("%:p")
                ---@cast exp string
                local path = exp:sub(7)
                -- drop trailing slash
                path = path:sub(1, #path - 1)

                if path == "" then
                  return "/"
                end

                if path == cwd then
                  return cwd:match("([^/]+)$")
                end

                -- if path is in cwd, remove cwd from path
                if path:sub(1, #cwd) == cwd then
                  path = path:sub(#cwd + 2)
                end
                return path
              end,
            },
          },
        },
        filetypes = { "oil" },
      }

      return {
        sections = {
          lualine_a = {
            "mode",
            { "macro-recording", fmt = show_macro_recording },
          },
          lualine_x = {},
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
          globalstatus = true,
          disabled_filetypes = { statusline = { "dashboard", "alpha" } },
        },
        extensions = {
          "lazy",
          "toggleterm",
          oil,
        },
      }
    end,
    config = function(_, opts)
      local lualine = require("lualine")
      lualine.setup(opts)

      local refresh_statusline = function()
        lualine.refresh({
          place = { "statusline" },
        })
      end

      vim.api.nvim_create_autocmd("RecordingEnter", {
        callback = refresh_statusline,
      })
      vim.api.nvim_create_autocmd("RecordingLeave", {
        callback = refresh_statusline,
      })
    end,
  },

  -- Tmux navigator
  "christoomey/vim-tmux-navigator",

  -- File explorer
  {
    "stevearc/oil.nvim",
    opts = {
      prompt_save_on_select_new_entry = false,
      use_default_keymaps = false,
      keymaps = {
        ["?"] = "actions.show_help",
        ["<CR>"] = "actions.select",
        ["<C-s>"] = "actions.select_vsplit",
        ["<C-h>"] = "actions.select_split",
        ["<C-t>"] = "actions.select_tab",
        ["<Tab>"] = "actions.preview",
        ["<C-c>"] = "actions.close",
        ["<C-l>"] = "actions.refresh",
        ["-"] = "actions.parent",
        ["_"] = "actions.open_cwd",
        ["`"] = "actions.cd",
        ["~"] = "actions.tcd",
        ["g."] = "actions.toggle_hidden",
      },
    },
    -- Optional dependencies
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
    },
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

  -- auto pairs
  {
    "echasnovski/mini.pairs",
    event = "VeryLazy",
    opts = {},
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
      lightbulb = {
        virtual_text = false,
      },
    },
  },

  -- Formatting & linting
  {
    "nvimtools/none-ls.nvim", -- configure formatters & linters
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason.nvim",
      "jayp0521/mason-null-ls.nvim", -- bridges gap b/w mason & null-ls
    },
    config = function()
      require("user.lsp.null-ls")
    end,
  },

  -- Git custom commands
  {
    dir = "./git",
    event = { "BufReadPost" },
    config = function()
      require("user.git.config").setup()
    end,
    keys = {
      { "gr", vim.cmd.GitOpenFileOnRemote, "Open selection on remote" },
      { "gR", vim.cmd.GitOpenLineOnRemote, "Open commit on remote" },
    },
  },

  -- Git blame, gutter
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      current_line_blame = true,
      on_attach = function(buffer)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
        end

      -- stylua: ignore start
      map("n", "]g", gs.next_hunk, "Next Hunk")
      map("n", "[g", gs.prev_hunk, "Prev Hunk")
      map({ "n", "v" }, "<leader>ggs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
      map({ "n", "v" }, "<leader>ggr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
      map("n", "<leader>ggu", gs.undo_stage_hunk, "Undo Stage Hunk")
      map("n", "<leader>ggp", gs.preview_hunk, "Preview Hunk")
      map("n", "<leader>ggb", function() gs.blame_line({ full = true }) end, "Blame Line")
      map("n", "<leader>ggd", gs.diffthis, "Diff This")
      map("n", "<leader>ggD", function() gs.diffthis("~") end, "Diff This ~")
      map({ "o", "x" }, "ig", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
      end,
    },
  },

  -- Highlight TODOs
  {
    "folke/todo-comments.nvim",
    event = "BufReadPost",
    dependencies = "nvim-lua/plenary.nvim",
    config = function()
      require("todo-comments").setup({})
    end,
  },

  {
    "RRethy/vim-illuminate",
    event = { "BufReadPost", "BufNewFile" },
    opts = { delay = 200, modes_denylist = { "i" } },
    config = function(_, opts)
      require("illuminate").configure(opts)

      local function map(key, dir, buffer)
        vim.keymap.set("n", key, function()
          require("illuminate")["goto_" .. dir .. "_reference"](false)
        end, { desc = dir:sub(1, 1):upper() .. dir:sub(2) .. " Reference", buffer = buffer })
      end

      map("]]", "next")
      map("[[", "prev")

      -- also set it after loading ftplugins, since a lot overwrite [[ and ]]
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          local buffer = vim.api.nvim_get_current_buf()
          map("]]", "next", buffer)
          map("[[", "prev", buffer)
        end,
      })
    end,
    keys = {
      { "]]", desc = "Next Reference" },
      { "[[", desc = "Prev Reference" },
    },
  },

  -- Which key
  "folke/which-key.nvim",

  -- Zen Mode
  {
    "folke/zen-mode.nvim",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("zen-mode").setup({
        window = {
          width = 150,
        },
        plugins = {
          tmux = { enabled = true },
          alacritty = { enabled = true, font = "16" },
          wezterm = { enabled = true, font = "20" },
        },
      })
    end,
  },

  -- Better diagnostics list and others
  {
    "folke/trouble.nvim",
    cmd = { "TroubleToggle", "Trouble" },
    opts = { use_diagnostic_signs = true },
    keys = {
      { "gf", "<cmd>TroubleToggle lsp_references<cr>", desc = "LSP references" },
      { "<leader>xt", "<cmd>TroubleToggle<cr>", desc = "Trouble" },
      { "<leader>xx", "<cmd>TroubleToggle document_diagnostics<cr>", desc = "Document Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>TroubleToggle workspace_diagnostics<cr>", desc = "Workspace Diagnostics (Trouble)" },
      { "<leader>xl", "<cmd>TroubleToggle loclist<cr>", desc = "Location List (Trouble)" },
      { "<leader>xq", "<cmd>TroubleToggle quickfix<cr>", desc = "Quickfix List (Trouble)" },
      {
        "[q",
        function()
          if require("trouble").is_open() then
            require("trouble").previous({ skip_groups = true, jump = true })
          else
            vim.cmd.cprev()
          end
        end,
        desc = "Previous quickfix item",
      },
      {
        "]q",
        function()
          if require("trouble").is_open() then
            require("trouble").next({ skip_groups = true, jump = true })
          else
            vim.cmd.cnext()
          end
        end,
        desc = "Next quickfix item",
      },
    },
  },

  -- Floating terminal
  {
    "akinsho/toggleterm.nvim",
    tag = "v2.6.0",
    event = "VeryLazy",
    opts = {
      open_mapping = [[<c-\>]],
      hide_numbers = true,
      shade_filetypes = {},
      shade_terminals = true,
      start_in_insert = true,
      persist_size = true,
      direction = "float",
      close_on_exit = true,
      shell = vim.o.shell .. " -l",
    },
  },

  -- Undo tree
  {
    "mbbill/undotree",
    keys = {
      { "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "Toggle undotree" },
    },
  },

  {
    "goolord/alpha-nvim",
    event = "VimEnter",
    opts = function()
      local dashboard = require("alpha.themes.dashboard")
      local logo = [[
         ██╗   ██╗██╗███╗   ███╗          Z
         ██║   ██║██║████╗ ████║      Z
         ██║   ██║██║██╔████╔██║   z
         ╚██╗ ██╔╝██║██║╚██╔╝██║ z
          ╚████╔╝ ██║██║ ╚═╝ ██║
           ╚═══╝  ╚═╝╚═╝     ╚═╝
    ]]

      dashboard.section.header.val = vim.split(logo, "\n")
      dashboard.section.buttons.val = {
        dashboard.button("f", " " .. " Find file", ":Telescope find_files theme=get_ivy<CR>"),
        dashboard.button("n", " " .. " New file", ":ene <BAR> startinsert <CR>"),
        dashboard.button("r", " " .. " Recent files", ":Telescope oldfiles only_cwd=true theme=get_ivy<CR>"),
        dashboard.button("g", " " .. " Find text", ":Telescope live_grep <CR>"),
        dashboard.button("c", " " .. " Config", ":e $MYVIMRC <CR> | :cd %:h/../.. <CR>"),
        dashboard.button("l", "󰒲 " .. " Lazy", ":Lazy<CR>"),
        dashboard.button("q", " " .. " Quit", ":qa<CR>"),
      }
      for _, button in ipairs(dashboard.section.buttons.val) do
        button.opts.hl = "AlphaButtons"
        button.opts.hl_shortcut = "AlphaShortcut"
      end
      dashboard.section.header.opts.hl = "AlphaHeader"
      dashboard.section.buttons.opts.hl = "AlphaButtons"
      dashboard.section.footer.opts.hl = "AlphaFooter"
      dashboard.opts.layout[1].val = 8
      return dashboard
    end,
    config = function(_, dashboard)
      -- close Lazy and re-open when the dashboard is ready
      if vim.o.filetype == "lazy" then
        vim.cmd.close()
        vim.api.nvim_create_autocmd("User", {
          pattern = "AlphaReady",
          callback = function()
            require("lazy").show()
          end,
        })
      end

      require("alpha").setup(dashboard.opts)
    end,
  },
})
