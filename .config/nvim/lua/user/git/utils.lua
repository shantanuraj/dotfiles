local M = {}

function __FILE__()
  return debug.getinfo(3, "S").source
end
function __LINE__()
  return debug.getinfo(3, "l").currentline
end
function __FUNC__()
  return debug.getinfo(3, "n").name
end

local function dump(o)
  if type(o) == "table" then
    local s = "{ "
    for k, v in pairs(o) do
      if type(k) ~= "number" then
        k = '"' .. k .. '"'
      end
      s = s .. "[" .. k .. "] = " .. dump(v) .. ","
    end
    return s .. "} "
  else
    return tostring(o)
  end
end

function M.log(text)
  print(string.format("[%s][%s-%s] %s", os.clock(), __FUNC__(), __LINE__(), dump(text)))
end

---@param cmd string
---@param opts table
---@return number | 'the job id'
function M.start_job(cmd, opts)
  opts = opts or {}
  local id = vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data, _)
      if data and opts.on_stdout then
        opts.on_stdout(data)
      end
    end,
    on_exit = function(_, data, _)
      if opts.on_exit then
        opts.on_exit(data)
      end
    end,
  })

  if opts.input then
    vim.fn.chansend(id, opts.input)
    vim.fn.chanclose(id, "stdin")
  end

  return id
end

---@return string|nil
function M.get_filepath()
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath == "" then
    return nil
  end
  if filepath:match("^term://") then
    return nil
  end
  return filepath
end

---@return number
function M.get_line_number()
  return vim.api.nvim_win_get_cursor(0)[1]
end

-- Returns the starting and ending line numbers of the current visual selection
-- or nil if no visual selection is active.
-- @return {start: number, end: number}
function M.get_visual_selection()
  local mode = vim.api.nvim_get_mode().mode
  if mode == "v" or mode == "V" then
    local visual_pos = vim.fn.getpos("v")[2]
    local cursor_pos = vim.fn.getcurpos()[2]
    local start_line = math.min(visual_pos, cursor_pos)
    local end_line = math.max(visual_pos, cursor_pos)
    return { start = start_line, ["end"] = end_line }
  end
  local line_number = M.get_line_number()
  return { start = line_number, ["end"] = line_number }
end

---Merges map entries of `source` into `target`.
---@param source table<any, any>
---@param target table<any, any>
function M.merge_map(source, target)
  for k, v in pairs(source) do
    target[k] = v
  end
end

---Keeping it outside the function improves performance by not
---finding the OS every time.
local open_cmd
---Attempts to open a given URL in the system default browser, regardless of the OS.
---Source: https://stackoverflow.com/a/18864453/9714875
---@param url string
function M.launch_url(url)
  if not open_cmd then
    if package.config:sub(1, 1) == "\\" then
      open_cmd = function(_url)
        M.start_job(string.format('rundll32 url.dll,FileProtocolHandler "%s"', _url), {})
      end
    elseif (io.popen("uname -s"):read("*a")):match("Darwin") then
      open_cmd = function(_url)
        M.start_job(string.format('open "%s"', _url), {})
      end
    else
      open_cmd = function(_url)
        M.start_job(string.format('xdg-open "%s"', _url), {})
      end
    end
  end

  open_cmd(url)
end

---@param text string
function M.copy_to_clipboard(text)
  vim.fn.setreg("+", text)
end

--- Replace pattern with given replacement in text
--- Handles hyphens and special characters unlike string.gsub
---@param text string
---@param pattern string
---@param replacement string
---@return string
function M.gsub(text, pattern, replacement)
  local escaped_pattern = pattern:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
  local res = text:gsub(escaped_pattern, replacement)
  return res
end

--- Return the string separted by space
--- @param str string
--- @return table
--- @usage split("a b c") => {"a", "b", "c"}
function M.split_space(str)
  local res = {}
  for word in str:gmatch("%S+") do
    table.insert(res, word)
  end
  return res
end

return M
