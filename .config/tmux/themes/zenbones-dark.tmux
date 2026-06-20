# Zenbones-inspired tmux theme.
# Palette adapted from .wezterm.lua and zenbones.nvim extras/tmux.

set -g status on
set -g status-position bottom
set -g status-justify left
set -g status-left-length 40
set -g status-right-length 120
set -g status-style "fg=#B4BDC3,bg=#1C1917"
set -g status-left "#[fg=#819B69,bold] #S #[default]"
set -g status-right "#{?client_prefix,#[fg=#1C1917#,bg=#B279A7#,bold] prefix #[default] ,}#[fg=#888F94]%a %b %e %H:%M "

set -g window-status-separator ""
set -g window-status-style "fg=#888F94,bg=#1C1917"
set -g window-status-current-style "fg=#C4CACF,bg=#1C1917,bold,underscore"
set -g window-status-activity-style "fg=#B77E64,bg=#1C1917"
set -g window-status-format " #[fg=#888F94]#{window_index}:#{window_name} "
set -g window-status-current-format " #[fg=#C4CACF,bold,underscore]#{window_index}:#{window_name}#{?window_zoomed_flag,+,} "

set -g pane-border-status top
set -g pane-border-style "fg=#403833"
set -g pane-active-border-style "fg=#B279A7"
set -g pane-border-format " #{pane_index}: #{pane_current_command} #[fg=#888F94](#{b:pane_current_path}) "

set -g message-style "fg=#B4BDC3,bg=#3D4042"
set -g message-command-style "fg=#B4BDC3,bg=#3D4042"
set -g mode-style "fg=#1C1917,bg=#B279A7,bold"
set -g copy-mode-match-style "fg=#1C1917,bg=#B77E64"
set -g copy-mode-current-match-style "fg=#1C1917,bg=#819B69"

set -g display-panes-active-colour "#B279A7"
set -g display-panes-colour "#888F94"
set -g clock-mode-colour "#B279A7"
