# Hecate Theme System Documentation

## 📋 Table of Contents

- [Overview](#overview)
- [How It Works](#how-it-works)
- [Components](#components)
- [Installation](#installation)
- [Configuration](#configuration)
- [Script Reference](#script-reference)
- [Troubleshooting](#troubleshooting)
- [Customization](#customization)

---

## 🎨 Overview


### Key Features

- **Automatic Color Extraction**: Uses Pywal to extract colors from wallpapers
- **Smart Contrast Detection**: Automatically adjusts foreground colors for light/dark backgrounds
- **Centralized Configuration**: Single source of truth for all component colors
- **Real-time Updates**: Components reload automatically when wallpaper changes
- **Mode Switching**: Toggle between dynamic (wallpaper-based) and static themes    `run hecate theme to change`
- **Component Support**: Waybar, SwayNC, Rofi, Wlogout, Starship, Quickshell, GTK, Qt (Kvantum)

### Supported Components

| Component | Format | Update Method |
|-----------|--------|---------------|
| Waybar | CSS (import) | SIGUSR2 signal |
| SwayNC | CSS (import) | swaync-client |
| Rofi | RASI | Manual reload |
| Wlogout | CSS | On launch |
| Starship | TOML | Next prompt |
|Quickshell|QML| Reloads itself|
| GTK 3/4 | `Hecate` theme (Materia-dark recolored by `app-theme.py`) | GTK3 live, GTK4 on relaunch |
| Qt | Kvantum `Hecate` theme (MateriaDark recolored) | On relaunch |

---

## 🔄 How It Works

### The Update Flow

```
┌─────────────────────────────────────────────────────────────┐
│    USER CHANGES WALLPAPER                                   │
│    (via waypaper)                                           │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│    WAYPAPER POST-COMMAND HOOK                               │
│    ~/.config/hecate/scripts/hecate-system-colors.sh         │
│    • Checks theme mode (dynamic/static)                     │
│    • Exits if mode = static                                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│    PYWAL COLOR EXTRACTION                                   │
│    wal -n -i "$WALLPAPER" -q -t -s                          │
│    • Generates ~/.cache/wal/colors.json                     │
│    • Creates 16-color palette + special colors              │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│    CENTRALIZED COLOR GENERATION                             │
│    ~/.config/hecate/scripts/update_hecate_colors.sh         │
│    • Calculates background luminance                        │
│    • Applies smart contrast adjustments                     │
│    • Generates master hecate.css                            │
│    • Creates RGBA variants                                  │
│    • Creates symlinks for components                        │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│    COMPONENT-SPECIFIC UPDATES                               │
│     ├─ update_wlogout_color.sh     (Wlogout CSS + blur)     │
│     └─ colors-rofi.rasi            (Rofi RASI format)       │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│    COMPONENT RELOAD                                         │
│    • Waybar:  pkill -SIGUSR2 waybar                         │
│    • SwayNC:  swaync-client -rs                             │
│    • Starship: automatic on next prompt                     │
│    • Rofi:     on next launch                               │
│    • Wlogout:  on next launch                               │
└─────────────────────────────────────────────────────────────┘
```

### File Structure

```
~/.config/
├── hecate/
│   ├── hecate.toml                    # Main config (theme mode)
│   ├── hecate.css                     # Master color definitions
│   └── scripts/
│       ├── hecate-system-colors.sh    # Waypaper hook (entry point)
│       ├── update_hecate_colors.sh    # Central color generator
│       └── update_wlogout_color.sh    # Wlogout colors + blur
├── waybar/
│   └── color.css -> ~/.config/hecate/hecate.css (symlink)
├── swaync/
│   └── color.css -> ~/.config/hecate/hecate.css (symlink)
├── rofi/
│   └── theme/colors-rofi.rasi         # Generated RASI file
├── wlogout/
│   └── color.css                      # Generated CSS
├── starship.toml                      # Palette block recolored by set-wallpaper.sh
└── waypaper/
    └── config.ini                     # Contains post_command hook

~/.cache/
├── wal/
│   ├── colors.json                    # Pywal output (source)
│   └── colors.sh                      # Shell variables
└── wlogout/
    └── blurred_wallpaper.png          # Blurred background
```

---

## 🔧 Components

### 1. Master Color File (`hecate.css`)

The heart of the system. All colors are defined here using GTK's `@define-color` syntax.

**Color Categories:**

```css
/* Base Colors (from Pywal) */
@define-color color0 through color15
@define-color background
@define-color foreground
@define-color cursor

/* Smart Contrast Variants */
@define-color fg              /* Auto-adjusted for contrast */
@define-color fg-dim          /* Dimmed text */
@define-color fg-bright       /* Bright text */
@define-color bg-alt          /* Alternative background */

/* Semantic Colors */
@define-color primary         /* Main accent (color4) */
@define-color secondary       /* Secondary accent (color6) */
@define-color accent          /* Highlight (color5) */
@define-color success         /* Green (color2) */
@define-color warning         /* Yellow (color3) */
@define-color error           /* Red (color1) */

/* RGBA Variants (transparency) */
@define-color bg_rgba         /* 85% opacity */
@define-color bg_rgba_light   /* 70% opacity */
@define-color color4_rgba     /* 15% opacity */
@define-color color4_rgba_hover /* 40% opacity */
/* ... and more */
```

### 2. Smart Contrast System

Hecate calculates background luminance to determine if the wallpaper is light or dark, then adjusts colors accordingly:

**Luminance Calculation:**
```bash
# Converts RGB to relative luminance (0.0 - 1.0)
L = 0.2126 × R + 0.7152 × G + 0.0722 × B

# If L > 0.5: Light background
#   - fg = color0 (dark text)
#   - fg-dim = color8
#   - bg-alt = color15
# Else: Dark background
#   - fg = color7 (light text)
#   - fg-dim = color8
#   - bg-alt = color1
```

This ensures text is always readable regardless of wallpaper brightness.

### 3. Component Integration

#### Waybar & SwayNC
- Import colors via symlink: `@import "color.css"`
- Use variables: `color: @primary;`
- Reload via signal: `pkill -SIGUSR2 waybar`

#### Rofi
- Separate RASI file (can't import CSS)
- Uses same color mapping
- Variables accessed via: `@primary`

#### Wlogout
- Imports colors from generated CSS
- Includes blurred wallpaper generation
- Uses ImageMagick for blur effect

#### Starship
- Not part of the pywal flow above: `set-wallpaper.sh` (the Quickshell wallpaper picker) rewrites only the
  `[palettes.hecate]` block at the bottom of `~/.config/starship/starship.toml` from the matugen colors
  (`primary`, `secondary`, `tertiary`, `error`, `muted` = outline)
- Edit the rest of `starship.toml` freely; keep the palette block last
- Updates on next shell prompt

### Quickshell
- Generates colors by itself, by reading `hecate.css`.
- ALl widgets reads color from `~/.config/quickshell/widgets/ColorManager.qml`

---

## 📦 Installation

### Prerequisites

```bash
# Required to set colors
python-pywal jq bc imagemagick
# Components
waybar swaync rofi wlogout starship waypaper quickshell-git
```

### Setup

1. **Create directory structure:**
```bash
mkdir -p ~/.config/hecate/scripts
mkdir -p ~/.cache/wal
mkdir -p ~/.cache/wlogout
```

2. **Copy scripts:**
```bash
# Place the provided scripts in:
~/.config/hecate/scripts/hecate-system-colors.sh
~/.config/hecate/scripts/update_hecate_colors.sh
~/.config/hecate/scripts/update_wlogout_color.sh
```

3. **Make scripts executable:**
```bash
chmod +x ~/.config/hecate/scripts/*.sh
```

4. **Configure Waypaper:**

Edit `~/.config/waypaper/config.ini`:
```ini
[Settings]
post_command = ~/.config/hecate/scripts/hecate-system-colors.sh
```

5. **Create theme config:**

`~/.config/hecate/hecate.toml`:
```toml
# Hecate Theme Configuration
mode = "dynamic"  # or "static"
```

6. **Component CSS files:**

**Waybar** (`~/.config/waybar/style.css`):
```css
@import "color.css";

window#waybar {
    background: @bg_rgba;
    color: @fg;
}
/* ... rest of your styles ... */
```

**SwayNC** (`~/.config/swaync/style.css`):
```css
@import "color.css";

.notification {
    background: @bg_rgba;
    color: @fg;
    border: 2px solid @primary;
}
/* ... rest of your styles ... */
```

**Rofi** (`~/.config/rofi/config.rasi`):
```rasi
@import "~/.config/rofi/theme/colors-rofi.rasi"

window {
    background-color: @background;
    text-color: @foreground;
}
/* ... rest of your config ... */
```

---

## ⚙️ Configuration

### Theme Modes

Edit `~/.config/hecate/hecate.toml`:

```toml
# Dynamic mode: Colors change with wallpaper
mode = "dynamic"

# Static mode: Colors don't change (wallpaper still changes)
mode = "static"
```

### Color Mapping

The system uses a standard 16-color palette:

| Variable | Purpose | Example Use |
|----------|---------|-------------|
| `color0` | Black / Dark gray | Terminal background |
| `color1` | Red | Errors, delete actions |
| `color2` | Green | Success, confirmations |
| `color3` | Yellow | Warnings, pending |
| `color4` | Blue | Primary accent, links |
| `color5` | Magenta | Secondary accent |
| `color6` | Cyan | Info, highlights |
| `color7` | Light gray / White | Text |
| `color8-15` | Bright variants | Emphasized text |

### Customizing Color Roles

Edit `update_hecate_colors.sh` to change semantic mappings:

```bash
# Change primary accent from blue to magenta
@define-color primary ${COLOR5};  # was COLOR4

# Change error color from red to orange
@define-color error ${COLOR9};    # was COLOR1
```

---

## 📚 Script Reference

### 1. `hecate-system-colors.sh`

**Purpose:** Entry point triggered by Waypaper
**Location:** `~/.config/hecate/scripts/`

**What it does:**
1. Checks theme mode from `hecate.toml`
2. Exits if mode is "static"
3. Runs Pywal on the new wallpaper
4. Validates `colors.json` generation
5. Calls `update_hecate_colors.sh`

**Usage:**
```bash
# Automatic (via Waypaper)
# or manual:
~/.config/hecate/scripts/hecate-system-colors.sh
```

**Exit Codes:**
- `0`: Success
- `1`: Wallpaper not found, Pywal failed, or update script failed

### 2. `update_hecate_colors.sh`

**Purpose:** Central color generation and distribution
**Location:** `~/.config/hecate/scripts/`

**What it does:**
1. Extracts 16 colors + specials from Pywal
2. Calculates background luminance
3. Applies smart contrast adjustments
4. Generates master `hecate.css`
5. Creates symlinks for Waybar/SwayNC
6. Generates Rofi RASI file
7. Calls component-specific update scripts
8. Reloads Waybar and SwayNC

**Manual Usage:**
```bash
~/.config/hecate/scripts/update_hecate_colors.sh
```

**Functions:**
- `extract_color()`: Safely extracts color from JSON
- `hex_to_rgba()`: Converts hex to RGBA with alpha
- `hex_to_rgb()`: Converts hex to RGB tuple
- `get_luminance()`: Calculates relative luminance
- `is_light()`: Determines if background is light

### 4. `update_wlogout_color.sh`

**Purpose:** Update Wlogout colors and generate blurred background
**Location:** `~/.config/hecate/scripts/`

**What it does:**
1. Extracts all 16 colors from Pywal JSON
2. Generates `~/.config/wlogout/color.css`
3. Creates blurred wallpaper using ImageMagick
4. Optionally recolors SVG icons

**Blur Parameters:**
- Blur: `0x10` (sigma)
- Scale: `1920x1080` (full HD)
- Gravity: `center`

**Manual Usage:**
```bash
~/.config/hecate/scripts/update_wlogout_color.sh
```

---

