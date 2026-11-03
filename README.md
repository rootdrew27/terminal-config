# terminal-config

My [Ghostty](https://ghostty.org) terminal, [Starship](https://starship.rs) prompt and zsh/bash setup. Works on macOS and Linux (tested install on Ubuntu).

- **Ghostty**: Catppuccin Latte/Mocha (follows system light/dark), translucent window, drop-down quick terminal.
- **Starship**: Pastel Powerline-style prompt (directory, git branch/status, Node version). Based on the [official preset](https://starship.rs/presets/pastel-powerline.html).
- **Shell (zsh or bash)**: vi mode with a cursor that changes shape per mode, `Ctrl+X C` to copy the last command, and `cpout` to copy a command's output. The zsh and bash files provide the same features; in bash the vi mode shows only through the cursor shape, since Starship's `❮` normal-mode prompt symbol is zsh/fish only.

## Layout

```
ghostty/config.ghostty   shared Ghostty config
ghostty/macos.ghostty    macOS-only settings (titlebar, Option-as-Alt, quick terminal key)
ghostty/linux.ghostty    Linux-only settings (quick terminal key)
starship/starship.toml   Starship prompt
zsh/terminal.zsh         portable zsh snippet (sourced from ~/.zshrc)
bash/terminal.bash       the same features for bash 4.4+ (sourced from ~/.bashrc)
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
sudo apt install git
sudo apt install wl-clipboard   # Wayland (or: xclip for X11), used by the copy helpers
curl -sS https://starship.rs/install.sh | sh   # Starship isn't in apt; see https://starship.rs
# zsh only (bash users skip this):
sudo apt install zsh
chsh -s "$(command -v zsh)"     # make zsh your login shell, then log out and back in
```

Ghostty has no official Ubuntu package. Options, per the [install docs](https://ghostty.org/docs/install/binary): `sudo snap install ghostty --classic` (tracks the latest release), the community [.deb builds](https://github.com/mkasberg/ghostty-ubuntu), or [build from source](https://ghostty.org/docs/install/build). The config needs Ghostty 1.2.3 or later: older versions ignore the `config.ghostty` file name and reject some of its options and theme names.

### 2. Link the config

```sh
git clone <this repo> ~/terminal-config
cd ~/terminal-config
./install.sh
echo 'source ~/.config/zsh/terminal.zsh' >> ~/.zshrc      # zsh
echo 'source ~/.config/bash/terminal.bash' >> ~/.bashrc   # bash
```

`install.sh` symlinks each file, so edits in the repo apply immediately (keep the clone where it is). Any existing file is moved to `<name>.bak-<timestamp>`, not deleted. Reload Ghostty with `cmd+shift+,` (macOS) or `ctrl+shift+,` (Linux).

Ghostty also loads a legacy `config` file from the same directory, after `config.ghostty`, so its settings win. If you have one from an older setup, move it aside.

## How the OS split works

`ghostty/config.ghostty` ends with `config-file = ?platform.ghostty`. The installer links `platform.ghostty` to `macos.ghostty` or `linux.ghostty`, so each OS only loads its own settings. The `?` makes the include optional, which also means a missing link fails silently, so check with `ghostty +show-config` (see Notes). Ghostty 1.4 resolves the include next to the linked `config.ghostty`, while some earlier versions followed the symlink into the repo, so the installer creates the link in both places. The one in the repo is gitignored.

Ghostty reads `~/.config/ghostty/` on both OSes and, on macOS, also `~/Library/Application Support/com.mitchellh.ghostty/`. The macOS path is loaded last and wins conflicts, so the script links there on macOS.

## Notes

- The Linux quick terminal needs Wayland with layer-shell support, and the global shortcut needs a desktop with global-shortcut support (e.g. KDE). Elsewhere it does nothing; edit `ghostty/linux.ghostty` to change it.
- Check the Ghostty config with `ghostty +validate-config`. Browse themes with `ghostty +list-themes`. To confirm the per-OS file loaded, `ghostty +show-config | grep quick_terminal` should print the quick terminal keybind.
- Machine-specific shell setup (PATH, nvm, Homebrew, cloud SDKs) is deliberately not included.
