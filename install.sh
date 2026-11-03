#!/usr/bin/env bash
# Copy this repo's configs into place (macOS and Linux). Re-run after editing the
# repo. Installed files that differ from the repo are moved aside to
# <name>.bak-<timestamp>, never deleted.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
XDG="${XDG_CONFIG_HOME:-$HOME/.config}"

install_file() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ]; then
    case "$(readlink "$dest")" in
      "$REPO"/*)
        # A link from an earlier, symlinking version of this script: nothing to keep.
        rm "$dest"
        ;;
      *)
        mv "$dest" "$dest.bak-$STAMP"
        echo "backup   $dest -> $dest.bak-$STAMP"
        ;;
    esac
  elif [ -e "$dest" ]; then
    if cmp -s "$src" "$dest"; then
      echo "ok       $dest"
      return
    fi
    mv "$dest" "$dest.bak-$STAMP"
    echo "backup   $dest -> $dest.bak-$STAMP"
  fi
  # Copy to a temporary name first so a failed copy never leaves a partial config.
  cp "$src" "$dest.tmp-$STAMP"
  mv "$dest.tmp-$STAMP" "$dest"
  echo "copied   $src -> $dest"
}

case "$(uname -s)" in
  Darwin)
    # On macOS the Application Support file is loaded last and wins, so install there.
    GHOSTTY_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
    PLATFORM=macos
    ;;
  Linux)
    GHOSTTY_DIR="$XDG/ghostty"
    PLATFORM=linux
    ;;
  *)
    echo "Unsupported OS: $(uname -s)" >&2
    exit 1
    ;;
esac

# `config-file = ?platform.ghostty` in config.ghostty loads the per-OS file from
# the same directory, so install this OS's file under that name.
install_file "$REPO/ghostty/config.ghostty"     "$GHOSTTY_DIR/config.ghostty"
install_file "$REPO/ghostty/$PLATFORM.ghostty"  "$GHOSTTY_DIR/platform.ghostty"
install_file "$REPO/starship/starship.toml"     "$XDG/starship.toml"
install_file "$REPO/zsh/terminal.zsh"           "$XDG/zsh/terminal.zsh"
install_file "$REPO/bash/terminal.bash"         "$XDG/bash/terminal.bash"

echo
missing=()
for tool in ghostty starship; do
  command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
done
if [ "$PLATFORM" = linux ] && ! command -v wl-copy >/dev/null 2>&1 \
   && ! command -v xclip >/dev/null 2>&1 && ! command -v xsel >/dev/null 2>&1; then
  missing+=("clipboard tool (wl-clipboard or xclip)")
fi
if [ "${#missing[@]}" -gt 0 ]; then
  echo "Not installed yet: ${missing[*]}"
  echo "See the Install section of README.md."
  echo
fi

echo "Add the line for your shell if it isn't there already:"
echo "  zsh  (~/.zshrc):   source ~/.config/zsh/terminal.zsh"
echo "  bash (~/.bashrc):  source ~/.config/bash/terminal.bash"
echo "Then reload Ghostty (cmd+shift+, on macOS, ctrl+shift+, on Linux) and open a new shell."
