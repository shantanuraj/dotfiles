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
---@return string
function M.get_blob_url(sha, remote_url, filepath)
  local blob_path = "/blob/" .. sha .. "/" .. (filepath or "")

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
function M.open_blob_in_browser(sha)
  M.get_remote_url(function(remote_url)
    M.get_relative_filepath(function(filepath)
      local blob_url = M.get_blob_url(sha, remote_url, filepath)
      utils.launch_url(blob_url)
    end)
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
    local relative_filepath = string.gsub(filepath, repo_root .. "/", "")
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

return M
