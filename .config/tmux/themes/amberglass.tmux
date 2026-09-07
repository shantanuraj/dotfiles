# Amberglass: quiet amber chrome, matching Neovim and WezTerm.
set -g status on
set -g status-position bottom
set -g status-justify left
set -g status-left-length 40
set -g status-right-length 120
set -g status-style "fg=#9B8055,bg=#100E0A"
set -g status-left ""
set -g status-right "#{?client_prefix,#[fg=#15120D#,bg=#FFD393#,bold] prefix #[default] ,}#[fg=#EABC75,bold]#S #[fg=#9B8055,nobold]| %a %b %e %H:%M "

set -g window-status-separator ""
set -g window-status-style "fg=#9B8055,bg=#100E0A"
set -g window-status-current-style "fg=#EABC75,bg=#2C2316,bold"
set -g window-status-activity-style "fg=#E8B461,bg=#100E0A"
set -g window-status-bell-style "fg=#D98267,bg=#100E0A,bold"
set -g window-status-format " #I:#{window_name} "
set -g window-status-current-format " #I:#{window_name}#{?window_zoomed_flag,+,} "

set -g pane-border-status top
set -g pane-border-style "fg=#665031"
set -g pane-active-border-style "fg=#EABC75"
set -g pane-border-format " #{pane_index}: #{pane_current_command} #[fg=#9B8055](#{b:pane_current_path}) "

set -g message-style "fg=#D9AA63,bg=#211B12"
set -g message-command-style "fg=#EABC75,bg=#211B12"
set -g mode-style "fg=#D9AA63,bg=#49351D"
set -g copy-mode-match-style "fg=#15120D,bg=#EABC75"
set -g copy-mode-current-match-style "fg=#15120D,bg=#FFD393,bold"
set -g popup-style "fg=#D9AA63,bg=#211B12"
set -g popup-border-style "fg=#665031,bg=#211B12"

set -g display-panes-active-colour "#FFD393"
set -g display-panes-colour "#9B8055"
set -g clock-mode-colour "#EABC75"
