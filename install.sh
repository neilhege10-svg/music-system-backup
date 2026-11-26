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
export WINESERVER="$AUDIO_WINE_DIR/usr/bin/wineserver"
export WINE="$WINELOADER"            # makes winetricks use the audio Wine, not system Wine
export WINEPREFIX="$HOME/.wine_music"
export WINE_WAYLAND_DRIVER=0
export GDK_BACKEND=x11

echo "[1/9] Installing dependencies..."
sudo pacman -S --needed yabridge yabridgectl winetricks wget tar zstd

echo
echo "[2/9] Restoring audio-wine..."
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
echo "[3/9] Verifying Wine version..."
WINE_VERSION="$("$WINELOADER" --version)"
echo "Detected: $WINE_VERSION"
if [[ "$WINE_VERSION" != *"9.21"* ]]; then
  echo
  echo "WARNING: Expected Wine 9.21, detected $WINE_VERSION"
  echo
fi

echo
echo "[4/9] Installing yabridgectl configuration..."
mkdir -p "$HOME/.config/yabridgectl"
cp "$REPO_DIR/yabridgectl/config.toml" "$HOME/.config/yabridgectl/config.toml"
echo "yabridgectl config installed."
# Note: yabridge.toml is deployed in step 8, after sync, because yabridge only
# reads it from ~/.vst/yabridge and ~/.vst3/yabridge (next to the bridged plugins).

echo
echo "[5/9] Updating .zshrc..."
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

# Added separately so existing setups also get it
if ! grep -q "alias mwine=" "$HOME/.zshrc" 2>/dev/null; then
  cat <<'EOF' >>"$HOME/.zshrc"
# Run anything (plugin installers, winecfg, regedit) with the audio Wine + music prefix
alias mwine='WINEPREFIX="$HOME/.wine_music" WINESERVER="$HOME/.local/share/audio-wine/usr/bin/wineserver" "$HOME/.local/share/audio-wine/usr/bin/wine"'
EOF
  echo "mwine alias added."
fi

echo
echo "[6/9] Checking music prefix..."
if [ ! -d "$WINEPREFIX" ]; then
  echo "No .wine_music detected. Creating fresh prefix..."
  "$WINELOADER" wineboot --init
  "$WINESERVER" -w
  echo "Prefix created."
else
  echo ".wine_music already exists."
fi

echo
echo "[7/9] Installing DXVK into the music prefix..."
# Without DXVK, many JUCE-based plugins (Valhalla, SD3, etc.) stop redrawing
# under WineD3D, so their GUIs look frozen.
D3D11_DLL="$WINEPREFIX/drive_c/windows/system32/d3d11.dll"
if [ -f "$D3D11_DLL" ] && grep -qai "dxvk" "$D3D11_DLL"; then
  echo "DXVK already installed."
else
  if ! command -v vulkaninfo >/dev/null 2>&1 || ! vulkaninfo --summary >/dev/null 2>&1; then
    echo "WARNING: Could not confirm a working Vulkan driver (install vulkan-tools to check)."
    echo "         DXVK needs Vulkan; on AMD that's the vulkan-radeon package."
  fi
  winetricks -q dxvk
  "$WINESERVER" -k || true
  echo "DXVK installed."
fi

echo
echo "[8/9] Running yabridge sync..."
yabridgectl sync --prune

# Deploy yabridge.toml (if present in the repo) to where yabridge actually reads it
if [ -f "$REPO_DIR/yabridge/yabridge.toml" ]; then
  for dir in "$HOME/.vst/yabridge" "$HOME/.vst3/yabridge"; do
    if [ -d "$dir" ]; then
      cp "$REPO_DIR/yabridge/yabridge.toml" "$dir/yabridge.toml"
      echo "yabridge.toml deployed to $dir"
    fi
  done
fi

echo
echo "[9/9] Deploying REAPER desktop launcher wrapper..."
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
echo "Install plugins with: mwine /path/to/installer.exe"
echo "Open REAPER from your launcher and rescan plugins."
