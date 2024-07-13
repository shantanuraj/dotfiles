local trouble = require("trouble.sources.telescope")

-- Telescope config
require("telescope").setup({
  defaults = {
    file_ignore_patterns = {
      ".git/worktrees",
      ".git/COMMIT_EDITMSG",
    },
    mappings = {
      i = { ["<C-t>"] = trouble.open },
      n = { ["<C-t>"] = trouble.open },
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

which_key.add({
  {
    "<C-f>",
    function()
      require("telescope.builtin").live_grep()
    end,
    desc = "Find in project",
  },
  {
    "<M-f>",
    function()
      require("telescope.builtin").live_grep({ search_dirs = { vim.fn.expand("%:p") } })
    end,
    desc = "Find in current file",
  },
  {
    { "<leader><space>", M.project_files, desc = "Go to File", group = "leader" },
    {
      "<leader>'",
      function()
        require("telescope.builtin").resume({ initial_mode = "normal" })
      end,
      desc = "Resume last search",
    },
    {
      group = "Find",
      { "<leader>fC", "<cmd>Telescope commands theme=get_dropdown<cr>", desc = "Find command" },
      { "<leader>fd", "<cmd>Telescope diagnostics theme=get_dropdown<cr>", desc = "Go to diagnostic" },
      { "<leader>fh", "<cmd>Telescope help_tags theme=get_dropdown<cr>", desc = "Find help" },
      { "<leader>fm", "<cmd>Telescope marks theme=get_dropdown<cr>", desc = "Go to Mark" },
      { "<leader>fR", "<cmd>Telescope registers theme=get_dropdown<cr>", desc = "Find registers" },
      { "<leader>fr", "<cmd>Telescope oldfiles only_cwd=true<cr>", desc = "Find recent files" },
      { "<leader>ft", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", desc = "Go to Symbol in workspace" },
      { "<leader>fT", require("telescope.builtin").builtin, desc = "Telescope" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Go to Buffer" },
      {
        "<leader>ff",
        function()
          require("telescope").extensions.live_grep_args.live_grep_args()
        end,
        desc = "Live grep",
      },
      {
        "<leader>fg",
        function()
          require("telescope").extensions.live_grep_args.live_grep_args({
            default_text = "--glob !{*.json,*.po,.git} ",
          })
        end,
        desc = "Find excluding translations",
      },
      {
        "<leader>fw",
        function()
          require("telescope-live-grep-args.shortcuts").grep_word_under_cursor({
            postfix = " -F --hidden --glob !**/.git/* ",
          })
        end,
        desc = "Find word",
      },
      {
        "<leader>fp",
        function()
          require("telescope").extensions.live_grep_args.live_grep_args({
            prompt_title = "Find in directory",
            search_dirs = { vim.fn.expand("%:p:h") },
          })
        end,
        desc = "Find in directory",
      },
    },
    {
      group = "Git",
      { "<leader>gm", "<cmd>Telescope git_status<cr>", desc = "Go to Modified files" },
      { "<leader>gC", "<cmd>Telescope git_commits<cr>", desc = "Checkout commit" },
      { "<leader>gc", "<cmd>Telescope git_bcommits<cr>", desc = "Checkout commit [file]" },
      { "<leader>gb", "<cmd>Telescope git_branches<cr>", desc = "Checkout branch" },
      { "<leader>gs", "<cmd>Telescope git_stash<cr>", desc = "Pop Stash" },
    },
  },
})
