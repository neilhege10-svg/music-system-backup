#!/usr/bin/env bash
set -e

echo "========================================="
echo " Neil's Music Production Recovery Script"
echo "========================================="
echo

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUDIO_WINE_DIR="$HOME/.local/share/audio-wine"
BACKUP_ARCHIVE="$REPO_DIR/audio-wine-backup.tar.zst"
WINE_URL="https://archive.archlinux.org/packages/w/wine-staging/wine-staging-9.21-1-x86_64.pkg.tar.zst"

# Ensure isolated Wine environment is active for this script's execution
export WINELOADER="$AUDIO_WINE_DIR/usr/bin/wine"
export WINEPREFIX="$HOME/.wine_music"
export WINE_WAYLAND_DRIVER=0
export GDK_BACKEND=x11

echo "[1/8] Installing dependencies..."
sudo pacman -S --needed yabridge yabridgectl wget tar zstd

echo
echo "[2/8] Restoring audio-wine..."
if [ -x "$AUDIO_WINE_DIR/usr/bin/wine" ]; then
  echo "audio-wine already exists."
else
  if [ -f "$BACKUP_ARCHIVE" ]; then
    echo "Found local backup: $BACKUP_ARCHIVE"
    mkdir -p "$HOME/.local/share"
    tar -xaf "$BACKUP_ARCHIVE" -C "$HOME"
    echo "audio-wine restored from backup."
  else
    echo "No local backup found. Downloading Wine Staging 9.21..."
    mkdir -p "$AUDIO_WINE_DIR"
    TMPFILE="$(mktemp)"
    wget -O "$TMPFILE" "$WINE_URL"
    tar -xaf "$TMPFILE" -C "$AUDIO_WINE_DIR"
    rm "$TMPFILE"
    echo "audio-wine reconstructed from archive."
  fi
fi

echo
echo "[3/8] Verifying Wine version..."
WINE_VERSION="$("$WINELOADER" --version)"
echo "Detected: $WINE_VERSION"
if [[ "$WINE_VERSION" != *"9.21"* ]]; then
  echo
  echo "WARNING: Expected Wine 9.21, detected $WINE_VERSION"
  echo
fi

echo
echo "[4/8] Installing configuration files..."
mkdir -p "$HOME/.config/yabridge" "$HOME/.config/yabridgectl"
cp "$REPO_DIR/yabridge/yabridge.toml" "$HOME/.config/yabridge/yabridge.toml"
cp "$REPO_DIR/yabridgectl/config.toml" "$HOME/.config/yabridgectl/config.toml"
echo "Configs installed."

echo
echo "[5/8] Updating .zshrc..."
if ! grep -q "audio-wine/usr/bin/wine" "$HOME/.zshrc" 2>/dev/null; then
  cat <<'EOF' >>"$HOME/.zshrc"

# Music Production Environment
export WINELOADER="$HOME/.local/share/audio-wine/usr/bin/wine"
export WINEPREFIX="$HOME/.wine_music"
export WINE_WAYLAND_DRIVER=0
export GDK_BACKEND=x11

alias gwine='WINEPREFIX=~/.wine_general /usr/bin/wine'
EOF
  echo ".zshrc updated."
else
  echo ".zshrc already configured."
fi

echo
echo "[6/8] Checking music prefix..."
if [ ! -d "$WINEPREFIX" ]; then
  echo "No .wine_music detected. Creating fresh prefix..."
  "$WINELOADER" winecfg || true
else
  echo ".wine_music already exists."
fi

echo
echo "[7/8] Running yabridge sync..."
yabridgectl sync --prune

echo
echo "[8/8] Deploying REAPER desktop launcher wrapper..."
mkdir -p "$HOME/customscripts" "$HOME/.local/share/applications"
cp "$REPO_DIR/scripts/reaper-studio" "$HOME/customscripts/reaper-studio"
chmod +x "$HOME/customscripts/reaper-studio"

if [ -f "/usr/share/applications/cockos-reaper.desktop" ]; then
  cp /usr/share/applications/cockos-reaper.desktop "$HOME/.local/share/applications/"
  sed -i "s|^Exec=.*|Exec=$HOME/customscripts/reaper-studio %F|" "$HOME/.local/share/applications/cockos-reaper.desktop"
  echo "REAPER desktop entry updated."
else
  echo "REAPER not installed yet; skipping .desktop override."
fi

echo
echo "========================================="
echo " Recovery Complete"
echo "========================================="
echo "Run: source ~/.zshrc"
echo "Open REAPER from your launcher and rescan plugins."
