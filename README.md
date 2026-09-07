# dotfiles

### Setup

```sh
# Just sets up the symlinks
./symlink.sh
```

To setup symlinks, and install tmux plugins

```sh
./setup.sh
```

In neovim run

```
Copilot setup
```

### Amberglass theme

A dark amber-phosphor theme inspired by the VT220 and IBM 5155. Neovim uses
Zenbones' dark/stark highlight generator with a custom palette: amber syntax,
bronze comments, copper errors, olive additions, and gray-sage information.
WezTerm, tmux, and Pi share its backgrounds, selections, and quiet UI colors.
All four stay dark regardless of macOS appearance; the existing font is unchanged.

| Role                           | Color                             |
| ------------------------------ | --------------------------------- |
| Background / recessed / raised | `#15120D` / `#100E0A` / `#211B12` |
| Foreground / emphasis / cursor | `#D9AA63` / `#EABC75` / `#FFD393` |
| Comments / borders / selection | `#9B8055` / `#665031` / `#49351D` |
| Error / warning / addition     | `#D98267` / `#E8B461` / `#A7AD79` |
| Information / hint             | `#A3A699` / `#B49A79`             |

**Apply:** restart Neovim; WezTerm normally reloads its config automatically
(or use its Reload Configuration action); reload tmux with `Ctrl-a r` or
`tmux source-file ~/.tmux.conf`. Existing Neovim sessions should be restarted
so the old appearance-sync autocmd and lualine configuration are replaced too.

**Tune:**

- `.config/nvim/lua/user/amberglass.lua`: palette, highlights, terminal ANSI, lualine.
- `.config/nvim/colors/amberglass.lua`: `:colorscheme amberglass` entry point.
- `.wezterm.lua`: terminal colors, cursor, tab bar, workspace status.
- `.config/tmux/themes/amberglass.tmux`: tmux chrome and copy-mode colors.
- `.pi/agent/themes/amberglass.json`: Pi UI, syntax, thinking borders, and HTML exports.

Keep the ANSI lists in Neovim and WezTerm synchronized when editing. Explicit
truecolor output from external programs is not recolored by the terminal palette.
The previous tmux theme remains in `zenbones-dark.tmux`; stock Zenbones is still
available in Neovim via `:colorscheme zenbones`.

### Pi

Amberglass is selected in `.pi/agent/settings.json`. Select `amberglass` through
`/settings` in an existing Pi session, or restart Pi. The theme must be linked at
`~/.pi/agent/themes/amberglass.json` (handled by `./symlink.sh`). The previous
`zenbones` theme remains available. Edits to the active theme hot-reload.

The theme explicitly defines all 56 tokens in the source schema, including
scrollbar track/thumb, search match text/background, and `thinkingMax`. Thinking
levels progress from bronze to bright phosphor rather than using rainbow colors.
Search uses phosphor on brown; Pi reverses that pair for the current match.
Pi has no global TUI background token: its unpainted areas use the terminal's
background, so use the matching WezTerm palette. HTML exports have explicit
page/card/info backgrounds.

Validated against `~/dev/earendil-works/pi` at `ed05aa028`. Its schema/runtime
require 51 tokens with 5 optional tokens (the docs currently count the two
optional scrollbar tokens as required); Amberglass supplies all of them.
To recheck against the latest local source, including the JSON schema, runtime
loader, truecolor/256-color output, and HTML export resolution:

```sh
~/dev/earendil-works/pi/node_modules/.bin/tsx scripts/check-pi-amberglass.mjs
# Optional argument: path to a different Pi source checkout with dependencies installed.
```

Install forked `pi` from [here](https://github.com/shantanuraj/pi),
run `scripts/install-local-pi.sh`.
Run `pi update --extensions` to install the packages listed in
`settings.json`.
