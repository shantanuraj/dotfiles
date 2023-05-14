#!/bin/bash

set -eo pipefail

icon_path=/Applications/WezTerm.app/Contents/Resources/terminal.icns
if [ ! -f "$icon_path" ]; then
  echo "Can't find existing icon, make sure WezTerm is installed"
  exit 1
fi

echo "Backing up existing icon"
hash="$(shasum $icon_path | head -c 10)"
mv "$icon_path" "$icon_path.backup-$hash"

cp ./.config/wezterm/term-icon.icns "$icon_path"

touch /Applications/WezTerm.app
killall Finder
killall Dock
