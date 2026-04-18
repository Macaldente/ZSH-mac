# ======================
#   .zshrc Configuration
# ======================

# --- PATH initializer
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/opt/homebrew/opt/libxml2/bin:$PATH"

# --- Plugin manager (Antidote)
ANTIDOTE_DIR="${HOME}/.zsh/antidote"
if [[ ! -d "$ANTIDOTE_DIR" ]]; then
  git clone --depth=1 https://github.com/mattmc3/antidote.git "$ANTIDOTE_DIR"
fi

export ANTIDOTE_HOME="${HOME}/.zsh/plugins"
source "$ANTIDOTE_DIR/antidote.zsh"

ZSH_PLUGINS_FILE="${ZDOTDIR:-$HOME}/.zsh_plugins.txt"
if [[ ! -f "$ZSH_PLUGINS_FILE" ]]; then
  cat > "$ZSH_PLUGINS_FILE" <<'EOF'
marlonrichert/zsh-autocomplete
zsh-users/zsh-autosuggestions
mafredri/zsh-async
zsh-users/zsh-syntax-highlighting
Aloxaf/fzf-tab
EOF
fi

# --- History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt INC_APPEND_HISTORY SHARE_HISTORY
setopt HIST_VERIFY
setopt HIST_IGNORE_ALL_DUPS

# --- Completion cache
export ZCOMPDUMP="${ZDOTDIR:-$HOME}/.cache/zsh/zcompdump"
mkdir -p "${ZDOTDIR:-$HOME}/.cache/zsh"
autoload -Uz compinit && compinit -d "$ZCOMPDUMP"

# --- Plugin loader
ZSH_AUTOSUGGEST_STRATEGY=( history )
ZSH_HIGHLIGHT_HIGHLIGHTERS=( main brackets )
antidote load "$ZSH_PLUGINS_FILE"

# --- Tool initialization
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

# FZF configuration file
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --zsh)" 2>/dev/null || true
fi

# --- Alias section
# ls
alias ls='eza --group-directories-first --icons=always'
alias ll='eza -l'
alias la='eza -a --group-directories-first --icons=always'
alias lla='eza -la'
# eza
alias eza='eza -a --group-directories-first --icons=always'
alias ezal='eza -l'
alias ezaa='eza -a --group-directories-first --icons=always'
alias ezla='eza -la'

# -------------
# own functions
# -------------

# clear the clipboard
clrclp () {
    pbcopy < /dev/null
}

# generate password: default 16 digits, optional less/more digits:
genpass() {
    jot -r -c ${1:-16} 33 126 | tr -d '\n' | pbcopy && echo "Neues Passwort (${1:-16} Zeichen) in der Zwischenablage verfügbar"
}

# scan the download directory
vscand () {
    clamdscan --fdpass --multiscan --no-summary ~/Downloads
}

# scan a path by clamdscan
vscan() {
  if [ -z "$1" ]; then
    echo "Bitte gib einen Pfad an, z. B.: vscan ~/Downloads"
    return 1
  fi

  if [ ! -e "$1" ]; then
    echo "Pfad '$1' existiert nicht."
    return 1
  fi

  clamdscan --fdpass --multiscan --no-summary "$1"
}

# youtube downloader mp4
ytv() {
    yt-dlp -t mp4 "$@"
}

# --- Nearly finished
. "$HOME/.atuin/bin/env"
eval "$(atuin init zsh)"

# --- PATH finish
if [[ -d /usr/local/bin/podman ]]; then
  export PATH="$PATH:/usr/local/bin/podman"
fi

# --- End of .zshrc ++++++++
export HOMEBREW_NO_ENV_HINTS=1
export PATH="$HOME/.local/bin:$PATH"
