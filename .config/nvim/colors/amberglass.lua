-- Built on Zenbones' highlight generator and Lush (loaded by lazy.nvim).
vim.opt.background = "dark"
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.g.colors_name = "amberglass"
require("user.amberglass").apply()
