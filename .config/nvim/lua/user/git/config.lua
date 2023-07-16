local cmd = require("user.git.cmd")

local M = {}

M.setup = function()
  vim.api.nvim_create_user_command(
    "GitOpenFileOnRemote",
    cmd.open_file_on_remote,
    { nargs = 0, desc = "Open file on remote" }
  )
  vim.api.nvim_create_user_command(
    "GitOpenLineOnRemote",
    cmd.open_line_sha_on_remote,
    { nargs = 0, desc = "Open line on remote" }
  )
end

return M
