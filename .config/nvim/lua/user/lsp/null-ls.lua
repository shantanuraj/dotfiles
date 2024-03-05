-- import null-ls plugin safely
local setup, null_ls = pcall(require, "null-ls")
if not setup then
  return
end

-- import mason-null-ls plugin safely
local mason_null_ls_status, mason_null_ls = pcall(require, "mason-null-ls")
if not mason_null_ls_status then
  return
end

mason_null_ls.setup({
  -- list of formatters & linters for mason to install
  ensure_installed = {
    "eslint_d", -- ts/js linter
    "goimports", -- go formatter
    "golines", -- go formatter
    "gomodifytags", -- go struct tag formatter
    "prettierd", -- ts/js formatter
    "stylua", -- lua formatter
  },
  -- auto-install configured formatters & linters (with null-ls)
  automatic_installation = true,
})

-- for conciseness
local formatting = null_ls.builtins.formatting -- to setup formatters
local codeactions = null_ls.builtins.code_actions -- to setup code actions
local eslint_d = require("none-ls.diagnostics.eslint_d") -- from nvimtools/none-ls-extras.nvim

-- to setup format on save
local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

-- configure null_ls
null_ls.setup({
  -- setup formatters & linters
  sources = {
    formatting.prettierd.with({
      extra_filetypes = { "astro", "svelte" }, -- use prettier for astro, svelte
    }),
    formatting.stylua, -- lua formatter
    formatting.goimports, -- go formatter
    formatting.golines, -- go formatter
    codeactions.gomodifytags, -- go struct tag formatter
    eslint_d.with({ -- js/ts linter
      -- only enable eslint if root has .eslintrc.js (not in youtube nvim video)
      condition = function(utils)
        return utils.root_has_file(".eslintrc.js") or utils.root_has_file(".eslintrc.json")
      end,
    }),
  },
  -- configure format on save
  on_attach = function(current_client, bufnr)
    if current_client.supports_method("textDocument/formatting") then
      vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup,
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format({
            filter = function(client)
              --  only use null-ls for formatting instead of lsp server
              return client.name == "null-ls"
            end,
            bufnr = bufnr,
          })
        end,
      })
    end
  end,
})
