# Portable terminal bits for bash (the zsh equivalent is zsh/terminal.zsh).
# Source this from ~/.bashrc:
#   source ~/.config/bash/terminal.bash
# Needs bash 4.4+ (for PS0). Only takes effect in interactive shells.

[[ $- == *i* ]] || return 0

# Vi mode, with a short timeout so Esc switches to normal mode without a lag.
# Ctrl+R reverse search is already bound in both vi keymaps.
set -o vi
bind 'set keyseq-timeout 10'

# Cursor shape per vi mode: block in normal mode, bar in insert mode.
# Readline prints the mode string before the last prompt line; \1 and \2 mark it
# as zero-width so line editing stays aligned.
bind 'set show-mode-in-prompt on'
bind 'set vi-ins-mode-string "\1\e[6 q\2"'
bind 'set vi-cmd-mode-string "\1\e[2 q\2"'
# Steady block cursor for commands you run (vim etc. inherit it). PS0 prints
# after a command is read and before it runs; append so Starship's PS0 survives.
[[ ${PS0-} == *'\e[2 q'* ]] || PS0+='\e[2 q'

# Clipboard: reads stdin. pbcopy (macOS), wl-copy (Wayland), xclip or xsel (X11).
# Ubuntu: sudo apt install wl-clipboard   (Wayland)  or  xclip   (X11)
_clip() {
  if command -v pbcopy >/dev/null; then pbcopy
  elif [[ -n ${WAYLAND_DISPLAY-} ]] && command -v wl-copy >/dev/null; then wl-copy
  elif [[ -n ${DISPLAY-} ]] && command -v xclip >/dev/null; then xclip -selection clipboard
  elif [[ -n ${DISPLAY-} ]] && command -v xsel >/dev/null; then xsel --clipboard --input
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

# Ctrl+X C: copy the last command to the clipboard (_clip reports a failure)
_copy_last_cmd() {
  local cmd
  cmd=$(_last_cmd)
  printf '%s' "$cmd" | _clip && echo "Copied: $cmd"
}
# Ctrl+X is unbound on its own first. Otherwise it stays bound (self-insert in
# insert mode), readline treats it as ambiguous, and the short keyseq-timeout
# above expires before a human can press C, inserting a literal ^X instead.
# Skipped when already bound: unbinding the prefix a second time breaks it.
for _km in vi-insert vi-command; do
  [[ $(bind -m "$_km" -X) == *'"\C-xc"'* ]] && continue
  bind -m "$_km" -r '\C-x'
  bind -m "$_km" -x '"\C-xc": _copy_last_cmd'
done
unset _km

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

# Prompt symbol that flips with the vi mode (success/error symbol in insert mode,
# vimcmd_symbol in normal mode). Starship can't do this in bash: it renders the
# prompt once per command, and only zsh/fish report the vi mode to it. Instead
# the [character] symbols are rendered once from starship.toml (via Starship's
# zsh renderer, the only one honouring --keymap), drawn by readline's mode
# strings, and Starship's own copy is trimmed off the prompt's last line.

# $1 as a readline string: backslashes and double quotes escaped, ANSI
# sequences wrapped as zero-width (\1...\2).
_rl_quote() {
  local s=${1//\\/\\\\} out= re=$'^([^\e]*)(\e\\[[0-9;?]*[A-Za-z])(.*)$'
  s=${s//\"/\\\"}
  while [[ $s =~ $re ]]; do
    out+=${BASH_REMATCH[1]}'\1'${BASH_REMATCH[2]}'\2'; s=${BASH_REMATCH[3]}
  done
  printf '%s' "$out$s"
}

# Runs after starship_precmd: picks the insert-mode symbol by exit status and
# drops Starship's symbol line. Leaves the prompt alone, with a one-time
# warning, if its last line isn't exactly the rendered symbol (custom format).
_vi_prompt_symbol() {
  local last=${PS1##*$'\n'} sym=$_VI_SYM_OK rl=$_VI_RL_OK
  if [[ ${STARSHIP_CMD_STATUS:-0} != 0 ]]; then sym=$_VI_SYM_ERR rl=$_VI_RL_ERR; fi
  last=${last//\\[/}; last=${last//\\]/}
  if [[ $PS1 == *$'\n'* && $last == "$sym" ]]; then
    PS1=${PS1%$'\n'*}$'\n'
    bind "set vi-ins-mode-string \"\\1\\e[6 q\\2$rl\""
    bind "set vi-cmd-mode-string \"\\1\\e[2 q\\2$_VI_RL_CMD\""
  else
    bind 'set vi-ins-mode-string "\1\e[6 q\2"'
    bind 'set vi-cmd-mode-string "\1\e[2 q\2"'
    if [[ -z ${_VI_SYM_WARNED-} ]]; then
      _VI_SYM_WARNED=1
      echo "terminal.bash: prompt's last line isn't Starship's [character] symbol; vi mode symbol disabled" >&2
    fi
  fi
}

if declare -F starship_precmd >/dev/null && [[ $PROMPT_COMMAND != *_vi_prompt_symbol* ]]; then
  _VI_SYM_OK=$(STARSHIP_SHELL=zsh starship module character --status=0)
  _VI_SYM_ERR=$(STARSHIP_SHELL=zsh starship module character --status=1)
  _VI_RL_CMD=$(_rl_quote "$(STARSHIP_SHELL=zsh starship module character --status=0 --keymap=vicmd)")
  if [[ -n $_VI_SYM_OK && -n $_VI_SYM_ERR && -n $_VI_RL_CMD ]]; then
    _VI_RL_OK=$(_rl_quote "$_VI_SYM_OK")
    _VI_RL_ERR=$(_rl_quote "$_VI_SYM_ERR")
    PROMPT_COMMAND+="${PROMPT_COMMAND:+;}_vi_prompt_symbol"
  else
    echo "terminal.bash: couldn't render Starship's [character] symbols; vi mode symbol disabled" >&2
  fi
fi

command -v tree >/dev/null && alias tree='tree -L 1'
