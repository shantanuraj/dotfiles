# Setup symlink for dotfiles
./symlink.sh;

# Update alacritty icon
./update-alacritty-icon.sh;

# Update wezterm icon
./update-wezterm-icon.sh;

# Clone tmux plugin manager and install plugins
git clone git@github.com:tmux-plugins/tpm ~/.tmux/plugins/tpm;
~/.tmux/plugins/tpm/bin/install_plugins;

# Clone theme for Alacritty
git clone git@github.com:srcery-colors/srcery-terminal.git ~/.local/share/alacritty/srcery-terminal;
