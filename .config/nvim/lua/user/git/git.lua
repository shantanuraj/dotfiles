local utils = require("user.git.utils")
local M = {}

local function current_file_dir()
  local filepath = utils.get_filepath()
  if not filepath then
    return nil
  end

  return vim.fn.fnamemodify(filepath, ":h")
end

---@param callback fun(is_ignored: boolean)
function M.check_is_ignored(callback)
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath == "" then
    return true
  end

  utils.start_job({ "git", "check-ignore", filepath }, {
    cwd = current_file_dir(),
    on_exit = function(code)
      callback(code == 0)
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
---@param custom_lines {start: number, end: number}|nil
function M.open_blob_in_browser(sha, custom_filepath, custom_lines)
  M.get_remote_url(function(remote_url)
    local function open_filepath_at_blob(filepath)
      local lines = custom_lines or utils.get_visual_selection()
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
  local cwd = current_file_dir()
  if not cwd then
    return
  end

  utils.start_job({ "git", "config", "--get", "remote.origin.url" }, {
    cwd = cwd,
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
  local cwd = current_file_dir()
  if not cwd then
    return
  end

  utils.start_job({ "git", "rev-parse", "--show-toplevel" }, {
    cwd = cwd,
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
  local cwd = current_file_dir()
  if not cwd then
    return
  end

  utils.start_job({ "git", "rev-parse", "HEAD" }, {
    cwd = cwd,
    on_stdout = function(data)
      callback(data[1])
    end,
  })
end

---@param callback fun(sha: string, filepath: string, lines: {start: number, end: number})
function M.get_line_sha(callback)
  local filepath = utils.get_filepath()
  local cwd = current_file_dir()
  if not filepath or not cwd then
    return
  end

  local line = tostring(vim.fn.line("."))
  utils.start_job({ "git", "blame", "--line-porcelain", "-L", line .. ",+1", "--", filepath }, {
    cwd = cwd,
    on_stdout = function(data)
      local sha, line_start = data[1]:match("^(%S+)%s+(%d+)")
      if not sha or not line_start then
        return
      end

      local blamed_filepath
      for _, output_line in ipairs(data) do
        blamed_filepath = output_line:match("^filename%s+(.+)$")
        if blamed_filepath then
          break
        end
      end

      if not blamed_filepath then
        return
      end

      local lines = { start = tonumber(line_start), ["end"] = tonumber(line_start) }
      callback(sha, blamed_filepath, lines)
    end,
  })
end

return M
