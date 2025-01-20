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
    "mcchrish/zenbones.nvim",
    lazy = false,
    priority = 1000,
    dependencies = {
      "rktjmp/lush.nvim",
    },
    config = function()
      local opts = { darkness = "stark", colorize_diagnostic_underline_text = true }
      vim.g.zenbones = opts
      vim.opt.background = "dark"
      vim.cmd.colorscheme("zenbones")
    end,
  },

  -- GitHub CoPilot
  { "github/copilot.vim" },

  -- Codecompanion
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("codecompanion").setup({
        adapters = {
          anthropic = require("codecompanion.adapters").extend("anthropic", {
            env = {
              api_key = "ANTHROPIC_RK_KEY",
            },
            schema = {
              model = {
                default = "claude-3-5-sonnet-20240620",
              },
            },
          }),
        },
        strategies = {
          chat = {
            adapter = "anthropic",
          },
          inline = {
            adapter = "anthropic",
          },
          agent = {
            adapter = "anthropic",
          },
        },
        default_prompts = {
          ["html"] = {
            strategy = "inline",
            description = "Generate some boilerplate HTML",
            opts = {
              slash_cmd = "html",
            },
            prompts = {
              {
                role = "system",
                content = "You are an expert Web developer",
              },
              {
                role = "user",
                content = "Please generate modern HTML boilerplate with a modern CSS reset using best practices."
                  .. "\n"
                  .. "Use the latest HTML5 doctype, a CSS reset, and a viewport meta tag."
                  .. "\n"
                  .. "Use css variables for colors and fonts."
                  .. "\n"
                  .. "Respond with just the code, no markdown, don't explain yourself.",
              },
            },
          },
        },
      })

      vim.keymap.set({ "n" }, "<leader>rc", "<cmd>CodeCompanionChat toggle<CR>", { desc = "Toggle CodeCompanion" })
    end,
  },

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = fzf_make_cmd }, -- Fzf native
      "nvim-telescope/telescope-live-grep-args.nvim",
    },
  },

  -- Harpoon
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      local harpoon = require("harpoon")
      harpoon:setup()
    end,
    keys = {
      {
        "<M-j>",
        function()
          local harpoon = require("harpoon")
          harpoon:list():append()
        end,
        desc = "Add file to harpoon",
      },
      {
        "<M-k>",
        function()
          local harpoon = require("harpoon")
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = "Toggle harpoon menu",
      },
      {
        "<M-1>",
        function()
          local harpoon = require("harpoon")
          harpoon:list():select(1)
        end,
        desc = "Jump to harpoon location 1",
      },
      {
        "<M-2>",
        function()
          local harpoon = require("harpoon")
          harpoon:list():select(2)
        end,
        desc = "Jump to harpoon location 2",
      },
      {
        "<M-3>",
        function()
          local harpoon = require("harpoon")
          harpoon:list():select(3)
        end,
        desc = "Jump to harpoon location 3",
      },
      {
        "<M-4>",
        function()
          local harpoon = require("harpoon")
          harpoon:list():select(4)
        end,
        desc = "Jump to harpoon location 4",
      },
      {
        "<M-[>",
        function()
          local harpoon = require("harpoon")
          harpoon:list():prev()
        end,
        desc = "Previous harpoon location",
      },
      {
        "<M-]>",
        function()
          local harpoon = require("harpoon")
          harpoon:list():next()
        end,
        desc = "Next harpoon location",
      },
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
      which_key.add({
        mode = { "n", "o", "x" },
        { ";", ts_repeat_move.repeat_last_move_next, desc = "move next" },
        { ",", ts_repeat_move.repeat_last_move_previous, desc = "move previous" },
        { "f", ts_repeat_move.builtin_f, desc = "move forward" },
        { "F", ts_repeat_move.builtin_F, desc = "move backward" },
        { "t", ts_repeat_move.builtin_t, desc = "move to" },
        { "T", ts_repeat_move.builtin_T, desc = "move to before" },
      })
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
      default_file_explorer = true,
      skip_confirm_for_simple_edits = true,
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
        ["gx"] = function()
          local oil = require("oil")
          local cwd = oil.get_current_dir()
          local entry = oil.get_cursor_entry()
          if cwd and entry then
            vim.fn.jobstart({ "open", string.format("%s/%s", cwd, entry.name) })
          end
        end,
        ["gD"] = function()
          local oil = require("oil")
          local cwd = oil.get_current_dir()
          local entry = oil.get_cursor_entry()
          if cwd and entry then
            vim.fn.jobstart({ "open", "-R", string.format("%s/%s", cwd, entry.name) })
          end
        end,
      },
      view_options = {
        is_hidden_file = function(name, _)
          return (vim.startswith(name, ".") or vim.endswith(name, "_templ.go") or vim.endswith(name, "_templ.txt"))
        end,
      },
    },
    config = function(_, opts)
      require("oil").setup(opts)
      local which_key_status, which_key = pcall(require, "which-key")
      if not which_key_status then
        return
      end

      which_key.add({
        { "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
      })
    end,
    -- Optional dependencies
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },

  {
    "echasnovski/mini.files",
    version = false,
    config = {
      mappings = {
        go_in_plus = "<CR>",
        go_out_plus = "-",
      },
    },
    keys = {
      {
        "<leader>e",
        function()
          local MiniFiles = require("mini.files")
          MiniFiles.open(vim.api.nvim_buf_get_name(0))
        end,
        desc = "Toggle file viewer",
      },
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
      local ai_indent = function(ai_type)
        local spaces = (" "):rep(vim.o.tabstop)
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local indents = {} ---@type {line: number, indent: number, text: string}[]

        for l, line in ipairs(lines) do
          if not line:find("^%s*$") then
            indents[#indents + 1] = { line = l, indent = #line:gsub("\t", spaces):match("^%s*"), text = line }
          end
        end

        local ret = {} ---@type (Mini.ai.region | {indent: number})[]

        for i = 1, #indents do
          if i == 1 or indents[i - 1].indent < indents[i].indent then
            local from, to = i, i
            for j = i + 1, #indents do
              if indents[j].indent < indents[i].indent then
                break
              end
              to = j
            end
            from = ai_type == "a" and from > 1 and from - 1 or from
            to = ai_type == "a" and to < #indents and to + 1 or to
            ret[#ret + 1] = {
              indent = indents[i].indent,
              from = { line = indents[from].line, col = ai_type == "a" and 1 or indents[from].indent + 1 },
              to = { line = indents[to].line, col = #indents[to].text },
            }
          end
        end

        return ret
      end

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
          u = ai.gen_spec.function_call(), -- u for "Usage"
          U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }), -- without dot in function name
          i = ai_indent,
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
        { "i ", desc = "Whitespace" },
        { 'i"', desc = 'Balanced "' },
        { "i'", desc = "Balanced '" },
        { "i`", desc = "Balanced `" },
        { "i(", desc = "Balanced (" },
        { "i)", desc = "Balanced ) including white-space" },
        { "i>", desc = "Balanced > including white-space" },
        { "i<lt>", desc = "Balanced <" },
        { "i]", desc = "Balanced ] including white-space" },
        { "i[", desc = "Balanced [" },
        { "i}", desc = "Balanced } including white-space" },
        { "i{", desc = "Balanced {" },
        { "i?", desc = "User Prompt" },
        { "i_", desc = "Underscore" },
        { "ia", desc = "Argument" },
        { "ib", desc = "Balanced ), ], }" },
        { "ic", desc = "Class" },
        { "if", desc = "Function" },
        { "io", desc = "Block, conditional, loop" },
        { "iq", desc = "Quote `, \", '" },
        { "it", desc = "Tag" },
      }
      local a = {
        { "a ", desc = "Whitespace" },
        { 'a"', desc = 'Balanced "' },
        { "a'", desc = "Balanced '" },
        { "a`", desc = "Balanced `" },
        { "a(", desc = "Balanced (" },
        { "a)", desc = "Balanced )" },
        { "a>", desc = "Balanced >" },
        { "a<lt>", desc = "Balanced <" },
        { "a]", desc = "Balanced ]" },
        { "a[", desc = "Balanced [" },
        { "a}", desc = "Balanced }" },
        { "a{", desc = "Balanced {" },
        { "a?", desc = "User Prompt" },
        { "a_", desc = "Underscore" },
        { "aa", desc = "Argument" },
        { "ab", desc = "Balanced ), ], }" },
        { "ac", desc = "Class" },
        { "af", desc = "Function" },
        { "ao", desc = "Block, conditional, loop" },
        { "aq", desc = "Quote `, \", '" },
        { "at", desc = "Tag" },
      }

      local function insertPrefixAfterFirstChar(originalTable, prefix)
        local newTable = {}
        for _, entry in ipairs(originalTable) do
          local oldKey = entry[1]
          local newKey = oldKey:sub(1, 1) .. prefix .. oldKey:sub(2)
          table.insert(newTable, { newKey, desc = entry.desc })
        end
        return newTable
      end

      local ic = insertPrefixAfterFirstChar(i, "n")
      local ac = insertPrefixAfterFirstChar(a, "n")

      which_key.add({
        mode = { "o", "x" },
        i,
        a,
        ic,
        ac,
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
  {
    "j-hui/fidget.nvim",
    opts = {
      progress = {
        ignore = {
          "null-ls",
        },
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
      "nvimtools/none-ls-extras.nvim",
    },
    config = function()
      require("user.lsp.null-ls")
    end,
  },

  -- Git custom commands
  {
    dir = "./git",
    virtual = true,
    event = { "BufReadPost" },
    config = function()
      require("user.git.config").setup()
    end,
    keys = {
      { "gr", vim.cmd.GitOpenFileOnRemote, desc = "Open selection on remote" },
      { "gR", vim.cmd.GitOpenLineOnRemote, desc = "Open commit on remote" },
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
    event = { "LspAttach" },
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
  {
    "folke/which-key.nvim",
    opts = {
      preset = "helix",
    },
  },

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
    opts = {
      auto_refresh = false,
    },
    cmd = { "Trouble" },
    keys = {
      { "gf", "<cmd>Trouble lsp_references toggle focus=false<cr>", desc = "LSP references" },
      { "<leader>xt", "<cmd>Trouble close<cr>", desc = "Close (Trouble)" },
      { "<leader>xx", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Document Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle<cr>", desc = "Workspace Diagnostics (Trouble)" },
      { "<leader>xl", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
      {
        "[q",
        function()
          if require("trouble").is_open() then
            require("trouble").prev({ skip_groups = true, jump = true })
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

  -- Leap
  {
    "ggandor/leap.nvim",
    keys = {
      { "s", mode = { "n", "x", "o" }, desc = "Leap Forward to" },
      { "S", mode = { "n", "x", "o" }, desc = "Leap Backward to" },
      { "gs", mode = { "n", "x", "o" }, desc = "Leap from Windows" },
    },
    config = function(_, opts)
      local leap = require("leap")
      for k, v in pairs(opts) do
        leap.opts[k] = v
      end
      leap.add_default_mappings(true)
      vim.keymap.del({ "x", "o" }, "x")
      vim.keymap.del({ "x", "o" }, "X")
      vim.keymap.del({ "n", "x" }, "s")
      vim.keymap.set("n", "s", function()
        leap.leap({ target_windows = { vim.api.nvim_get_current_win() } })
      end)
    end,
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
