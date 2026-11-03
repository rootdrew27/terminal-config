# terminal-config

My [Ghostty](https://ghostty.org) terminal, [Starship](https://starship.rs) prompt and zsh setup. Works on macOS and Linux (tested install on Ubuntu).

- **Ghostty**: Catppuccin Latte/Mocha (follows system light/dark), translucent window, drop-down quick terminal.
- **Starship**: Pastel Powerline-style prompt (directory, git branch/status, Node version). Based on the [official preset](https://starship.rs/presets/pastel-powerline.html).
- **zsh**: vi mode with a cursor that changes shape per mode, `Ctrl+X C` to copy the last command, and `cpout` to copy a command's output.

## Layout

```
ghostty/config.ghostty   shared Ghostty config
ghostty/macos.ghostty    macOS-only settings (titlebar, Option-as-Alt, quick terminal key)
ghostty/linux.ghostty    Linux-only settings (quick terminal key)
starship/starship.toml   Starship prompt
zsh/terminal.zsh         portable zsh snippet (sourced from ~/.zshrc)
install.sh               symlinks the files into place for the current OS
```

## Install

### 1. Prerequisites

**macOS**

```sh
brew install --cask ghostty
brew install starship
```

**Ubuntu / Debian**

```sh
sudo apt install zsh git
sudo apt install wl-clipboard   # Wayland (or: xclip for X11), used by the copy helpers
curl -sS https://starship.rs/install.sh | sh   # Starship isn't in apt; see https://starship.rs
chsh -s "$(command -v zsh)"     # make zsh your login shell, then log out and back in
```

Ghostty has no official Ubuntu package. Options, per the [install docs](https://ghostty.org/docs/install/binary): the community [.deb builds](https://github.com/mkasberg/ghostty-ubuntu), `sudo snap install ghostty --classic`, or [build from source](https://ghostty.org/docs/install/build).

### 2. Link the config

```sh
git clone <this repo> ~/terminal-config
cd ~/terminal-config
./install.sh
echo 'source ~/.config/zsh/terminal.zsh' >> ~/.zshrc
```

`install.sh` symlinks each file, so edits in the repo apply immediately (keep the clone where it is). Any existing file is moved to `<name>.bak-<timestamp>`, not deleted. Reload Ghostty with `cmd+shift+,` (macOS) or `ctrl+shift+,` (Linux).

## How the OS split works

`ghostty/config.ghostty` ends with `config-file = ?platform.ghostty`. The installer points a gitignored symlink, `ghostty/platform.ghostty`, at `macos.ghostty` or `linux.ghostty`, so each OS only loads its own settings. The `?` makes the include optional. The symlink lives in the repo because Ghostty resolves includes relative to the config file's real location, not the symlink's.

Ghostty reads `~/.config/ghostty/` on both OSes and, on macOS, also `~/Library/Application Support/com.mitchellh.ghostty/`. The macOS path is loaded last and wins conflicts, so the script links there on macOS.

## Notes

- The Linux quick terminal needs Wayland with layer-shell support, and the global shortcut needs a desktop with global-shortcut support (e.g. KDE). Elsewhere it does nothing; edit `ghostty/linux.ghostty` to change it.
- Check the Ghostty config with `ghostty +validate-config`. Browse themes with `ghostty +list-themes`.
- Machine-specific shell setup (PATH, nvm, Homebrew, cloud SDKs) is deliberately not included.
