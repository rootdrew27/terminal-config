# Portable terminal bits for bash (the zsh equivalent is zsh/terminal.zsh).
# Source this from ~/.bashrc:
#   source ~/.config/bash/terminal.bash
# Needs bash 4.4+ (for PS0). Only takes effect in interactive shells.

[[ $- == *i* ]] || return 0

# Vi mode, with a short timeout so Esc switches to normal mode without a lag
set -o vi
bind 'set keyseq-timeout 10'
bind -m vi-insert '"\C-r": reverse-search-history'

# Cursor shape per vi mode: block in normal mode, bar in insert mode.
# Readline prints the mode string before the last prompt line; \1 and \2 mark it
# as zero-width so line editing stays aligned.
bind 'set show-mode-in-prompt on'
bind 'set vi-ins-mode-string "\1\e[6 q\2"'
bind 'set vi-cmd-mode-string "\1\e[2 q\2"'
# Steady block cursor for commands you run (vim etc. inherit it). PS0 prints
# after a command is read and before it runs; append so Starship's PS0 survives.
[[ ${PS0-} == *'\e[2 q'* ]] || PS0="${PS0-}"'\e[2 q'

# Clipboard: reads stdin. pbcopy (macOS), wl-copy (Wayland), xclip or xsel (X11).
# Ubuntu: sudo apt install wl-clipboard   (Wayland)  or  xclip   (X11)
_clip() {
  if command -v pbcopy >/dev/null; then pbcopy
  elif [[ -n ${WAYLAND_DISPLAY-} ]] && command -v wl-copy >/dev/null; then wl-copy
  elif command -v xclip >/dev/null; then xclip -selection clipboard
  elif command -v xsel >/dev/null; then xsel --clipboard --input
  else cat >/dev/null; echo "no clipboard tool found (install wl-clipboard or xclip)" >&2; return 1
  fi
}

# Most recent history entry, skipping back over calls to $1 if given (bash
# records the running command before it executes, and repeated calls may be
# recorded too). Fails if nothing else is left. Avoids fc: it assumes its own
# call is the newest entry and skips it, which is wrong inside a key binding.
_last_cmd() {
  local HISTTIMEFORMAT= entry num cmd
  entry=$(history 1)
  [[ $entry =~ ^\ *([0-9]+)\*?\ \ (.*)$ ]] || return 1
  num=${BASH_REMATCH[1]} cmd=${BASH_REMATCH[2]}
  while [[ -n ${1-} && ( $cmd == "$1" || $cmd == "$1 "* ) ]]; do
    (( num > 1 )) || return 1
    num=$((num - 1))
    cmd=$(history -p "!$num" 2>/dev/null) || return 1
  done
  printf '%s' "$cmd"
}

# Ctrl+X C: copy the last command to the clipboard
_copy_last_cmd() {
  local cmd
  cmd=$(_last_cmd)
  if printf '%s' "$cmd" | _clip; then echo "Copied: $cmd"; else echo "No clipboard tool found"; fi
}
bind -m vi-insert  -x '"\C-xc": _copy_last_cmd'
bind -m vi-command -x '"\C-xc": _copy_last_cmd'

# cpout: re-run the last command and copy its output (beware of commands with side effects)
cpout() {
  local cmd
  cmd=$(_last_cmd cpout) || { echo "cpout: no previous command to re-run" >&2; return 1; }
  printf 'Re-running: %s\n' "$cmd" >&2
  eval "$cmd" 2>&1 | tee >(_clip)
}

# Starship prompt (skipped if ~/.bashrc already initialised it)
if command -v starship >/dev/null && ! declare -F starship_precmd >/dev/null; then
  eval "$(starship init bash)"
fi

command -v tree >/dev/null && alias tree='tree -L 1'
