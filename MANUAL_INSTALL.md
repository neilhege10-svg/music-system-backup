# Manual Installation Guide

This document explains how to manually rebuild the complete audio environment without using the automated installation script.

---

# Overview

The system consists of five major components:

1. Wine Staging 9.21 runtime
2. Dedicated Wine prefix
3. yabridge
4. yabridgectl
5. REAPER desktop launcher wrapper (`reaper-studio`)

The objective is to isolate audio production from the system Wine installation.

This allows newer Wine releases to coexist with a stable music-production environment.

---

# Why Use A Dedicated Wine Runtime?

Many Linux musicians rely on Windows VST plugins through Wine and yabridge.

Historically, some Wine updates have introduced regressions affecting:

* Plugin GUI rendering
* Window embedding
* Input handling
* Plugin scanning
* DAW integration

By maintaining a dedicated Wine runtime, the audio environment remains stable regardless of future system updates.

---

# Step 1: Install Dependencies

Install the required packages:

```bash
sudo pacman -S yabridge yabridgectl wget tar zstd
```

---

# Step 2: Create The Dedicated Wine Runtime

Create a storage location:

```bash
mkdir -p ~/.local/share/audio-wine
```

Download Wine Staging 9.21:

```bash
wget https://archive.archlinux.org/packages/w/wine-staging/wine-staging-9.21-1-x86_64.pkg.tar.zst
```

Extract the package:

```bash
tar -xaf wine-staging-9.21-1-x86_64.pkg.tar.zst \
    -C ~/.local/share/audio-wine
```

Verify the installation:

```bash
~/.local/share/audio-wine/usr/bin/wine --version
```

Expected output:

```text
wine-9.21 (Staging)
```

---

# Step 3: Configure Environment Variables

Add the following to your shell configuration:

```bash
export WINELOADER="$HOME/.local/share/audio-wine/usr/bin/wine"
export WINEPREFIX="$HOME/.wine_music"

export WINE_WAYLAND_DRIVER=0
export GDK_BACKEND=x11

alias gwine='WINEPREFIX=~/.wine_general /usr/bin/wine'
```

Reload the shell:

```bash
source ~/.zshrc
```

---

# Step 4: Create The Dedicated Wine Prefix

Generate the audio-production prefix:

```bash
$WINELOADER winecfg
```

This creates:

```text
~/.wine_music
```

---

# Step 5: Deploy yabridge Configuration

Create configuration directories:

```bash
mkdir -p ~/.config/yabridge
mkdir -p ~/.config/yabridgectl
```

Copy the provided configuration files:

```bash
cp yabridge/yabridge.toml ~/.config/yabridge/
cp yabridgectl/config.toml ~/.config/yabridgectl/
```

---

# Step 6: Configure Plugin Paths

Open:

```text
~/.config/yabridgectl/config.toml
```

Update the plugin directory path if necessary.

Example:

```toml
plugin_dirs = ['/run/media/USERNAME/DRIVE_NAME/Linux_VST']
```
*(This is where you put your plugin `.dll` and `.vst3` files).*

---

# Step 7: Synchronize Plugins

Once you have installed your plugins and placed them in `plugin_dirs`, run:

```bash
yabridgectl sync --prune
```

This creates the required bridge files and plugin wrappers.

---

# Step 8: Configure Desktop Launcher (Wayland / App Launchers)

Application launchers (Rofi, Wofi, etc.) do not load `~/.zshrc` environment variables, and external drives under `/run/media/` may not be mounted before REAPER starts.

1. Deploy the wrapper script to `~/customscripts`:
   ```bash
   mkdir -p ~/customscripts
   cp scripts/reaper-studio ~/customscripts/
   chmod +x ~/customscripts/reaper-studio
   ```

2. Override the system `.desktop` entry:
   ```bash
   mkdir -p ~/.local/share/applications
   cp /usr/share/applications/cockos-reaper.desktop ~/.local/share/applications/
   sed -i "s|^Exec=.*|Exec=$HOME/customscripts/reaper-studio %F|" ~/.local/share/applications/cockos-reaper.desktop
   ```

---

# Step 9: Configure REAPER

Open REAPER from your application launcher or terminal.

Perform a full plugin rescan.

Verify that:

* Plugins appear correctly
* Plugin GUIs open correctly
* Plugin state is saved and restored properly

---

# Troubleshooting

## Verify Wine Runtime

```bash
$WINELOADER --version
```

Expected:

```text
wine-9.21 (Staging)
```

---

## Verify Wine Prefix

```bash
echo $WINEPREFIX
```

Expected:

```text
/home/<user>/.wine_music
```

---

## Verify Plugin Detection

```bash
yabridgectl status
```

---

## Rebuild Plugin Bridges

```bash
yabridgectl sync --prune
```

---

# Additional Notes

Large sample libraries such as Kontakt libraries, drum libraries, and other content libraries should be stored separately from the Wine runtime and Wine prefix.

Keeping libraries independent makes backups significantly smaller and simplifies migration between systems.

---

## Installing Windows Plugins

Always install audio plugins inside a terminal with your Zsh environment loaded (or explicitly invoke `$WINELOADER`) so they install into `~/.wine_music` using Wine 9.21 rather than system Wine:

```bash
$WINELOADER "path/to/your/plugin/installer.exe"
```

---

## General Purpose Wine

For non-audio software or games, use `gwine` instead of `wine`:

```bash
gwine "~/Downloads/game.exe"
```