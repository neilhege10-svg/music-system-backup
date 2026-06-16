# 🎹 Neil's Linux Music Production Recovery Guide

This repository contains the configuration and documentation required to reconstruct my Windows VST workflow on Arch Linux / CachyOS using REAPER, yabridge, and a dedicated Wine environment.

The primary goal of this setup is **stability**, not novelty.

The entire environment is intentionally pinned to Wine Staging 9.21 because newer Wine versions introduced plugin GUI and compatibility issues when used with REAPER and yabridge.

---

# ⚠️ Important Design Philosophy

This system intentionally separates music production from the system Wine installation.

Current system Wine may be:

```text
wine-staging 11.x
wine-cachyos-opt 10.x
Proton 11.x
```

These versions are free to update normally.

Music production uses a completely isolated runtime:

```text
~/.local/share/audio-wine
```

which contains:

```text
Wine Staging 9.21
```

This prevents system updates from breaking plugin compatibility.

Do not casually upgrade the audio Wine environment.

---

# Architecture Overview

```text
Linux Host
│
├── REAPER
│
├── System Wine
│   ├── Games
│   ├── Steam
│   └── General Applications
│
└── Music Production Environment
    │
    ├── Wine Staging 9.21
    │   └── ~/.local/share/audio-wine
    │
    ├── Dedicated Wine Prefix
    │   └── ~/.wine_music
    │
    ├── Yabridge
    │
    ├── Yabridgectl
    │
    ├── Linux_VST
    │
    └── External Sample Libraries
```

---

# Repository Contents

```text
music-system-backup/
├── README.md
├── yabridge/
│   └── yabridge.toml
├── yabridgectl/
│   └── config.toml
└── zsh/
    └── music-env.zsh
```

These files are small configuration files only.

Large assets are stored separately.

---

# Required Backup Assets

This repository alone is NOT enough to fully restore the studio.

The following assets must also be preserved:

## Audio Runtime

```text
~/.local/share/audio-wine
```

Contains:

```text
Wine Staging 9.21
```

Size:

```text
~490 MB
```

---

## Music Prefix

```text
~/.wine_music
```

Contains:

```text
Plugin support files
Registry data
Plugin application data
Wine configuration
```

Size:

```text
~2.3 GB
```

---

## Plugin Installers

External backup location.

Contains installers for:

* FabFilter
* Native Instruments
* Kontakt
* Superior Drummer
* Analog Obsession
* Other production plugins

---

## Sample Libraries

Stored separately.

Examples:

* Kontakt Libraries
* Superior Drummer Libraries

These are intentionally NOT included in the Wine environment.

---

# Recovery Level 1 (Preferred)

Use this when backup archives are available.

## Step 1

Install:

```bash
sudo pacman -S reaper yabridge yabridgectl --needed
```

---

## Step 2

Restore:

```text
~/.local/share/audio-wine
```

from backup.

---

## Step 3

Restore:

```text
~/.wine_music
```

from backup.

---

## Step 4

Deploy configuration files.

```bash
mkdir -p ~/.config/yabridge
mkdir -p ~/.config/yabridgectl
```

Copy repository files:

```bash
cp yabridge/yabridge.toml ~/.config/yabridge/
cp yabridgectl/config.toml ~/.config/yabridgectl/
```

---

## Step 5

Restore shell configuration.

Add the environment variables from:

```text
zsh/music-env.zsh
```

to:

```bash
~/.zshrc
```

Reload:

```bash
source ~/.zshrc
```

---

## Step 6

Verify Wine loader.

```bash
$WINELOADER --version
```

Expected:

```text
wine-9.21 (Staging)
```

---

## Step 7

Rebuild plugin bridges.

```bash
yabridgectl sync --prune
```

---

## Step 8

Open REAPER.

Clear plugin cache.

Run full plugin rescan.

Studio restored.

---

# Recovery Level 2 (Reinstall Plugins)

Use if:

```text
~/.wine_music
```

is unavailable.

---

## Step 1

Restore:

```text
~/.local/share/audio-wine
```

---

## Step 2

Deploy configuration files.

---

## Step 3

Create fresh prefix.

```bash
$WINELOADER winecfg
```

This automatically creates:

```text
~/.wine_music
```

---

## Step 4

Reinstall plugins from archived installers.

---

## Step 5

Run:

```bash
yabridgectl sync --prune
```

---

## Step 6

Rescan inside REAPER.

---

# Recovery Level 3 (Disaster Recovery)

Use only if:

* Backups are lost
* Cloud backups are lost
* External drives are lost
* Only this Git repository remains

---

## Recreate Audio Wine

Create directory:

```bash
mkdir -p ~/.local/share/audio-wine
```

Download Wine Staging 9.21:

```bash
wget https://archive.archlinux.org/packages/w/wine-staging/wine-staging-9.21-1-x86_64.pkg.tar.zst
```

Extract:

```bash
tar -C ~/.local/share/audio-wine -xavf wine-staging-9.21-1-x86_64.pkg.tar.zst
```

Remove archive:

```bash
rm wine-staging-9.21-1-x86_64.pkg.tar.zst
```

Verify:

```bash
~/.local/share/audio-wine/usr/bin/wine --version
```

Expected:

```text
wine-9.21 (Staging)
```

---

## Recreate Music Prefix

```bash
export WINELOADER="$HOME/.local/share/audio-wine/usr/bin/wine"
export WINEPREFIX="$HOME/.wine_music"

$WINELOADER winecfg
```

---

## Reinstall Plugins

Use archived installers.

Restore sample libraries.

Run:

```bash
yabridgectl sync --prune
```

Rescan REAPER.

---

# Why Wine 9.21?

Historical note:

Newer Wine versions introduced issues affecting REAPER and yabridge workflows.

Observed issues included:

* Plugin GUI interaction bugs
* Window embedding issues
* Plugin scanning instability
* Various compatibility regressions reported by Linux audio users

Wine Staging 9.21 was identified as the last known stable version for this workflow.

The audio runtime is intentionally frozen to preserve project compatibility and workflow reliability.

Future upgrades should only be performed after thorough testing.

---

# Maintenance

After changing any music-production configuration:

```bash
cp ~/.config/yabridge/yabridge.toml ./yabridge/
cp ~/.config/yabridgectl/config.toml ./yabridgectl/
```

Commit changes:

```bash
git add .
git commit -m "Update music environment"
git push
```

Keep backups current.

Future Neil will appreciate it.

