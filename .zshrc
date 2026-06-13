# vi mode
bindkey -v
export KEYTIMEOUT=10
bindkey -M viins '^?' backward-delete-char

# Prefix history search on arrows
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
for m in viins vicmd; do
  bindkey -M $m '^[[A' up-line-or-beginning-search
  bindkey -M $m '^[OA' up-line-or-beginning-search
  bindkey -M $m '^[[B' down-line-or-beginning-search
  bindkey -M $m '^[OB' down-line-or-beginning-search
done

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_dups hist_ignore_space

# Completions
FPATH="/opt/homebrew/share/zsh/site-functions:$FPATH"
autoload -Uz compinit && compinit

# Git aliases (vendored from oh-my-zsh git plugin)
source "$HOME/.dotfiles/.config/zsh/git.plugin.zsh"
alias grb!='GIT_SEQUENCE_EDITOR=true git rebase -i'

# mise
eval "$(~/.local/bin/mise activate zsh)"

# zoxide
eval "$(zoxide init zsh --cmd j)"

# FZF
export FZF_DEFAULT_COMMAND='rg --files'
eval "$(fzf --zsh)"

# atuin
eval "$(atuin init zsh --disable-up-arrow)"

# NVIM
export EDITOR='nvim'
alias vim='nvim'
alias vi='NVIM_APPNAME=nvim-zen nvim'

# Ripgrep
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/rc"

# Android
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/platform-tools:$PATH"

# bun
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Go
export PATH="$HOME/go/bin:$PATH"

# Local bin
export PATH="$HOME/.local/bin:$PATH"

# bat theme
export BAT_THEME="ansi"

# magit
alias magit="emacs -nw --eval '(magit-status)'"

if [ "$(uname)" = "Linux" ]; then
  export COLORTERM=truecolor
fi

# starship
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
command -v starship >/dev/null && eval "$(starship init zsh)"

# WezTerm
source "$HOME/.dotfiles/.config/wezterm/wezterm.sh"

# rbenv
command -v rbenv >/dev/null && eval "$(rbenv init - zsh)"

# Playdate SDK
export PLAYDATE_SDK="$HOME/Developer/PlaydateSDK"
export PATH="$PLAYDATE_SDK/bin:$PATH"

# Mojo
export PATH="$PATH:$HOME/.modular/bin"

# Plan9
[ -d "$HOME/dev/9fans/plan9port" ] && export PLAN9="$HOME/dev/9fans/plan9port"
[ -n "$PLAN9" ] && export PATH="$PATH:$PLAN9/bin"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
