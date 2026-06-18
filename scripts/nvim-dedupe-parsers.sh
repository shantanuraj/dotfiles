#!/usr/bin/env bash
# nvim-dedupe-parsers.sh
#
# Remove tree-sitter parsers from plugin/site dirs that duplicate (shadow)
# Neovim's own bundled parsers, so Neovim's matched parser+query pair is used.
#
# Why this matters:
#   Neovim core ships a grammar AND its highlight queries together and keeps
#   them in lockstep. Plugins (nvim-treesitter, and the legacy
#   ~/.local/share/nvim/site/parser dir) place their own copy of the same
#   grammar EARLIER on 'runtimepath', so an older plugin parser ends up paired
#   with Neovim's newer core query -> errors like:
#       Query error ... Invalid field name "operator"
#   Deleting the duplicate lets Neovim load its own (matching) grammar.
#
# Safe by design:
#   * Never touches Neovim's bundled parser dir (<prefix>/lib/nvim/parser).
#   * Only removes a parser when Neovim ALSO ships a query for that language
#     (i.e. only the grammars that can actually cause this crash).
#   * Skips languages in --keep (default: bash,python -- current Neovim no
#     longer bundles these; they are usually managed by nvim-treesitter's
#     ensure_installed, so leave them to the plugin).
#   * Dry-run unless --apply. Removed files are moved to a timestamped backup.
#
# Usage:
#   nvim-dedupe-parsers.sh                 # dry run; show what would change
#   nvim-dedupe-parsers.sh --apply         # back up + remove duplicates
#   nvim-dedupe-parsers.sh --keep bash,go  # custom keep list
#   nvim-dedupe-parsers.sh --no-keep       # don't keep anything
#   NVIM=/path/to/nvim nvim-dedupe-parsers.sh --apply
set -eu

NVIM="${NVIM:-nvim}"
APPLY=0
KEEP="bash,python"

while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1 ;;
    --keep) KEEP="${2:-}"; shift ;;
    --keep=*) KEEP="${1#--keep=}" ;;
    --no-keep) KEEP="" ;;
    -h|--help) sed -n '2,40p' "$0" | sed 's/^#\{0,1\} \{0,1\}//'; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
lua="$tmpdir/detect.lua"

cat > "$lua" <<'LUA'
local function norm(p) return vim.fs.normalize(p) end
local keep = {}
for k in tostring(vim.env.NTS_KEEP or ""):gmatch("[^,]+") do keep[k] = true end

local vrt    = norm(vim.env.VIMRUNTIME or "")
local data   = norm(vim.fn.stdpath("data"))
local prefix = vim.fn.fnamemodify(vrt, ":h:h:h")
local bdir   = norm(prefix .. "/lib/nvim/parser")

if vim.fn.isdirectory(bdir) == 0 then
  for _, f in ipairs(vim.api.nvim_get_runtime_file("parser/*.so", true)) do
    local d = norm(vim.fn.fnamemodify(f, ":h"))
    if d:match("/lib/nvim/parser$") then bdir = d break end
  end
end

-- Languages Neovim currently bundles BOTH a parser and a query for.
local bundled = {}
if vim.fn.isdirectory(bdir) == 1 then
  for name in vim.fs.dir(bdir) do
    local lang = name:match("^(.-)%.so$")
    if lang and vim.fn.isdirectory(vrt .. "/queries/" .. lang) == 1 then
      bundled[lang] = true
    end
  end
end

io.write("BUNDLED_DIR\t" .. bdir .. "\n")
io.write("DATA\t" .. data .. "\n")
io.write("BACKUP\t" .. data .. "/ts-parser-backup-" .. os.date("%Y%m%d-%H%M%S") .. "\n")

local langs = {}
for l in pairs(bundled) do langs[#langs + 1] = l end
table.sort(langs)
for _, l in ipairs(langs) do io.write("BUNDLED\t" .. l .. "\n") end

-- Find every parser/*.so under the data dir that duplicates a bundled lang.
local files = vim.fn.glob(data .. "/**/parser/*.so", true, true)
table.sort(files)
for _, f in ipairs(files) do
  local fn   = norm(f)
  local d    = norm(vim.fn.fnamemodify(f, ":h"))
  local lang = vim.fn.fnamemodify(f, ":t:r")
  if d ~= bdir and bundled[lang] and not keep[lang] then
    io.write("DUP\t" .. lang .. "\t" .. fn .. "\n")
  end
end
LUA

meta="$(NTS_KEEP="$KEEP" "$NVIM" --headless -u NONE -i NONE -n -c "luafile $lua" -c "qa" 2>/dev/null || true)"

bundled_dir="$(printf '%s\n' "$meta" | awk -F'\t' '$1=="BUNDLED_DIR"{print $2; exit}')"
backup="$(printf '%s\n' "$meta" | awk -F'\t' '$1=="BACKUP"{print $2; exit}')"

if [ -z "$bundled_dir" ]; then
  echo "error: could not query Neovim (is '$NVIM' on PATH?)" >&2
  exit 1
fi

echo "Neovim bundled parser dir: $bundled_dir"
echo "Bundled langs (parser+query): $(printf '%s\n' "$meta" | awk -F'\t' '$1=="BUNDLED"{print $2}' | paste -sd' ' -)"
[ -n "$KEEP" ] && echo "Keeping (never removed):      $KEEP"
echo

dups="$(printf '%s\n' "$meta" | awk -F'\t' '$1=="DUP"{print $3}')"
if [ -z "$dups" ]; then
  echo "No duplicate parsers found. Nothing to do."
  exit 0
fi

echo "Duplicate parsers shadowing Neovim's bundled ones:"
printf '%s\n' "$meta" | awk -F'\t' '$1=="DUP"{printf "  %-18s %s\n", $2, $3}'
echo

if [ "$APPLY" -ne 1 ]; then
  echo "Dry run. Re-run with --apply to back up and remove them."
  exit 0
fi

mkdir -p "$backup"
printf '%s\n' "$dups" | while IFS= read -r f; do
  [ -n "$f" ] || continue
  dest="$backup/${f#/}"
  mkdir -p "$(dirname "$dest")"
  mv "$f" "$dest"
  echo "moved $f"
done

echo
echo "Backed up to: $backup"
echo "Done. Restart Neovim; it will now use its bundled parsers."
