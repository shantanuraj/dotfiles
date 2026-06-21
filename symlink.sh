#!/usr/bin/env bash

set -e
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

symlink() {
	target="$HOME/$1"
	rm -rf "$target"
	mkdir -p "$(dirname "$target")"
	ln -svf "$PWD/$1" "$target"
}

/usr/bin/find . -mindepth 1 -maxdepth 1 \( -type f -o -type l \) \( -name '.*' -o -name 'blog' -o -name 'notes' \) \! -name '.gitmodules' | while read -r file; do
	symlink "${file#./}"
done

/usr/bin/find . -mindepth 1 -maxdepth 1 -type d -name '.*' \! -name '.config' \! -name '.git' \! -name '.pi' | while read -r dir; do
	symlink "${dir#./}"
done

/usr/bin/find .config -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
	symlink "$dir"
done

# Pi keeps secrets, sessions, package caches, and other runtime state under ~/.pi/agent.
if [ -d .pi/agent ]; then
	/usr/bin/find .pi/agent -mindepth 1 -maxdepth 1 -type f \
		\! -name '.gitignore' \
		\! -name 'auth.json' \
		\! -name 'trust.json' \
		\! -name 'run-history.jsonl' | while read -r file; do
		symlink "${file#./}"
	done

	for dir in extensions prompts skills themes; do
		if [ -d ".pi/agent/$dir" ]; then
			/usr/bin/find ".pi/agent/$dir" -mindepth 1 -maxdepth 1 \( -type f -o -type d -o -type l \) | while read -r entry; do
				symlink "${entry#./}"
			done
		fi
	done
fi

