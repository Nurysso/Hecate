package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

type ThemeConfig struct {
	Mode            string            `json:"mode"`
	CurrentTheme    string            `json:"currentTheme"`
	Colors          map[string]string `json:"colors"`
	AvailableThemes []ThemePreset     `json:"availableThemes"`
}

type ThemePreset struct {
	Name        string            `json:"name"`
	Description string            `json:"description"`
	Colors      map[string]string `json:"colors"`
}

// GetThemeConfig reads current theme configuration
func (a *App) GetThemeConfig() (ThemeConfig, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return ThemeConfig{}, err
	}

	config := ThemeConfig{
		Colors:          make(map[string]string),
		AvailableThemes: getPresetThemes(),
	}

	// Read mode from hecate.toml
	tomlPath := filepath.Join(homeDir, ".config", "hecate", "hecate.toml")
	mode, err := readThemeModeFromToml(tomlPath)
	if err == nil {
		config.Mode = mode
	} else {
		config.Mode = "dynamic"
	}

	// Read current colors from hecate.css
	cssPath := filepath.Join(homeDir, ".config", "hecate", "hecate.css")
	colors, err := readColorsFromCSS(cssPath)
	if err == nil {
		config.Colors = colors
	}

	// Determine current theme if in static mode
	if config.Mode == "static" {
		config.CurrentTheme = detectCurrentTheme(colors, config.AvailableThemes)
	}

	return config, nil
}

// UpdateThemeMode updates the theme mode in hecate.toml
func (a *App) UpdateThemeMode(mode string) error {
	if mode != "dynamic" && mode != "static" {
		return fmt.Errorf("invalid theme mode: %s (must be 'dynamic' or 'static')", mode)
	}

	homeDir, err := os.UserHomeDir()
	if err != nil {
		return err
	}

	tomlPath := filepath.Join(homeDir, ".config", "hecate", "hecate.toml")
	return updateThemeModeInToml(tomlPath, mode)
}

// ApplyTheme applies a preset theme (only works in static mode)
func (a *App) ApplyTheme(themeName string) error {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return err
	}

	// Check if we're in static mode
	tomlPath := filepath.Join(homeDir, ".config", "hecate", "hecate.toml")
	mode, err := readThemeModeFromToml(tomlPath)
	if err != nil {
		return err
	}

	if mode != "static" {
		return fmt.Errorf("cannot apply preset theme in dynamic mode")
	}

	// Find the theme
	presets := getPresetThemes()
	var selectedTheme *ThemePreset
	for _, preset := range presets {
		if preset.Name == themeName {
			selectedTheme = &preset
			break
		}
	}

	if selectedTheme == nil {
		return fmt.Errorf("theme not found: %s", themeName)
	}

	// Generate complete color set with derived colors
	fullColors := generateFullColorSet(selectedTheme.Colors)

	// Write to hecate.css
	cssPath := filepath.Join(homeDir, ".config", "hecate", "hecate.css")
	if err := writeHecateCSS(cssPath, fullColors, themeName); err != nil {
		return fmt.Errorf("failed to write hecate.css: %w", err)
	}

	// Write to waybar color.css (symlinked from hecate.css, so this might not be needed)
	// But if you have a separate file:
	waybarColorPath := filepath.Join(homeDir, ".config", "waybar", "color.css")
	if err := writeHecateCSS(waybarColorPath, fullColors, themeName); err != nil {
		// Don't fail if waybar doesn't exist
		fmt.Printf("Warning: could not write waybar colors: %v\n", err)
	}

	// Write to wlogout
	wlogoutColorPath := filepath.Join(homeDir, ".config", "wlogout", "color.css")
	if err := writeWlogoutCSS(wlogoutColorPath, fullColors); err != nil {
		fmt.Printf("Warning: could not write wlogout colors: %v\n", err)
	}

	// Write to rofi
	rofiColorPath := filepath.Join(homeDir, ".config", "rofi","theme", "colors-rofi.rasi")
	if err := writeRofiColors(rofiColorPath, fullColors); err != nil {
		fmt.Printf("Warning: could not write rofi colors: %v\n", err)
	}

	// Write to swaync (if it uses hecate.css via symlink, it should auto-update)
	swayNCColorPath := filepath.Join(homeDir, ".config", "swaync", "color.css")
	if err := writeHecateCSS(swayNCColorPath, fullColors, themeName); err != nil {
		fmt.Printf("Warning: could not write swaync colors: %v\n", err)
	}

	// Update starship
	// if err := updateStarship(fullColors); err != nil {
	// 	fmt.Printf("Warning: could not update starship: %v\n", err)
	// }

	// Reload waybar
	if err := a.ReloadWaybar(); err != nil {
		fmt.Printf("Warning: failed to reload waybar: %v\n", err)
	}

	// Reload SwayNC
	if err := reloadSwayNC(); err != nil {
		fmt.Printf("Warning: failed to reload swaync: %v\n", err)
	}

	return nil
}

// reloadSwayNC reloads swaync to apply theme changes
func reloadSwayNC() error {
	cmd := exec.Command("swaync-client", "-rs")
	return cmd.Run()
}

// ReloadWaybar reloads waybar to apply theme changes
func (a *App) ReloadWaybar() error {
	cmd := exec.Command("pkill", "-SIGUSR2", "waybar")
	return cmd.Run()
}

// generateFullColorSet creates all derived colors from base colors
func generateFullColorSet(baseColors map[string]string) map[string]string {
	colors := make(map[string]string)

	// Copy all base colors
	for k, v := range baseColors {
		colors[k] = v
	}

	// Ensure we have all 16 terminal colors
	ensureColor := func(name string, fallback string) {
		if _, exists := colors[name]; !exists {
			colors[name] = fallback
		}
	}

	// Add derived/semantic colors if not present
	ensureColor("bg", colors["background"])
	ensureColor("fg", colors["foreground"])
	ensureColor("bg-alt", lighten(colors["background"], 10))
	ensureColor("bg-dim", colors["color0"])
	ensureColor("fg-dim", colors["color8"])
	ensureColor("fg-bright", colors["color15"])

	ensureColor("primary", colors["color4"])
	ensureColor("secondary", colors["color6"])
	ensureColor("accent", colors["color5"])
	ensureColor("accent-alt", colors["color12"])
	ensureColor("success", colors["color2"])
	ensureColor("warning", colors["color3"])
	ensureColor("error", colors["color1"])
	ensureColor("muted", colors["color8"])

	ensureColor("red", colors["color1"])
	ensureColor("green", colors["color2"])
	ensureColor("yellow", colors["color3"])
	ensureColor("blue", colors["color4"])
	ensureColor("magenta", colors["color5"])
	ensureColor("cyan", colors["color6"])

	ensureColor("red-bright", colors["color9"])
	ensureColor("green-bright", colors["color10"])
	ensureColor("yellow-bright", colors["color11"])
	ensureColor("blue-bright", colors["color12"])
	ensureColor("magenta-bright", colors["color13"])
	ensureColor("cyan-bright", colors["color14"])

	// Generate RGBA variants
	colors["bg_rgba"] = hexToRGBA(colors["background"], 0.9)
	colors["bg_rgba_light"] = hexToRGBA(colors["background"], 0.7)
	colors["bg_rgba_lighter"] = hexToRGBA(colors["background"], 0.5)
	colors["bg_rgba_dim"] = hexToRGBA(colors["background"], 0.3)

	colors["color4_rgba"] = hexToRGBA(colors["color4"], 0.5)
	colors["color4_rgba_hover"] = hexToRGBA(colors["color4"], 0.4)
	colors["color4_rgba_border"] = hexToRGBA(colors["color4"], 0.2)

	colors["color1_rgba"] = hexToRGBA(colors["color1"], 0.4)
	colors["color1_rgba_border"] = hexToRGBA(colors["color1"], 0.2)

	return colors
}

// writeHecateCSS writes the main hecate.css file matching script format
func writeHecateCSS(path string, colors map[string]string, themeName string) error {
	timestamp := time.Now().Format("2006-01-02 15:04:05")

	var builder strings.Builder
	builder.WriteString("/* ═══════════════════════════════════════════════════════════════\n")
	builder.WriteString(fmt.Sprintf("   Hecate Theme - %s\n", themeName))
	builder.WriteString(fmt.Sprintf("   Applied on %s\n\n", timestamp))
	builder.WriteString("   This file is the single source of truth for all theme colors.\n")
	builder.WriteString("   All component CSS files import from this file.\n")
	builder.WriteString("   ═══════════════════════════════════════════════════════════════ */\n\n")

	// Base Colors
	builder.WriteString("/* ─────────────────────────────────────────────────────────────── */\n")
	builder.WriteString("/* Base Colors (Pywal)                                             */\n")
	builder.WriteString("/* ─────────────────────────────────────────────────────────────── */\n\n")
	builder.WriteString(fmt.Sprintf("@define-color background %s;\n", colors["background"]))
	builder.WriteString(fmt.Sprintf("@define-color foreground %s;\n", colors["foreground"]))
	builder.WriteString(fmt.Sprintf("@define-color cursor %s;\n\n", colors["cursor"]))

	// Palette Colors (without spacing for compactness like script)
	for i := 0; i <= 15; i++ {
		key := fmt.Sprintf("color%d", i)
		builder.WriteString(fmt.Sprintf("@define-color %-6s %s;\n", key, colors[key]))
	}
	builder.WriteString("\n")

	// Smart Contrast Variants
	builder.WriteString("/* ─────────────────────────────────────────────────────────────── */\n")
	builder.WriteString("/* Smart Contrast Variants                                         */\n")
	builder.WriteString("/* ─────────────────────────────────────────────────────────────── */\n\n")
	builder.WriteString(fmt.Sprintf("@define-color bg %s;\n", colors["bg"]))
	builder.WriteString(fmt.Sprintf("@define-color fg %s;\n", colors["fg"]))
	builder.WriteString(fmt.Sprintf("@define-color bg-alt %s;\n", colors["bg-alt"]))
	builder.WriteString(fmt.Sprintf("@define-color bg-dim %s;\n", colors["bg-dim"]))
	builder.WriteString(fmt.Sprintf("@define-color fg-dim %s;\n", colors["fg-dim"]))
	builder.WriteString(fmt.Sprintf("@define-color fg-bright %s;\n\n", colors["fg-bright"]))

	// Semantic Colors
	builder.WriteString("/* ─────────────────────────────────────────────────────────────── */\n")
	builder.WriteString("/* Semantic Colors                                                 */\n")
	builder.WriteString("/* ─────────────────────────────────────────────────────────────── */\n\n")
	builder.WriteString(fmt.Sprintf("@define-color primary %s;\n", colors["primary"]))
	builder.WriteString(fmt.Sprintf("@define-color secondary %s;\n", colors["secondary"]))
	builder.WriteString(fmt.Sprintf("@define-color accent %s;\n", colors["accent"]))
	builder.WriteString(fmt.Sprintf("@define-color accent-alt %s;\n", colors["accent-alt"]))
	builder.WriteString(fmt.Sprintf("@define-color success %s;\n", colors["success"]))
	builder.WriteString(fmt.Sprintf("@define-color warning %s;\n", colors["warning"]))
	builder.WriteString(fmt.Sprintf("@define-color error %s;\n", colors["error"]))
	builder.WriteString(fmt.Sprintf("@define-color muted %s;\n\n", colors["muted"]))

	// Named Colors
	builder.WriteString(fmt.Sprintf("@define-color red %s;\n", colors["red"]))
	builder.WriteString(fmt.Sprintf("@define-color green %s;\n", colors["green"]))
	builder.WriteString(fmt.Sprintf("@define-color yellow %s;\n", colors["yellow"]))
	builder.WriteString(fmt.Sprintf("@define-color blue %s;\n", colors["blue"]))
	builder.WriteString(fmt.Sprintf("@define-color magenta %s;\n", colors["magenta"]))
	builder.WriteString(fmt.Sprintf("@define-color cyan %s;\n\n", colors["cyan"]))

	builder.WriteString(fmt.Sprintf("@define-color red-bright %s;\n", colors["red-bright"]))
	builder.WriteString(fmt.Sprintf("@define-color green-bright %s;\n", colors["green-bright"]))
	builder.WriteString(fmt.Sprintf("@define-color yellow-bright %s;\n", colors["yellow-bright"]))
	builder.WriteString(fmt.Sprintf("@define-color blue-bright %s;\n", colors["blue-bright"]))
	builder.WriteString(fmt.Sprintf("@define-color magenta-bright %s;\n", colors["magenta-bright"]))
	builder.WriteString(fmt.Sprintf("@define-color cyan-bright %s;\n\n", colors["cyan-bright"]))

	// RGBA Variants (for transparency effects)
	builder.WriteString("/* ─────────────────────────────────────────────────────────────── */\n")
	builder.WriteString("/* RGBA Variants (for transparency effects)                        */\n")
	builder.WriteString("/* ─────────────────────────────────────────────────────────────── */\n\n")
	builder.WriteString("/* Background variants */\n")
	builder.WriteString(fmt.Sprintf("@define-color bg_rgba %s;\n", colors["bg_rgba"]))
	builder.WriteString(fmt.Sprintf("@define-color bg_rgba_light %s;\n", colors["bg_rgba_light"]))
	builder.WriteString(fmt.Sprintf("@define-color bg_rgba_lighter %s;\n", colors["bg_rgba_lighter"]))
	builder.WriteString(fmt.Sprintf("@define-color bg_dark %s;\n", colors["bg_rgba_lighter"]))
	builder.WriteString(fmt.Sprintf("@define-color bg_rgba_dim %s;\n\n", colors["bg_rgba_dim"]))

	builder.WriteString("/* Primary/Accent variants */\n")
	builder.WriteString(fmt.Sprintf("@define-color color4_rgba %s;\n", colors["color4_rgba"]))
	builder.WriteString(fmt.Sprintf("@define-color color4_rgba_hover %s;\n", colors["color4_rgba_hover"]))
	builder.WriteString(fmt.Sprintf("@define-color color4_rgba_border %s;\n\n", colors["color4_rgba_border"]))

	builder.WriteString("/* Error/Warning variants */\n")
	builder.WriteString(fmt.Sprintf("@define-color color1_rgba %s;\n", colors["color1_rgba"]))
	builder.WriteString(fmt.Sprintf("@define-color color1_rgba_border %s;\n", colors["color1_rgba_border"]))

	// Extract RGB values for additional RGBA variants
	rgb1 := hexToRGB(colors["color1"])
	rgb0 := hexToRGB(colors["background"])
	rgb4 := hexToRGB(colors["color4"])

	builder.WriteString(fmt.Sprintf("@define-color color1_rgba_light rgba(%s, 0.3);\n", rgb1))
	builder.WriteString(fmt.Sprintf("@define-color color1_rgba_dim rgba(%s, 0.1);\n\n", rgb1))

	builder.WriteString("/* SwayNC specific RGBA variants */\n")
	builder.WriteString(fmt.Sprintf("@define-color BG_RGBA rgba(%s, 0.85);\n", rgb0))
	builder.WriteString(fmt.Sprintf("@define-color BG_RGBA_LIGHT rgba(%s, 0.7);\n", rgb0))
	builder.WriteString(fmt.Sprintf("@define-color BG_RGBA_LIGHTER rgba(%s, 0.5);\n", rgb0))
	builder.WriteString(fmt.Sprintf("@define-color COLOR1_RGBA rgba(%s, 0.4);\n", rgb1))
	builder.WriteString(fmt.Sprintf("@define-color COLOR1_RGBA_LIGHT rgba(%s, 0.3);\n", rgb1))
	builder.WriteString(fmt.Sprintf("@define-color COLOR1_RGBA_DIM rgba(%s, 0.1);\n", rgb1))
	builder.WriteString(fmt.Sprintf("@define-color COLOR4_RGBA rgba(%s, 0.5);\n", rgb4))
	builder.WriteString(fmt.Sprintf("@define-color COLOR4_RGBA_LIGHT rgba(%s, 0.4);\n", rgb4))
	builder.WriteString(fmt.Sprintf("@define-color COLOR4_RGBA_DIM rgba(%s, 0.3);\n", rgb4))
	builder.WriteString(fmt.Sprintf("@define-color COLOR4_RGBA_BORDER rgba(%s, 0.2);\n\n", rgb4))

	// Component-Specific Aliases
	builder.WriteString("/* ─────────────────────────────────────────────────────────────── */\n")
	builder.WriteString("/* Component-Specific Aliases                                      */\n")
	builder.WriteString("/* ─────────────────────────────────────────────────────────────── */\n\n")
	builder.WriteString("/* Waybar */\n")
	builder.WriteString(fmt.Sprintf("@define-color BACKGROUND %s;\n", colors["background"]))
	builder.WriteString(fmt.Sprintf("@define-color FOREGROUND %s;\n\n", colors["foreground"]))
	builder.WriteString("/* Wlogout */\n")
	builder.WriteString("/* (uses same definitions as above) */\n\n")

	builder.WriteString("/* ═══════════════════════════════════════════════════════════════\n")
	builder.WriteString("   End of Hecate Theme Colors\n")
	builder.WriteString("   ═══════════════════════════════════════════════════════════════ */\n")

	return os.WriteFile(path, []byte(builder.String()), 0644)
}

// writeWlogoutCSS writes wlogout color.css
func writeWlogoutCSS(path string, colors map[string]string) error {
	timestamp := time.Now().Format("2006-01-02 15:04:05")

	var builder strings.Builder
	builder.WriteString("/* Wlogout Colors - Static Theme */\n")
	builder.WriteString(fmt.Sprintf("/* Generated: %s */\n\n", timestamp))

	colorKeys := []string{"background", "foreground", "color0", "color1", "color2", "color3", "color4", "color5", "color6", "color7", "color8", "color9", "color10", "color11", "color12", "color13", "color14", "color15"}

	for _, key := range colorKeys {
		if val, ok := colors[key]; ok {
			builder.WriteString(fmt.Sprintf("@define-color %-15s %s;\n", key, val))
		}
	}

	builder.WriteString("\n/* Semantic color names for wlogout */\n")
	builder.WriteString(fmt.Sprintf("@define-color %-15s %s;\n", "primary", colors["color4"]))
	builder.WriteString(fmt.Sprintf("@define-color %-15s %s;\n", "secondary", colors["color6"]))
	builder.WriteString(fmt.Sprintf("@define-color %-15s %s;\n", "accent", colors["color5"]))
	builder.WriteString(fmt.Sprintf("@define-color %-15s %s;\n", "success", colors["color2"]))
	builder.WriteString(fmt.Sprintf("@define-color %-15s %s;\n", "warning", colors["color3"]))
	builder.WriteString(fmt.Sprintf("@define-color %-15s %s;\n", "error", colors["color1"]))

	return os.WriteFile(path, []byte(builder.String()), 0644)
}

// writeRofiColors writes rofi colors.rasi
func writeRofiColors(path string, colors map[string]string) error {
	var builder strings.Builder
	builder.WriteString("/* Rofi Colors - Static Theme */\n\n")
	builder.WriteString("* {\n")
	builder.WriteString(fmt.Sprintf("    background:     %s;\n", colors["background"]))
	builder.WriteString(fmt.Sprintf("    foreground:     %s;\n", colors["foreground"]))
	builder.WriteString(fmt.Sprintf("    cursor:         %s;\n", colors["cursor"]))

	for i := 0; i <= 15; i++ {
		key := fmt.Sprintf("color%d", i)
		builder.WriteString(fmt.Sprintf("    %-15s %s;\n", key+":", colors[key]))
	}

	builder.WriteString("\n    /* Semantic aliases */\n")
	builder.WriteString("    bg:             @background;\n")
	builder.WriteString("    fg:             @foreground;\n")
	builder.WriteString(fmt.Sprintf("    bg-alt:         %s;\n", colors["bg-alt"]))
	builder.WriteString("    bg-dim:         @color0;\n")
	builder.WriteString(fmt.Sprintf("    fg-dim:         %s;\n", colors["fg-dim"]))
	builder.WriteString(fmt.Sprintf("    fg-bright:      %s;\n", colors["fg-bright"]))
	builder.WriteString("    accent:         @color4;\n")
	builder.WriteString("    accent-alt:     @color12;\n")
	builder.WriteString("    red:            @color1;\n")
	builder.WriteString("    green:          @color2;\n")
	builder.WriteString("    yellow:         @color3;\n")
	builder.WriteString("    blue:           @color4;\n")
	builder.WriteString("    magenta:        @color5;\n")
	builder.WriteString("    cyan:           @color6;\n")
	builder.WriteString("    red-bright:     @color9;\n")
	builder.WriteString("    green-bright:   @color10;\n")
	builder.WriteString("    yellow-bright:  @color11;\n")
	builder.WriteString("    blue-bright:    @color12;\n")
	builder.WriteString("    magenta-bright: @color13;\n")
	builder.WriteString("    cyan-bright:    @color14;\n")
	builder.WriteString("}\n")

	return os.WriteFile(path, []byte(builder.String()), 0644)
}

// updateStarship updates starship.toml with new colors
// func updateStarship(colors map[string]string) error {
// 	homeDir, err := os.UserHomeDir()
// 	if err != nil {
// 		return err
// 	}

// 	starshipPath := filepath.Join(homeDir, ".config", "starship.toml")
// 	timestamp := time.Now().Format("2006-01-02 15:04:05")

// 	// Generate starship config with actual colors
// 	config := fmt.Sprintf(`# ────────────────────────────────────────────────────────────────
// # 🌟 Starship Prompt Configuration
// # Modern, clean prompt — Hecate Theme Edition
// # Generated: %s
// # ────────────────────────────────────────────────────────────────

// "$schema" = 'https://starship.rs/config-schema.json'

// add_newline = true
// command_timeout = 500

// format = """
// [╭─](bold %s)$username$hostname$directory$git_branch$git_status$cmd_duration$fill$time
// [╰─](bold %s)$character
// """

// [character]
// success_symbol = "[➜](bold %s)"
// error_symbol = "[✗](bold %s)"
// vicmd_symbol = "[V](bold %s)"

// [username]
// style_user = "bold %s"
// style_root = "bold %s"
// format = "[$user]($style)"
// show_always = true

// [hostname]
// ssh_only = false
// format = "[@$hostname](bold %s) "
// disabled = false

// [directory]
// truncation_length = 3
// truncate_to_repo = true
// style = "bold %s"
// read_only = " "
// format = "[in](dim %s) [$path]($style)[$read_only]($read_only_style) "

// [git_branch]
// symbol = " "
// format = "on [$symbol$branch]($style) "
// style = "bold %s"

// [git_status]
// format = '([\[$all_status$ahead_behind\]]($style) )'
// style = "bold %s"
// conflicted = "🏳 "
// ahead = "⇡${count} "
// diverged = "⇕⇡${ahead_count}⇣${behind_count} "
// behind = "⇣${count} "
// untracked = "?${count} "
// stashed = "💾${count} "
// modified = "!${count} "
// staged = "+${count} "
// renamed = "»${count} "
// deleted = "✘${count} "

// [nodejs]
// symbol = " "
// format = "via [$symbol($version )]($style)"
// style = "bold %s"

// [python]
// symbol = " "
// style = "bold %s"

// [rust]
// symbol = " "
// format = "via [$symbol($version )]($style)"
// style = "bold %s"

// [java]
// symbol = " "
// format = "via [$symbol($version )]($style)"
// style = "bold %s"

// [package]
// symbol = " "
// format = "[$symbol$version]($style)"
// style = "bold %s"

// [golang]
// symbol = " "
// format = "via [$symbol($version )]($style)"
// style = "bold %s"

// [lua]
// symbol = " "
// format = "via [$symbol($version )]($style)"
// style = "bold %s"

// [cmd_duration]
// min_time = 500
// format = "[took $duration](bold %s) "

// [time]
// disabled = false
// format = "[$time](dim %s)"
// time_format = "%%R"

// [fill]
// symbol = " "

// [battery]
// disabled = false
// full_symbol = "🔋"
// charging_symbol = "⚡"
// discharging_symbol = "💀"
// format = "[$symbol $percentage]($style) "

// [[battery.display]]
// threshold = 10
// style = "bold %s"

// [[battery.display]]
// threshold = 30
// style = "bold %s"

// [[battery.display]]
// threshold = 100
// style = "bold %s"

// [docker_context]
// symbol = " "
// format = "via [$symbol$context](bold %s) "

// [kubernetes]
// symbol = "☸ "
// format = 'on [$symbol$context( \($namespace\))](bold %s) '
// disabled = false

// [aws]
// symbol = " "
// format = 'on [$symbol($profile )($region )](bold %s) '

// [gcloud]
// format = 'on [$symbol$account(@$domain)($region)](bold %s) '

// [azure]
// symbol = " "
// format = 'on [$symbol($subscription)](bold %s) '
// `,
// 		timestamp,
// 		colors["color2"], colors["color2"],  // prompt frame
// 		colors["color2"], colors["color1"], colors["color3"],  // character states
// 		colors["color3"], colors["color1"],  // username styles
// 		colors["color4"],  // hostname
// 		colors["color6"], colors["color8"],  // directory
// 		colors["color5"],  // git branch
// 		colors["color1"],  // git status
// 		colors["color2"], colors["color3"], colors["color1"], colors["color1"],  // language colors
// 		colors["color4"], colors["color6"], colors["color4"],  // more languages
// 		colors["color3"], colors["color8"],  // cmd_duration, time
// 		colors["color1"], colors["color3"], colors["color2"],  // battery
// 		colors["color4"], colors["color4"],  // docker, k8s
// 		colors["color3"], colors["color4"], colors["color4"],  // cloud providers
// 	)

// 	return os.WriteFile(starshipPath, []byte(config), 0644)
// }

// readThemeModeFromToml reads the theme mode from hecate.toml
func readThemeModeFromToml(path string) (string, error) {
	file, err := os.Open(path)
	if err != nil {
		return "", err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	inTheme := false

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())

		if line == "[theme]" {
			inTheme = true
			continue
		}

		if inTheme && strings.HasPrefix(line, "[") {
			break
		}

		if inTheme && strings.HasPrefix(line, "mode") {
			parts := strings.SplitN(line, "=", 2)
			if len(parts) == 2 {
				mode := strings.Trim(strings.TrimSpace(parts[1]), `"`)
				return mode, nil
			}
		}
	}

	return "dynamic", nil
}

// updateThemeModeInToml updates the theme mode in hecate.toml
func updateThemeModeInToml(path string, mode string) error {
	file, err := os.Open(path)
	if err != nil {
		return err
	}

	var lines []string
	scanner := bufio.NewScanner(file)
	inTheme := false

	for scanner.Scan() {
		line := scanner.Text()
		trimmedLine := strings.TrimSpace(line)

		if trimmedLine == "[theme]" {
			inTheme = true
			lines = append(lines, line)
			continue
		}

		if inTheme && strings.HasPrefix(trimmedLine, "[") {
			inTheme = false
			lines = append(lines, line)
			continue
		}

		if inTheme && strings.HasPrefix(trimmedLine, "mode") {
			leadingSpace := line[:len(line)-len(strings.TrimLeft(line, " \t"))]
			lines = append(lines, fmt.Sprintf(`%smode = "%s"`, leadingSpace, mode))
		} else {
			lines = append(lines, line)
		}
	}

	file.Close()

	if err := scanner.Err(); err != nil {
		return err
	}

	return os.WriteFile(path, []byte(strings.Join(lines, "\n")), 0644)
}

// readColorsFromCSS parses hecate.css and extracts color definitions
func readColorsFromCSS(path string) (map[string]string, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	colors := make(map[string]string)
	colorRegex := regexp.MustCompile(`@define-color\s+(\S+)\s+(.+);`)

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		matches := colorRegex.FindStringSubmatch(line)
		if len(matches) == 3 {
			colorName := matches[1]
			colorValue := strings.TrimSpace(matches[2])
			colors[colorName] = colorValue
		}
	}

	return colors, scanner.Err()
}

// detectCurrentTheme tries to match current colors with a preset
func detectCurrentTheme(currentColors map[string]string, presets []ThemePreset) string {
	for _, preset := range presets {
		if matchesTheme(currentColors, preset.Colors) {
			return preset.Name
		}
	}
	return "custom"
}

// matchesTheme checks if colors match a preset
func matchesTheme(current, preset map[string]string) bool {
	keyColors := []string{"background", "foreground", "color4"}
	for _, key := range keyColors {
		if current[key] != preset[key] {
			return false
		}
	}
	return true
}

// Helper functions for color manipulation
func hexToRGBA(hex string, alpha float64) string {
	hex = strings.TrimPrefix(hex, "#")
	if len(hex) != 6 {
		return hex
	}

	var r, g, b int
	fmt.Sscanf(hex, "%02x%02x%02x", &r, &g, &b)
	return fmt.Sprintf("rgba(%d, %d, %d, %.2f)", r, g, b, alpha)
}

func hexToRGB(hex string) string {
	hex = strings.TrimPrefix(hex, "#")
	if len(hex) != 6 {
		return "0, 0, 0"
	}

	var r, g, b int
	fmt.Sscanf(hex, "%02x%02x%02x", &r, &g, &b)
	return fmt.Sprintf("%d, %d, %d", r, g, b)
}

func lighten(hex string, percent int) string {
	hex = strings.TrimPrefix(hex, "#")
	if len(hex) != 6 {
		return hex
	}

	var r, g, b int
	fmt.Sscanf(hex, "%02x%02x%02x", &r, &g, &b)

	factor := float64(percent) / 100.0
	r = min(255, int(float64(r)+(255.0-float64(r))*factor))
	g = min(255, int(float64(g)+(255.0-float64(g))*factor))
	b = min(255, int(float64(b)+(255.0-float64(b))*factor))

	return fmt.Sprintf("#%02x%02x%02x", r, g, b)
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

// getPresetThemes returns available theme presets
func getPresetThemes() []ThemePreset {
	return []ThemePreset{
		{
			Name:        "Catppuccin Mocha",
			Description: "Soothing pastel theme in the dark",
			Colors: map[string]string{
				"background": "#1e1e2e", "foreground": "#cdd6f4", "cursor": "#f5e0dc",
				"color0": "#45475a", "color1": "#f38ba8", "color2": "#a6e3a1", "color3": "#f9e2af",
				"color4": "#89b4fa", "color5": "#f5c2e7", "color6": "#94e2d5", "color7": "#bac2de",
				"color8": "#585b70", "color9": "#f38ba8", "color10": "#a6e3a1", "color11": "#f9e2af",
				"color12": "#89b4fa", "color13": "#f5c2e7", "color14": "#94e2d5", "color15": "#a6adc8",
			},
		},
		{
			Name:        "Tokyo Night",
			Description: "A clean, dark theme inspired by Tokyo nights",
			Colors: map[string]string{
				"background": "#1a1b26", "foreground": "#c0caf5", "cursor": "#c0caf5",
				"color0": "#15161e", "color1": "#f7768e", "color2": "#9ece6a", "color3": "#e0af68",
				"color4": "#7aa2f7", "color5": "#bb9af7", "color6": "#7dcfff", "color7": "#a9b1d6",
				"color8": "#414868", "color9": "#f7768e", "color10": "#9ece6a", "color11": "#e0af68",
				"color12": "#7aa2f7", "color13": "#bb9af7", "color14": "#7dcfff", "color15": "#c0caf5",
			},
		},
		{
			Name:        "Gruvbox Dark",
			Description: "Retro groove color scheme",
			Colors: map[string]string{
				"background": "#282828", "foreground": "#ebdbb2", "cursor": "#ebdbb2",
				"color0": "#282828", "color1": "#cc241d", "color2": "#98971a", "color3": "#d79921",
				"color4": "#458588", "color5": "#b16286", "color6": "#689d6a", "color7": "#a89984",
				"color8": "#928374", "color9": "#fb4934", "color10": "#b8bb26", "color11": "#fabd2f",
				"color12": "#83a598", "color13": "#d3869b", "color14": "#8ec07c", "color15": "#ebdbb2",
			},
		},
		{
			Name:        "Nord",
			Description: "Arctic, north-bluish color palette",
			Colors: map[string]string{
				"background": "#2e3440", "foreground": "#d8dee9", "cursor": "#d8dee9",
				"color0": "#3b4252", "color1": "#bf616a", "color2": "#a3be8c", "color3": "#ebcb8b",
				"color4": "#81a1c1", "color5": "#b48ead", "color6": "#88c0d0", "color7": "#e5e9f0",
				"color8": "#4c566a", "color9": "#bf616a", "color10": "#a3be8c", "color11": "#ebcb8b",
				"color12": "#81a1c1", "color13": "#b48ead", "color14": "#8fbcbb", "color15": "#eceff4",
			},
		},
		{
			Name:        "Dracula",
			Description: "A dark theme with vibrant colors",
			Colors: map[string]string{
				"background": "#282a36", "foreground": "#f8f8f2", "cursor": "#f8f8f2",
				"color0": "#21222c", "color1": "#ff5555", "color2": "#50fa7b", "color3": "#f1fa8c",
				"color4": "#bd93f9", "color5": "#ff79c6", "color6": "#8be9fd", "color7": "#f8f8f2",
				"color8": "#6272a4", "color9": "#ff6e6e", "color10": "#69ff94", "color11": "#ffffa5",
				"color12": "#d6acff", "color13": "#ff92df", "color14": "#a4ffff", "color15": "#ffffff",
			},
		},
		{
			Name:        "One Dark",
			Description: "Atom's iconic One Dark theme",
			Colors: map[string]string{
				"background": "#282c34", "foreground": "#abb2bf", "cursor": "#528bff",
				"color0": "#282c34", "color1": "#e06c75", "color2": "#98c379", "color3": "#e5c07b",
				"color4": "#61afef", "color5": "#c678dd", "color6": "#56b6c2", "color7": "#abb2bf",
				"color8": "#545862", "color9": "#e06c75", "color10": "#98c379", "color11": "#e5c07b",
				"color12": "#61afef", "color13": "#c678dd", "color14": "#56b6c2", "color15": "#c8ccd4",
			},
		},
	}
}
