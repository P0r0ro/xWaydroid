# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-10-17

### Added
- `xwaydroid` launcher: starts a nested Weston (X11 backend, kiosk shell),
  starts the Waydroid session on it and opens the full Android UI; cleans up
  when the window is closed.
- `xwaydroid setup`: installs waydroid, weston and wl-clipboard on dnf, apt,
  pacman (+AUR), zypper, xbps, apk and eopkg; runs `waydroid init`
  (optionally with `--gapps`); enables `waydroid-container`.
- `xwaydroid stop` and `xwaydroid doctor` subcommands.
- Options: `--fullscreen`, `--width`, `--height`, `--app`, `--software`,
  `--desktop-shell`, `--keep-running`, plus `~/.config/xwaydroid/config`.
- Detects native Wayland sessions and runs Waydroid directly there.
- `install.sh` with user (`~/.local/bin`) and `--system` installs,
  `curl | bash` support, desktop entry, hicolor icons and `--uninstall`.

[1.0.0]: https://github.com/P0r0ro/xWaydroid/releases/tag/v1.0.0
