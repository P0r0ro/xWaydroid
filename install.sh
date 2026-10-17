#!/usr/bin/env bash
# xWaydroid installer
#
#   ./install.sh               install for the current user (~/.local/bin), set up, then launch
#   ./install.sh --system      install for all users (/usr/local/bin)
#   ./install.sh --no-launch   install and set up, but do not start Android
#   ./install.sh --gapps       initialize Waydroid with Google Play images
#   ./install.sh --uninstall   remove xWaydroid (Waydroid itself is left alone)
#
# One-liner:
#   curl -fsSL https://raw.githubusercontent.com/P0r0ro/xWaydroid/main/install.sh | bash
#
# SPDX-License-Identifier: GPL-3.0-or-later

set -euo pipefail

REPO="P0r0ro/xWaydroid"
BRANCH="${XWAYDROID_BRANCH:-main}"
SCOPE="user"
LAUNCH=1
UNINSTALL=0
SETUP_ARGS=()

for arg in "$@"; do
    case "$arg" in
        --system)    SCOPE="system" ;;
        --user)      SCOPE="user" ;;
        --no-launch) LAUNCH=0 ;;
        --gapps)     SETUP_ARGS+=(--gapps) ;;
        -y|--yes)    SETUP_ARGS+=(--yes) ;;
        --uninstall) UNINSTALL=1 ;;
        -h|--help)   sed -n '2,13p' "$0" 2>/dev/null | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown option: $arg" >&2; exit 2 ;;
    esac
done

if [[ "$SCOPE" == system ]]; then
    BIN_DIR="/usr/local/bin"
    DATA_DIR="/usr/local/share"
    SUDO="sudo"; [[ $EUID -eq 0 ]] && SUDO=""
else
    BIN_DIR="$HOME/.local/bin"
    DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
    SUDO=""
fi
APP_DIR="$DATA_DIR/applications"
ICON_DIR="$DATA_DIR/icons/hicolor"

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }

refresh_caches() {
    command -v update-desktop-database >/dev/null && $SUDO update-desktop-database -q "$APP_DIR" 2>/dev/null || true
    command -v gtk-update-icon-cache  >/dev/null && $SUDO gtk-update-icon-cache -q -t "$ICON_DIR" 2>/dev/null || true
}

if [[ $UNINSTALL == 1 ]]; then
    say "Removing xWaydroid ($SCOPE install)"
    $SUDO rm -f "$BIN_DIR/xwaydroid" "$APP_DIR/xwaydroid.desktop"
    $SUDO find "$ICON_DIR" -name 'xwaydroid.png' -delete 2>/dev/null || true
    refresh_caches
    say "Done. Waydroid and Weston were not removed."
    exit 0
fi

# Locate the source files: a local checkout, or download them (curl | bash).
SRC_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "$(dirname "${BASH_SOURCE[0]}")/xwaydroid" ]]; then
    SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    TMP="$(mktemp -d)"
    trap 'rm -rf "$TMP"' EXIT
    say "Downloading xWaydroid ($BRANCH)"
    curl -fsSL "https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz" | tar -xz -C "$TMP"
    SRC_DIR="$(find "$TMP" -mindepth 1 -maxdepth 1 -type d | head -n1)"
fi

say "Installing xwaydroid to $BIN_DIR"
$SUDO install -Dm755 "$SRC_DIR/xwaydroid"         "$BIN_DIR/xwaydroid"
$SUDO install -Dm644 "$SRC_DIR/xwaydroid.desktop" "$APP_DIR/xwaydroid.desktop"
for icon in "$SRC_DIR"/assets/icons/hicolor/*/apps/xwaydroid.png; do
    size="$(basename "$(dirname "$(dirname "$icon")")")"
    $SUDO install -Dm644 "$icon" "$ICON_DIR/$size/apps/xwaydroid.png"
done
refresh_caches

# Desktop launchers do not read shell rc files, so point Exec at the full path.
if [[ "$SCOPE" == user ]]; then
    sed -i "s|^Exec=xwaydroid|Exec=$BIN_DIR/xwaydroid|" "$APP_DIR/xwaydroid.desktop"
fi

case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *)
        echo
        echo "  $BIN_DIR is not in your PATH. Add it with:"
        echo "    bash/zsh : echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
        echo "    fish     : fish_add_path ~/.local/bin"
        echo
        ;;
esac

say "Setting up requirements"
"$BIN_DIR/xwaydroid" setup "${SETUP_ARGS[@]}"

if [[ $LAUNCH == 1 ]]; then
    if [[ -n "${DISPLAY:-}" ]]; then
        say "Launching xWaydroid"
        exec "$BIN_DIR/xwaydroid"
    else
        say "No graphical session detected. Start Android later with: xwaydroid"
    fi
fi
