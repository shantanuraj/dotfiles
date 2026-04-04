local M = {
  ensure_installed = {
    "astro",
    "bash",
    "css",
    "go",
    "gomod",
    "html",
    "javascript",
    "jsdoc",
    "json",
    "rust",
    "svelte",
    "swift",
    "toml",
    "tsx",
    "typescript",
    "yaml",
  },

  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },

  indent = { enable = true },

  autotag = { enable = true },

  textobjects = {
    move = {
      enable = true,
      set_jumps = true,
      goto_next_start = {
        ["]m"] = "@function.outer",
        -- ["]]"] = "@class.outer",
        ["]o"] = {
          query = {
            "@block.inner",
            "@conditional.inner",
            "@loop.inner",
          },
          desc = "Next block, conditional or loop",
        },
        ["]O"] = {
          query = {
            "@block.outer",
            "@conditional.outer",
            "@loop.outer",
          },
          desc = "Next block, conditional or loop (outer)",
        },
        ["]s"] = {
          query = "@scope",
          query_group = "locals",
          desc = "Next scope",
        },
      },
      goto_next_end = {
        ["]M"] = "@function.outer",
        ["]["] = "@class.outer",
      },
      goto_previous_start = {
        ["[m"] = "@function.outer",
        -- ["[["] = "@class.outer",
        ["[o"] = {
          query = {
            "@block.inner",
            "@conditional.inner",
            "@loop.inner",
          },
          desc = "Previous block, conditional or loop",
        },
        ["[O"] = {
          query = {
            "@block.outer",
            "@conditional.outer",
            "@loop.outer",
          },
          desc = "Previous block, conditional or loop (outer)",
        },
        ["[s"] = {
          query = "@scope",
          query_group = "locals",
          desc = "Previous scope",
        },
      },
      goto_previous_end = {
        ["[M"] = "@function.outer",
        ["[]"] = "@class.outer",
      },
      goto_next = {
        ["]a"] = "@parameter.inner",
      },
      goto_previous = {
        ["[a"] = "@parameter.inner",
      },
    },
    select = {
      enable = true,
      keymaps = {
        ["as"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },
      },
    },
  },
}

return M
