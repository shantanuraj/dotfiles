local trouble = require("trouble.providers.telescope")

-- Telescope config
require("telescope").setup({
  defaults = {
    file_ignore_patterns = {
      ".git/worktrees",
      ".git/COMMIT_EDITMSG",
    },
    mappings = {
      i = { ["<C-t>"] = trouble.open_with_trouble },
      n = { ["<C-t>"] = trouble.open_with_trouble },
    },
  },
  extensions = {
    fzf = {
      fuzzy = true, -- false will only do exact matching
      override_generic_sorter = true, -- override the generic sorter
      override_file_sorter = true, -- override the file sorter
      case_mode = "smart_case", -- or "ignore_case" or "respect_case"
    },
    live_grep_args = {
      auto_quoting = false,
    },
  },
  pickers = {
    live_grep = {
      additional_args = function()
        return { "--hidden", "--glob", "!**/.git/*" }
      end,
      theme = "ivy",
    },
  },
})

require("telescope").load_extension("fzf")
require("telescope").load_extension("live_grep_args")

local M = {}

M.project_files = function()
  local opts = require("telescope.themes").get_ivy({})
  opts.find_command = { "rg", "--files", "--hidden", "--follow", "--glob", "!.git/*" }
  vim.fn.system("git rev-parse --is-inside-work-tree")
  if vim.v.shell_error == 0 then
    require("telescope.builtin").git_files(opts)
  else
    opts.hidden = true
    require("telescope.builtin").find_files(opts)
  end
end

-- Keymaps
local which_key = require("which-key")

which_key.register({
  ["<C-f>"] = {
    function()
      require("telescope.builtin").live_grep()
    end,
    "Find in project",
  },
  ["<M-f>"] = {
    function()
      require("telescope.builtin").live_grep({ search_dirs = { vim.fn.expand("%:p") } })
    end,
    "Find in current file",
  },
  ["<leader>"] = {
    ["<space>"] = { M.project_files, "Go to File" },
    ["'"] = {
      function()
        require("telescope.builtin").resume({ initial_mode = "normal" })
      end,
      "Resume last search",
    },
    ["f"] = {
      name = "+Find",
      C = { "<cmd>Telescope commands theme=get_dropdown<cr>", "Find command" },
      d = { "<cmd>Telescope diagnostics theme=get_dropdown<cr>", "Go to diagnostic" },
      h = { "<cmd>Telescope help_tags theme=get_dropdown<cr>", "Find help" },
      m = { "<cmd>Telescope marks theme=get_dropdown<cr>", "Go to Mark" },
      R = { "<cmd>Telescope registers theme=get_dropdown<cr>", "Find registers" },
      r = { "<cmd>Telescope oldfiles only_cwd=true<cr>", "Find recent files" },
      t = { "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", "Go to Symbol in workspace" },
      T = { require("telescope.builtin").builtin, "Telescope" },
      b = { "<cmd>Telescope buffers<cr>", "Go to Buffer" },
      f = {
        function()
          require("telescope").extensions.live_grep_args.live_grep_args()
        end,
        "Live grep",
      },
      g = {
        function()
          require("telescope").extensions.live_grep_args.live_grep_args({
            default_text = "--glob !{*.json,*.po,.git} ",
          })
        end,
        "Find excluding translations",
      },
      w = {
        function()
          require("telescope-live-grep-args.shortcuts").grep_word_under_cursor({
            postfix = " -F --hidden --glob !**/.git/* ",
          })
        end,
        "Find word",
      },
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
