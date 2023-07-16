local utils = require("user.git.utils")
local M = {}

---@param callback fun(is_ignored: boolean)
function M.check_is_ignored(callback)
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath == "" then
    return true
  end

  utils.start_job("git check-ignore " .. vim.fn.shellescape(filepath), {
    on_exit = function(data)
      callback(data ~= 1)
    end,
  })
end

---@param sha string
---@param remote_url string
---@param filepath string|nil
---@param lines {start: number, end: number}
---@return string
function M.get_blob_url(sha, remote_url, filepath, lines)
  local blob_path = "/blob/" .. sha .. "/" .. (filepath or "") .. "#L" .. lines.start .. "-L" .. lines["end"]

  local domain, path = string.match(remote_url, ".*git%@(.*)%:(.*)%.git")
  if domain and path then
    return "https://" .. domain .. "/" .. path .. blob_path
  end

  local url = string.match(remote_url, ".*git%@(.*)%.git")
  if url then
    return "https://" .. url .. blob_path
  end

  local https_url = string.match(remote_url, "(https%:%/%/.*)%.git")
  if https_url then
    return https_url .. blob_path
  end

  return remote_url .. blob_path
end

---@param sha string
---@param custom_filepath string|nil
function M.open_blob_in_browser(sha, custom_filepath)
  M.get_remote_url(function(remote_url)
    local function open_filepath_at_blob(filepath)
      local lines = utils.get_visual_selection()
      local blob_url = M.get_blob_url(sha, remote_url, filepath, lines)
      utils.launch_url(blob_url)
    end
    if custom_filepath then
      open_filepath_at_blob(custom_filepath)
      return
    end
    M.get_relative_filepath(open_filepath_at_blob)
  end)
end

---@param callback fun(url: string)
function M.get_remote_url(callback)
  if not utils.get_filepath() then
    return
  end
  local remote_url_command = "cd "
    .. vim.fn.shellescape(vim.fn.expand("%:p:h"))
    .. " && git config --get remote.origin.url"

  utils.start_job(remote_url_command, {
    on_stdout = function(url)
      if url and url[1] then
        callback(url[1])
      else
        callback("")
      end
    end,
  })
end

---@param callback fun(repo_root: string)
function M.get_repo_root(callback)
  if not utils.get_filepath() then
    return
  end
  local command = "cd " .. vim.fn.shellescape(vim.fn.expand("%:p:h")) .. " && git rev-parse --show-toplevel"

  utils.start_job(command, {
    on_stdout = function(data)
      callback(data[1])
    end,
  })
end

---@param callback fun(filepath: string)
function M.get_relative_filepath(callback)
  local filepath = utils.get_filepath()
  if not filepath then
    return
  end
  M.get_repo_root(function(repo_root)
    local relative_filepath = utils.gsub(filepath, repo_root .. "/", "")
    callback(relative_filepath)
  end)
end

---@param callback fun(sha: string)
function M.get_sha(callback)
  utils.start_job("git rev-parse HEAD", {
    on_stdout = function(data)
      callback(data[1])
    end,
  })
end

---@param callback fun(sha: string, filepath: string)
function M.get_line_sha(callback)
  local line = vim.fn.line(".")
  utils.start_job(
    "git log -L " .. line .. ",+1" .. ":" .. vim.fn.expand("%:p") .. " --pretty=format:'%H' --max-count=1",
    {
      on_stdout = function(data)
        local sha = data[1]
        local filepath = utils.gsub(data[4], "+++ b/", "")
        callback(sha, filepath)
      end,
    }
  )
end

return M
