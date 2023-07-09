local utils = require("user.git.utils")
local git = require("user.git.git")

local M = {}

M.open_file_on_remote = function()
  local filepath = utils.get_filepath()
  if not filepath then
    return
  end

  git.get_sha(git.open_blob_in_browser)
end

M.open_line_sha_on_remote = function()
  local filepath = utils.get_filepath()
  if not filepath then
    return
  end

  git.get_line_sha(git.open_blob_in_browser)
end

return M
