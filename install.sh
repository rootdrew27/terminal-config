#!/usr/bin/env bash
# Symlink this repo's configs into place (macOS and Linux). Existing files are
# moved aside to <name>.bak-<timestamp>, never deleted.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
XDG="${XDG_CONFIG_HOME:-$HOME/.config}"

link() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "ok       $dest"
    return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mv "$dest" "$dest.bak-$STAMP"
    echo "backup   $dest -> $dest.bak-$STAMP"
  fi
  ln -s "$src" "$dest"
  echo "linked   $dest -> $src"
}

case "$(uname -s)" in
  Darwin)
    # On macOS the Application Support file is loaded last and wins, so link there.
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

# Ghostty resolves `config-file = ?platform.ghostty` relative to the REAL location of
# config.ghostty (it follows the symlink), so the per-OS file is selected by a
# gitignored symlink inside the repo rather than next to the linked config.
ln -sfn "$PLATFORM.ghostty" "$REPO/ghostty/platform.ghostty"
echo "selected ghostty/platform.ghostty -> $PLATFORM.ghostty"
link "$REPO/ghostty/config.ghostty"          "$GHOSTTY_DIR/config.ghostty"
link "$REPO/starship/starship.toml"          "$XDG/starship.toml"
link "$REPO/zsh/terminal.zsh"                "$XDG/zsh/terminal.zsh"

echo
missing=()
for tool in ghostty starship zsh; do
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

echo "Add this line to ~/.zshrc if it isn't there already:"
echo "  source ~/.config/zsh/terminal.zsh"
echo "Then reload Ghostty (cmd+shift+, on macOS, ctrl+shift+, on Linux) and open a new zsh shell."
