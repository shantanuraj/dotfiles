local M = {
  -- A list of parser names, or "all"
  ensure_installed = {
    "astro",
    "bash",
    "c",
    "cpp",
    "css",
    "dockerfile",
    "diff",
    "gitignore",
    "go",
    "gomod",
    "git_rebase",
    "html",
    "http",
    "java",
    "javascript",
    "jsdoc",
    "json",
    "json5",
    "jsonc",
    "kotlin",
    "latex",
    "make",
    "markdown",
    "markdown_inline",
    "python",
    "regex",
    "ruby",
    "rust",
    "sql",
    "scss",
    "svelte",
    "toml",
    "tsx",
    "typescript",
    "vim",
    "vue",
    "yaml",
  },

  -- allow incremental selection
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "<C-space>",
      node_incremental = "<C-space>",
      scope_incremental = "<nop>",
      node_decremental = "<bs>",
    },
  },

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  -- Automatically install missing parsers when entering buffer
  auto_install = true,

  -- enable syntax highlighting
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },

  -- enable indentation
  indent = { enable = true },

  -- enable autotagging (w/ nvim-ts-autotag plugin)
  autotag = { enable = true },
}

return M
