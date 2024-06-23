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
  -- import lspconfig plugin safely
  local lspconfig_status, lspconfig = pcall(require, "lspconfig")
  if not lspconfig_status then
    return
  end

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
    which_key.register({
      ["g"] = {
        name = "+Go to",
        D = { "<Cmd>Lspsaga goto_definition<CR>", "Declaration" },
        d = { "<cmd>Lspsaga peek_definition<CR>", "Peek Definition" },
        i = { vim.lsp.buf.implementation, "Implementation" },
      },
      ["<leader>"] = {
        ["D"] = { "<cmd>Lspsaga show_cursor_diagnostics<CR>", "Show Diagnostics" },
        ["d"] = { "<cmd>Lspsaga show_line_diagnostics<CR>", "Show Line Diagnostics" },
        ["o"] = { "<cmd>Lspsaga outline<CR>", "Outline" },
        ["l"] = {
          function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
          end,
          "Toggle LSP inlay hints",
        },
        ["r"] = {
          name = "+Refactor",
          ["r"] = { "<cmd>Lspsaga rename ++project<CR>", "Rename" },
        },
      },
      ["K"] = { "<cmd>Lspsaga hover_doc<CR>", "Hover Doc" },
      ["<c-k>"] = { vim.lsp.buf.signature_help, "Signature Documentation" },
    }, { buffer = bufnr })

    which_key.register({
      ["r"] = {
        name = "+Refactor",
        ["a"] = { "<cmd>Lspsaga code_action<CR>", "Code Action" },
      },
    }, { buffer = bufnr, mode = { "n", "o", "x" } })
  end

  -- typescript specific keymaps (e.g. rename file and update imports)
  local function on_attach_ts(client, bufnr)
    on_attach(client, bufnr)

    which_key.register({
      ["r"] = {
        ["f"] = { vim.cmd.TypescriptRenameFile, "Rename File" },
        ["i"] = {
          function()
            lsp.action["source.addMissingImports.ts"]()
            lsp.action["source.organizeImports"]()
          end,
          "Organize Imports",
        },
        ["u"] = {
          function()
            lsp.action["source.removeUnused.ts"]()
          end,
          "Remove Unused",
        },
        ["d"] = {
          function()
            lsp.action["source.addMissingImports.ts"]()
            lsp.action["source.organizeImports"]()
            lsp.action["source.removeUnused.ts"]()
            lsp.action["source.fixAll.ts"]()
          end,
          "Fix all",
        },
      },
    }, { buffer = bufnr, prefix = "<leader>" })
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
  lspconfig["cssls"].setup({
    capabilities = capabilities,
    on_attach = on_attach,
  })

  -- configure emmet language server
  lspconfig["emmet_ls"].setup({
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

  -- configure astro server
  lspconfig["astro"].setup({
    capabilities = capabilities,
    on_attach = on_attach,
  })

  -- configure gopls server
  lspconfig["gopls"].setup({
    capabilities = capabilities,
    on_attach = on_attach,
  })

  -- configure html server
  lspconfig["html"].setup({
    capabilities = capabilities,
    on_attach = on_attach,
  })

  -- configure markdown server
  lspconfig["marksman"].setup({
    capabilities = capabilities,
    on_attach = on_attach,
  })

  -- configure rust server
  lspconfig["rust_analyzer"].setup({
    capabilities = capabilities,
    on_attach = on_attach,
  })

  -- configure svelte server
  lspconfig["svelte"].setup({
    capabilities = capabilities,
    on_attach = on_attach,
  })

  -- configure lua server (with special settings)
  lspconfig["lua_ls"].setup({
    capabilities = capabilities,
    on_attach = on_attach,
    settings = { -- custom settings for lua
      Lua = {
        -- make the language server recognize "vim" global
        diagnostics = {
          globals = { "vim" },
        },
        workspace = {
          -- make language server aware of runtime files
          library = {
            [vim.fn.expand("$VIMRUNTIME/lua")] = true,
            [vim.fn.stdpath("config") .. "/lua"] = true,
          },
        },
      },
    },
  })

  -- configure tailwindcss server
  lspconfig["tailwindcss"].setup({
    capabilities = capabilities,
    on_attach = on_attach,
  })

  -- configure zls server
  lspconfig["zls"].setup({
    capabilities = capabilities,
    on_attach = on_attach,
  })

  -- configure templ language server
  lspconfig["templ"].setup({
    capabilities = capabilities,
    on_attach = on_attach,
  })

  -- configure typescript server with plugin
  lspconfig["vtsls"].setup({
    capabilities = capabilities,
    on_attach = on_attach_ts,
    server = {
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
    },
  })

  -- configure mason lspconfig plugin
  mason_lspconfig.setup({
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
