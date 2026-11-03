# Portable terminal bits for zsh. Source this from ~/.zshrc:
#   source ~/.config/zsh/terminal.zsh

# Vi mode (must come before starship init, which wraps zle-keymap-select)
bindkey -v
export KEYTIMEOUT=1
bindkey '^R' history-incremental-search-backward

# Cursor shape per vi mode: block in normal mode, bar in insert mode
_vi_cursor() {
  if [[ $KEYMAP == vicmd ]]; then printf '\e[2 q'; else printf '\e[6 q'; fi
}
zle -N zle-keymap-select _vi_cursor
zle -N zle-line-init _vi_cursor
# Steady block cursor for commands you run (vim etc. inherit it)
_reset_cursor() { printf '\e[2 q' }
autoload -Uz add-zsh-hook
add-zsh-hook preexec _reset_cursor

# Clipboard: reads stdin. pbcopy (macOS), wl-copy (Wayland), xclip or xsel (X11).
# Ubuntu: sudo apt install wl-clipboard   (Wayland)  or  xclip   (X11)
_clip() {
  if (( $+commands[pbcopy] )); then pbcopy
  elif [[ -n $WAYLAND_DISPLAY ]] && (( $+commands[wl-copy] )); then wl-copy
  elif (( $+commands[xclip] )); then xclip -selection clipboard
  elif (( $+commands[xsel] )); then xsel --clipboard --input
  else cat >/dev/null; print -u2 "no clipboard tool found (install wl-clipboard or xclip)"; return 1
  fi
}

# Ctrl+X C: copy the last command to the clipboard
_copy_last_cmd() { print -rn -- "$(fc -ln -1)" | _clip && zle -M "Copied: $(fc -ln -1)" || zle -M "No clipboard tool found" }
zle -N _copy_last_cmd
bindkey -M viins '^Xc' _copy_last_cmd
bindkey -M vicmd '^Xc' _copy_last_cmd

# cpout: re-run the last command and copy its output (beware of commands with side effects)
cpout() {
  local cmd=$(fc -ln -1)
  print -r -- "Re-running: $cmd" >&2
  eval "$cmd" 2>&1 | tee >(_clip)
}

# Starship prompt
(( $+commands[starship] )) && eval "$(starship init zsh)"

(( $+commands[tree] )) && alias tree='tree -L 1'
