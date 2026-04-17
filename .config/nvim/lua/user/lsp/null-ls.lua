local setup, null_ls = pcall(require, "null-ls")
if not setup then
  return
end

null_ls.setup({
  sources = {
    null_ls.builtins.code_actions.gomodifytags,
  },
})
