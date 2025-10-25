## 🔍 Troubleshooting

### Colors not updating

**Check theme mode:**
```bash
grep "mode" ~/.config/hecate/hecate.toml
# Should show: mode = "dynamic"
```

**Verify Pywal output:**
```bash
cat ~/.cache/wal/colors.json
# Should contain valid JSON with color0-15
```

**Check script permissions:**
```bash
ls -l ~/.config/hecate/scripts/*.sh
# All should be executable (rwxr-xr-x)
```

**Test manually:**
```bash
~/.config/hecate/scripts/hecate-system-colors.sh
# Check for error messages
```

### Waybar not reloading

```bash
# Check if Waybar is running
pgrep waybar

# Manually reload
pkill -SIGUSR2 waybar

# Check Waybar logs
journalctl -u waybar --user -f
```

### SwayNC colors wrong

```bash
# Verify symlink
ls -l ~/.config/swaync/color.css
# Should point to ~/.config/hecate/hecate.css

# Manually reload
swaync-client -rs

# Check SwayNC config
cat ~/.config/swaync/style.css | grep "@import"
```

### Rofi colors not working

```bash
# Check RASI file exists
cat ~/.config/rofi/theme/colors-rofi.rasi

# Test Rofi with color debug
rofi -show drun -theme ~/.config/rofi/config.rasi
```

### Low contrast / unreadable text

The smart contrast system should handle this, but if it fails:

```bash
# Check calculated luminance
~/.config/hecate/scripts/update_hecate_colors.sh | grep "luminance"

# Manually force dark mode colors in update_hecate_colors.sh:
SMART_FG="${COLOR7}"      # Force light text
SMART_FG_DIM="${COLOR8}"
SMART_BG_ALT="${COLOR1}"
```

### Pywal fails on certain images

```bash
# Try different Pywal backends
wal -i wallpaper.jpg --backend colorz
wal -i wallpaper.jpg --backend colorthief
wal -i wallpaper.jpg --backend haishoku

# Add to hecate-system-colors.sh:
wal -n -i "$WP_PATH" -q -t -s --backend colorz
```

---

## 🎨 Customization

### Adding a New Component

1. **Create update script:**
```bash
#!/usr/bin/env bash
# update_mycomponent_color.sh

COLOR_FILE="$HOME/.cache/wal/colors.json"
OUTPUT="$HOME/.config/mycomponent/colors.conf"

# Extract colors (reuse functions from update_hecate_colors.sh)
COLOR4=$(jq -r '.colors.color4' "$COLOR_FILE")

# Generate config
cat > "$OUTPUT" <<EOF
primary_color=$COLOR4
EOF
```

2. **Call from `update_hecate_colors.sh`:**
```bash
# Add before "Reloading components"
echo "Updating MyComponent..."
MYCOMPONENT_SCRIPT="$HOME/.config/hecate/scripts/update_mycomponent_color.sh"
if [ -f "$MYCOMPONENT_SCRIPT" ]; then
    bash "$MYCOMPONENT_SCRIPT"
    echo "✓ MyComponent updated"
fi
```

3. **Reload component:**
```bash
# Add to reload section
if pgrep -x mycomponent > /dev/null; then
    pkill -HUP mycomponent  # or appropriate signal
    echo "✓ MyComponent reloaded"
fi
```

### Using Custom Pywal Templates

Create `~/.config/wal/templates/mytemplate.conf`:

```
# MyApp Config
background={background}
foreground={foreground}
accent={color4}
```

Pywal will automatically generate:
`~/.cache/wal/mytemplate.conf`

### Adjusting Transparency Levels

Edit `update_hecate_colors.sh`:

```bash
# Current defaults:
COLOR4_RGBA=$(hex_to_rgba "$COLOR4" "0.15")      # 15%
COLOR4_RGBA_HOVER=$(hex_to_rgba "$COLOR4" "0.4") # 40%
BG_RGBA=$(hex_to_rgba "$BACKGROUND" "0.85")      # 85%

# Make more opaque:
COLOR4_RGBA=$(hex_to_rgba "$COLOR4" "0.25")      # 25%
BG_RGBA=$(hex_to_rgba "$BACKGROUND" "0.95")      # 95%
```

### Changing Blur Intensity

Edit `update_wlogout_color.sh`:

```bash
# Current blur
convert "$WP_PATH" -blur 0x10 ...

# Stronger blur
convert "$WP_PATH" -blur 0x20 ...

# Lighter blur
convert "$WP_PATH" -blur 0x5 ...

# Pixelate effect
convert "$WP_PATH" -scale 10% -scale 1000% ...
```

---

## 📝 Configuration Examples

### Example 1: Always Use Dark Colors

Edit `update_hecate_colors.sh`:

```bash
# Comment out the luminance check
# if is_light "$BG_LUMINANCE"; then
#     ...
# else

# Always use dark theme colors
SMART_FG="${COLOR7}"
SMART_FG_DIM="${COLOR8}"
SMART_FG_BRIGHT="${COLOR15}"
SMART_BG_ALT="${COLOR1}"
```

### Example 2: Static Color with Dynamic Wallpaper

Set `hecate.toml`:
```toml
mode = "static"
```

Colors won't update, but wallpaper still changes via Waypaper.

To manually update colors once:
```bash
mode = "dynamic" ~/.config/hecate/hecate.toml
# Change wallpaper
# Wait for update
mode = "static" ~/.config/hecate/hecate.toml
```

### Example 3: Multiple Color Schemes

Create preset files:

```bash
# Save current scheme
cp ~/.config/hecate/hecate.css ~/.config/hecate/schemes/blue-theme.css

# Switch between schemes
ln -sf ~/.config/hecate/schemes/blue-theme.css ~/.config/hecate/hecate.css
pkill -SIGUSR2 waybar
swaync-client -rs
```

---

## 🐛 Known Issues

1. **SwayNC doesn't reload automatically**
   - Solution: Run `swaync-client -rs` manually
   - Reason: SwayNC has no signal-based reload

2. **Rofi requires restart**
   - Solution: Close and reopen Rofi
   - Reason: Config loaded at startup

3. **Starship colors lag behind**
   - Solution: Close and reopen terminal
   - Reason: Prompt generated once per session

4. **ImageMagick blur is slow**
   - Solution: Reduce wallpaper resolution or disable blur
   - Alternative: Use GPU-accelerated tools

---

## Quick Reference Card

```bash
# Check theme mode
grep mode ~/.config/hecate/hecate.toml

# Force color update
~/.config/hecate/scripts/update_hecate_colors.sh

# Reload components
pkill -SIGUSR2 waybar
swaync-client -rs

# View current colors
cat ~/.config/hecate/hecate.css | grep "@define-color"

# Test with wallpaper
wal -i ~/Pictures/wallpaper.jpg
~/.config/hecate/scripts/update_hecate_colors.sh

# Debug mode
bash -x ~/.config/hecate/scripts/hecate-system-colors.sh
```
