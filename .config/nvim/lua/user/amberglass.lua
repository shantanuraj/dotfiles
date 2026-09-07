-- Amberglass: amber phosphor with restrained semantic accents.
local M = {}

M.palette = {
  bg = "#15120D",
  recessed = "#100E0A",
  raised = "#211B12",
  highlight = "#2C2316",
  selection = "#49351D",
  border = "#665031",
  muted = "#9B8055",
  fg = "#D9AA63",
  amber = "#EABC75",
  phosphor = "#FFD393",
  rose = "#D98267",
  leaf = "#A7AD79",
  wood = "#E8B461",
  water = "#A3A699",
  blossom = "#B49A79",
  sky = "#9FA889",
}

-- Keep these ANSI slots in sync with .wezterm.lua.
M.ansi = {
  "#211B12",
  "#D98267",
  "#A7AD79",
  "#E8B461",
  "#A3A699",
  "#B49A79",
  "#9FA889",
  "#D9AA63",
  "#9B8055",
  "#E99A7D",
  "#BCC28C",
  "#FFD393",
  "#BDC0B1",
  "#CBB18D",
  "#B7C09E",
  "#EABC75",
}

function M.apply()
  local lush = require("lush")
  local c = M.palette
  local p = {}
  for _, name in ipairs({ "bg", "fg", "rose", "leaf", "wood", "water", "blossom", "sky" }) do
    p[name] = lush.hsluv(c[name])
  end
  -- Our background is already the intended stark shade: don't darken it again.
  p.bg_stark = p.bg
  p = require("zenbones.util").palette_extend(p, "dark")
  local base = require("zenbones.specs").generate(p, "dark", {
    darkness = "stark",
    colorize_diagnostic_underline_text = false,
    italic_comments = true,
    italic_strings = false,
  })

  -- Extend before compiling so inherited Treesitter/plugin groups follow along.
  -- Lush supplies highlight names inside this DSL.
  ---@diagnostic disable: undefined-global
  -- stylua: ignore start
  local specs = lush.extends({ base }).with(function()
    return {
      Normal       { fg = c.fg, bg = c.bg },
      NormalNC     { fg = c.fg, bg = c.recessed },
      Error        { fg = c.rose },
      WarningMsg   { fg = c.wood },
      DiagnosticInfo { fg = c.water },
      DiagnosticHint { fg = c.blossom },
      DiagnosticOk { fg = c.leaf },
      Comment      { fg = c.muted, gui = "italic" },
      Identifier   { fg = c.fg },
      Function     { fg = c.amber },
      Statement    { fg = c.amber, gui = "bold" },
      String       { fg = "#C59C62", gui = "NONE" },
      Constant     { fg = "#C59C62", gui = "italic" },
      Number       { fg = "#C59C62" },
      Type         { fg = "#C5A573" },
      Delimiter    { fg = c.muted },
      Cursor       { fg = c.bg, bg = c.phosphor },
      CursorLine   { bg = c.highlight },
      ColorColumn  { bg = c.highlight },
      LineNr       { fg = c.border },
      CursorLineNr { fg = c.amber, gui = "bold" },
      NonText      { fg = c.border },
      Folded       { fg = c.muted, bg = c.raised },
      NormalFloat  { fg = c.fg, bg = c.raised },
      FloatBorder  { fg = c.border, bg = c.raised },
      Pmenu        { fg = c.fg, bg = c.raised },
      PmenuSel     { fg = c.phosphor, bg = c.selection },
      PmenuSbar    { bg = c.highlight },
      PmenuThumb   { bg = c.border },
      Search       { fg = c.bg, bg = c.amber },
      IncSearch    { fg = c.bg, bg = c.phosphor, gui = "bold" },
      MatchParen   { fg = c.phosphor, bg = c.selection, gui = "bold" },
      QuickFixLine { fg = c.phosphor, bg = c.selection },
      StatusLine   { fg = c.fg, bg = c.recessed },
      StatusLineNC { fg = c.muted, bg = c.recessed },
      TabLine      { fg = c.muted, bg = c.recessed },
      TabLineSel   { fg = c.amber, bg = c.highlight, gui = "bold" },
      WinSeparator { fg = c.border },
      Visual       { bg = c.selection },
      LspInlayHint { fg = c.muted, bg = c.raised },
      DiffAdd      { bg = "#26291B" },
      DiffDelete   { bg = "#35221A" },
      DiffChange   { bg = c.highlight },
      DiffText     { fg = c.phosphor, bg = c.selection },
    }
  end)
  -- stylua: ignore end
  ---@diagnostic enable: undefined-global
  lush(specs)
  for i, color in ipairs(M.ansi) do
    vim.g["terminal_color_" .. (i - 1)] = color
  end
end

function M.lualine()
  local c = M.palette
  local active = {
    a = { fg = c.amber, bg = c.highlight, gui = "bold" },
    b = { fg = c.fg, bg = c.raised },
    c = { fg = c.muted, bg = c.recessed },
  }
  return {
    normal = vim.deepcopy(active),
    insert = vim.deepcopy(active),
    visual = vim.tbl_deep_extend("force", vim.deepcopy(active), { a = { bg = c.selection, fg = c.phosphor } }),
    replace = vim.tbl_deep_extend("force", vim.deepcopy(active), { a = { fg = c.rose } }),
    command = vim.deepcopy(active),
    inactive = {
      a = { fg = c.muted, bg = c.recessed },
      b = { fg = c.muted, bg = c.recessed },
      c = { fg = c.muted, bg = c.recessed },
    },
  }
end

return M
