#!/usr/bin/env bash

COLOR_FILE="$HOME/.cache/wal/colors.json"
CSS_OUTPUT="$HOME/.config/wlogout/colors.css"
STYLE_OUTPUT="$HOME/.config/wlogout/style.css"
WALLPAPER_OUTPUT="$HOME/.cache/wlogout/blurred_wallpaper.png"

# Verify colors.json exists
if [ ! -f "$COLOR_FILE" ]; then
    echo "Error: wal colors.json not found at $COLOR_FILE"
    exit 1
fi

# Verify jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed"
    exit 1
fi

# Extract colors
extract_color() {
    local key="$1"
    local value
    value=$(jq -r "$key" "$COLOR_FILE" 2>/dev/null)
    if [ -z "$value" ] || [ "$value" = "null" ]; then
        echo "Error: Failed to extract $key"
        exit 1
    fi
    echo "$value"
}

# Extract all colors
COLOR0=$(extract_color '.colors.color0')
COLOR1=$(extract_color '.colors.color1')
COLOR2=$(extract_color '.colors.color2')
COLOR3=$(extract_color '.colors.color3')
COLOR4=$(extract_color '.colors.color4')
COLOR5=$(extract_color '.colors.color5')
COLOR6=$(extract_color '.colors.color6')
COLOR7=$(extract_color '.colors.color7')
COLOR8=$(extract_color '.colors.color8')
COLOR9=$(extract_color '.colors.color9')
COLOR10=$(extract_color '.colors.color10')
COLOR11=$(extract_color '.colors.color11')
COLOR12=$(extract_color '.colors.color12')
COLOR13=$(extract_color '.colors.color13')
COLOR14=$(extract_color '.colors.color14')
COLOR15=$(extract_color '.colors.color15')
BACKGROUND=$(extract_color '.special.background')
FOREGROUND=$(extract_color '.special.foreground')

# Create wlogout cache directory
mkdir -p "$HOME/.cache/wlogout"
mkdir -p "$(dirname "$CSS_OUTPUT")"

# Generate blurred wallpaper from current wallpaper
CONFIG="$HOME/.config/waypaper/config.ini"
if [ -f "$CONFIG" ]; then
    WP_PATH=$(grep '^wallpaper' "$CONFIG" | cut -d '=' -f2 | tr -d ' ')
    WP_PATH="${WP_PATH/#\~/$HOME}"

    if [ -f "$WP_PATH" ] && command -v convert &> /dev/null; then
        convert "$WP_PATH" -blur 0x10 -scale 1920x1080^ -gravity center -extent 1920x1080 "$WALLPAPER_OUTPUT" 2>/dev/null
        echo "✓ Generated blurred wallpaper"
    fi
fi

# Create backup
if [ -f "$CSS_OUTPUT" ]; then
    cp "$CSS_OUTPUT" "${CSS_OUTPUT}.backup"
fi

# Generate colors.css
cat > "$CSS_OUTPUT" <<EOF
/* Wlogout Colors - Generated from Pywal */
/* Generated: $(date '+%Y-%m-%d %H:%M:%S') */

* {
    --background: ${BACKGROUND};
    --foreground: ${FOREGROUND};
    --color0: ${COLOR0};
    --color1: ${COLOR1};
    --color2: ${COLOR2};
    --color3: ${COLOR3};
    --color4: ${COLOR4};
    --color5: ${COLOR5};
    --color6: ${COLOR6};
    --color7: ${COLOR7};
    --color8: ${COLOR8};
    --color9: ${COLOR9};
    --color10: ${COLOR10};
    --color11: ${COLOR11};
    --color12: ${COLOR12};
    --color13: ${COLOR13};
    --color14: ${COLOR14};
    --color15: ${COLOR15};
}

/* Semantic color names for wlogout */
@define-color background ${BACKGROUND};
@define-color foreground ${FOREGROUND};
@define-color primary ${COLOR4};
@define-color on_primary ${FOREGROUND};
@define-color shadow ${COLOR4};
@define-color accent ${COLOR4};
EOF

# Generate style.css with pywal colors (matching your original structure)
cat > "$STYLE_OUTPUT" <<EOF
/* Wlogout Dynamic Theme - Generated from Pywal */
/* Generated: $(date '+%Y-%m-%d %H:%M:%S') */

* {
    font-family: "Fira Sans Semibold", FontAwesome, Roboto, Helvetica, Arial, sans-serif;
    background-image: none;
    transition: 20ms;
    box-shadow: none;
}

window {
    background: url("../../.cache/wlogout/blurred_wallpaper.png");
    background-size: cover;
    font-size: 16pt;
}

button {
    background-repeat: no-repeat;
    background-position: center;
    background-size: 20%;
    animation: gradient_f 20s ease-in infinite;
    border-radius: 80px;
    border: 0px;
    transition: all 0.3s cubic-bezier(.55, 0.0, .28, 1.682), box-shadow 0.2s ease-in-out, background-color 0.2s ease-in-out;
    color: ${BACKGROUND};
    background-color: alpha(${COLOR4}, 0.2);
}

button:focus {
    background-color: alpha(${COLOR4}, 0.5);
    background-size: 25%;
    border: 0px;
}

button:hover {
    background-color: alpha(${COLOR4}, 0.9);
    opacity: 0.8;
    color: ${COLOR0};
    background-size: 30%;
    margin: 30px;
    border-radius: 80px;
    box-shadow: 0 0 50px ${BACKGROUND};
}

button span {
    font-size: 1.2em;
}

#lock {
    margin: 10px;
    border-radius: 20px;
    background-image: image(url("icons/lock.svg"));
}

#logout {
    margin: 10px;
    border-radius: 20px;
    background-image: image(url("icons/logout.svg"));
}

#suspend {
    margin: 10px;
    border-radius: 20px;
    background-image: image(url("icons/suspend.svg"));
}

#hibernate {
    margin: 10px;
    border-radius: 20px;
    background-image: image(url("icons/hibernate.svg"));
}

#shutdown {
    margin: 10px;
    border-radius: 20px;
    background-image: image(url("icons/shutdown.svg"));
}

#reboot {
    margin: 10px;
    border-radius: 20px;
    background-image: image(url("icons/reboot.svg"));
}
EOF

echo "✓ Wlogout theme updated (Primary: $COLOR4)"

# Optional: Recolor SVG icons if they exist
SVG_DIR="$HOME/.config/wlogout/icons"
if [ -d "$SVG_DIR" ] && command -v sed &> /dev/null; then
    echo "Updating SVG icon colors..."
    for svg in "$SVG_DIR"/*.svg; do
        if [ -f "$svg" ]; then
            # Replace common fill colors with foreground color
            sed -i "s/fill=\"#[0-9a-fA-F]\{6\}\"/fill=\"${FOREGROUND}\"/g" "$svg"
            sed -i "s/stroke=\"#[0-9a-fA-F]\{6\}\"/stroke=\"${FOREGROUND}\"/g" "$svg"
        fi
    done
    echo "✓ SVG icons recolored"
fi
