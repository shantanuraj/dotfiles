# Setup symlink for dotfiles
./symlink.sh;

# Update wezterm icon
./update-wezterm-icon.sh;

# Clone tmux plugin manager and install plugins
git clone git@github.com:tmux-plugins/tpm ~/.tmux/plugins/tpm;
~/.tmux/plugins/tpm/bin/install_plugins;
