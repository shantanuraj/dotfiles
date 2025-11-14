local lsp = {
  ---@class LspCommand: lsp.ExecuteCommandParams
  ---@param opts LspCommand
  execute = function(opts)
    local params = {
      command = opts.command,
      arguments = opts.arguments,
    }
    if opts.open then
      require("trouble").open({
        mode = "lsp_command",
        params = params,
      })
    else
      return vim.lsp.buf_request(0, "workspace/executeCommand", params, opts.handler)
    end
  end,

  action = setmetatable({}, {
    __index = function(_, action)
      return function()
        vim.lsp.buf.code_action({
          apply = true,
          context = {
            only = { action },
            diagnostics = {},
          },
        })
      end
    end,
  }),
}

return function(_, _)
  -- import cmp-nvim-lsp plugin safely
  local cmp_nvim_lsp_status, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
  if not cmp_nvim_lsp_status then
    return
  end

  -- import mason-lspconfig plugin safely
  local mason_lspconfig_status, mason_lspconfig = pcall(require, "mason-lspconfig")
  if not mason_lspconfig_status then
    return
  end

  local which_key = require("which-key")

  -- enable keybinds only for when lsp server available
  local on_attach = function(_, bufnr)
    -- set keybinds
    which_key.add({
      buffer = bufnr,
      {
        group = "+Go to",
        { "gD", "<Cmd>Lspsaga goto_definition<CR>", desc = "Declaration" },
        { "gd", "<cmd>Lspsaga peek_definition<CR>", desc = "Peek Definition" },
        { "gi", vim.lsp.buf.implementation, desc = "Implementation" },
      },
      {
        { "<leader>D", "<cmd>Lspsaga show_cursor_diagnostics<CR>", desc = "Show Diagnostics" },
        { "<leader>d", "<cmd>Lspsaga show_line_diagnostics<CR>", desc = "Show Line Diagnostics" },
        { "<leader>o", "<cmd>Lspsaga outline<CR>", desc = "Outline" },
        {
          "<leader>l",
          function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
          end,
          desc = "Toggle LSP inlay hints",
        },
        {
          group = "Refactor",
          { "<leader>rr", "<cmd>Lspsaga rename ++project<CR>", desc = "Rename" },
          { "<leader>ra", "<cmd>Lspsaga code_action<CR>", desc = "Code Action", mode = { "n", "o", "x" } },
        },
      },
      { "K", "<cmd>Lspsaga hover_doc<CR>", desc = "Hover Doc" },
      { "<c-k>", vim.lsp.buf.signature_help, desc = "Signature Documentation" },
      {
        "<leader>=",
        function()
          vim.lsp.buf.format({
            filter = function(client)
              return client.name == "null-ls" or client.name == "rust_analyzer"
            end,
            bufnr = bufnr,
          })
        end,
        desc = "Format file LSP",
      },
    })
  end

  -- typescript specific keymaps (e.g. rename file and update imports)
  local function on_attach_ts(client, bufnr)
    on_attach(client, bufnr)

    which_key.add({
      buffer = bufnr,
      {
        { "<leader>rf", vim.cmd.TypescriptRenameFile, desc = "Rename File" },
        {
          "<leader>ri",
          function()
            lsp.action["source.addMissingImports.ts"]()
            lsp.action["source.organizeImports"]()
          end,
          desc = "Organize Imports",
        },
        {
          "<leader>ru",
          function()
            lsp.action["source.removeUnused.ts"]()
          end,
          desc = "Remove Unused",
        },
        {
          "<leader>rd",
          function()
            lsp.action["source.addMissingImports.ts"]()
            lsp.action["source.organizeImports"]()
            lsp.action["source.removeUnused.ts"]()
            lsp.action["source.fixAll.ts"]()
          end,
          desc = "Fix all",
        },
      },
    })
  end

  -- used to enable autocompletion (assign to every lsp server config)
  local capabilities = cmp_nvim_lsp.default_capabilities()

  -- Change the Diagnostic symbols in the sign column (gutter)
  -- (not in youtube nvim video)
  local signs = { Error = " ", Warn = " ", Hint = "ﴞ ", Info = " " }
  for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
  end

  -- configure css server
  vim.lsp.config("cssls", {
    capabilities = capabilities,
    on_attach = on_attach,
  })
  vim.lsp.enable("cssls")

  -- configure emmet language server
  vim.lsp.config("emmet_ls", {
    capabilities = capabilities,
    on_attach = on_attach,
    filetypes = {
      "astro",
      "html",
      "typescriptreact",
      "javascriptreact",
      "css",
      "sass",
      "scss",
      "less",
      "svelte",
    },
  })
  vim.lsp.enable("emmet_ls")

  -- configure astro server
  vim.lsp.config("astro", {
    capabilities = capabilities,
    on_attach = on_attach,
  })
  vim.lsp.enable("astro")

  -- configure gopls server
  vim.lsp.config("gopls", {
    capabilities = capabilities,
    on_attach = on_attach,
  })
  vim.lsp.enable("gopls")

  -- configure html server
  vim.lsp.config("html", {
    capabilities = capabilities,
    on_attach = on_attach,
  })
  vim.lsp.enable("html")

  -- configure markdown server
  vim.lsp.config("marksman", {
    capabilities = capabilities,
    on_attach = on_attach,
  })
  vim.lsp.enable("marksman")

  -- configure rust server
  vim.lsp.config("rust_analyzer", {
    capabilities = capabilities,
    on_attach = on_attach,
  })
  vim.lsp.enable("rust_analyzer")

  -- configure svelte server
  vim.lsp.config("svelte", {
    capabilities = capabilities,
    on_attach = on_attach,
  })
  vim.lsp.enable("svelte")

  -- configure lua server (with special settings)
  vim.lsp.config("lua_ls", {
    capabilities = capabilities,
    on_attach = on_attach,
    settings = { -- custom settings for lua
      Lua = {
        -- make the language server recognize "vim" global
        diagnostics = {
          globals = {
            "vim",
            "playdate",
            "import",
          },
        },
        workspace = {
          -- make language server aware of runtime files
          library = {
            [vim.fn.expand("$VIMRUNTIME/lua")] = true,
            [vim.fn.stdpath("config") .. "/lua"] = true,

            -- Playdate SDK
            [vim.fn.expand("$PLAYDATE_SDK") .. "/CoreLibs"] = true,
          },
        },
      },
    },
  })
  vim.lsp.enable("lua_ls")

  -- configure tailwindcss server
  vim.lsp.config("tailwindcss", {
    capabilities = capabilities,
    on_attach = on_attach,
  })
  vim.lsp.enable("tailwindcss")

  -- configure zls server
  vim.lsp.config("zls", {
    capabilities = capabilities,
    on_attach = on_attach,
  })
  vim.lsp.enable("zls")

  -- configure templ language server
  vim.lsp.config("templ", {
    capabilities = capabilities,
    on_attach = on_attach,
  })
  vim.lsp.enable("templ")

  -- configure typescript server with plugin
  vim.lsp.config("vtsls", {
    capabilities = capabilities,
    on_attach = on_attach_ts,
    settings = {
      complete_function_calls = true,
      vtsls = {
        enableMoveToFileCodeAction = true,
        autoUseWorkspaceTsdk = true,
        experimental = {
          completion = {
            enableServerSideFuzzyMatch = true,
          },
        },
      },
      typescript = {
        updateImportsOnFileMove = { enabled = "always" },
        suggest = {
          completeFunctionCalls = true,
        },
        inlayHints = {
          enumMemberValues = { enabled = true },
          functionLikeReturnTypes = { enabled = true },
          parameterNames = { enabled = "literals" },
          parameterTypes = { enabled = true },
          propertyDeclarationTypes = { enabled = true },
          variableTypes = { enabled = false },
        },
      },
    },
  })
  vim.lsp.enable("vtsls")

  -- configure mason lspconfig plugin
  mason_lspconfig.setup({
    automatic_enable = false,
    -- list of servers for mason to install
    ensure_installed = {
      "cssls",
      "emmet_ls",
      "gopls",
      "html",
      "marksman",
      "rust_analyzer",
      "svelte",
      "lua_ls",
      "tailwindcss",
      "templ",
      "vtsls",
    },
    -- auto-install configured servers (with lspconfig)
    automatic_installation = true, -- not the same as ensure_installed
  })
end
