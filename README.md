# Linux Music Production Recovery Toolkit

A recovery and deployment toolkit for Linux musicians using Windows VST plugins through Wine, yabridge, and REAPER.

This repository was created to solve a common problem in Linux audio production:

Wine updates can occasionally introduce regressions that affect plugin scanning, plugin GUI behavior, or DAW compatibility. While newer Wine versions may improve gaming and application support, they are not always ideal for music-production workflows.

Rather than freezing the entire system on an older Wine version, this project isolates music production into its own dedicated environment using:

* Wine Staging 9.21
* A dedicated Wine prefix (`~/.wine_music`)
* yabridge & yabridgectl
* REAPER with an isolated desktop launcher wrapper (`reaper-studio`)

This allows the rest of the system to continue updating normally while preserving a known-working audio environment.

---

## Features

* Isolated Wine runtime for audio production
* Dedicated Wine prefix for plugins and audio software
* Automatic yabridge deployment
* Automatic environment configuration
* Desktop launcher wrapper (`reaper-studio`) for Wayland/app launchers with automatic external drive mounting
* Recovery from backup archives
* Fallback reconstruction using archived Wine packages
* Compatible with Arch Linux and CachyOS

---

## Repository Structure

```text
music-system-backup/
├── README.md
├── MANUAL_INSTALL.md
├── plugin-list.md
├── install.sh
├── backup.sh
├── .zshrc_snippet
├── scripts/
│   └── reaper-studio
├── yabridge/
│   └── yabridge.toml
└── yabridgectl/
    └── config.toml
```

---

## Quick Start

Clone the repository:

```bash
git clone https://github.com/neilhege10-svg/music-system-backup
cd music-system-backup
```

Make the installer executable:

```bash
chmod +x install.sh
```

Run the installer:

```bash
./install.sh
```

The installer will automatically:

* Install required packages
* Restore or recreate the isolated Wine runtime
* Deploy yabridge configuration
* Configure environment variables
* Create a dedicated Wine prefix
* Run yabridgectl synchronization
* Deploy the `reaper-studio` desktop launcher wrapper and override REAPER's `.desktop` entry

---

## Important: Verify Plugin Paths

The installer automatically deploys the included `yabridgectl/config.toml` file.

However, the plugin directory paths defined in this file are system-specific and may not match your storage layout.

After running the installer, review:

```text
~/.config/yabridgectl/config.toml
```

and verify that the `plugin_dirs` entry points to your actual Windows VST location.

Example:

```toml
plugin_dirs = [
'/run/media/USERNAME/DRIVE_NAME/Linux_VST'
]
```

If your VST collection is stored on a different drive, partition, or mount point, update the path accordingly before running:

```bash
yabridgectl sync --prune
```

You can verify the correct mount location using:

```bash
lsblk -f
```

or by inspecting the mounted drive in your file manager.

Failure to update the plugin path may result in yabridge detecting no plugins during synchronization.

---

## Included Components

### Audio Wine Runtime

Dedicated Wine Staging 9.21 installation used exclusively for music production.

### Wine Prefix

Dedicated Wine environment for Windows plugins and audio software.

### yabridge Configuration

Preconfigured bridge settings for Windows VST integration.

### Desktop Launcher Wrapper (`reaper-studio`)

Ensures REAPER inherits the isolated Wine runtime, prefix, and X11/XWayland flags when launched from desktop application menus (Rofi, Wofi, etc.), and automatically mounts external plugin storage if disconnected.

### Recovery Scripts

Automated restoration and deployment tools.

---

## Manual Installation

If you prefer to rebuild everything manually or want to understand how the system works internally, see:

```text
MANUAL_INSTALL.md
```

---

## Disclaimer

This repository focuses on the Wine, yabridge, and plugin-hosting environment.

Commercial plugin installers, licenses, and sample libraries are not included and must be obtained separately from their respective vendors.