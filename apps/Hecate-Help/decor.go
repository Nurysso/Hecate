// decorations.go
package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

type GeneralConfig struct {
	BorderSize           int     `json:"border_size"`
	GapsIn               string  `json:"gaps_in"`
	GapsOut              string  `json:"gaps_out"`
	FloatGaps            string  `json:"float_gaps"`
	GapsWorkspaces       int     `json:"gaps_workspaces"`
	ColInactiveBorder    string  `json:"col_inactive_border"`
	ColActiveBorder      string  `json:"col_active_border"`
	ColNogroupBorder     string  `json:"col_nogroup_border"`
	ColNogroupBorderActive string `json:"col_nogroup_border_active"`
	Layout               string  `json:"layout"`
	NoFocusFallback      bool    `json:"no_focus_fallback"`
	ResizeOnBorder       bool    `json:"resize_on_border"`
	ExtendBorderGrabArea int     `json:"extend_border_grab_area"`
	HoverIconOnBorder    bool    `json:"hover_icon_on_border"`
	AllowTearing         bool    `json:"allow_tearing"`
	ResizeCorner         int     `json:"resize_corner"`
	ModalParentBlocking  bool    `json:"modal_parent_blocking"`
	Locale               string  `json:"locale"`
}

type SnapConfig struct {
	Enabled        bool `json:"enabled"`
	WindowGap      int  `json:"window_gap"`
	MonitorGap     int  `json:"monitor_gap"`
	BorderOverlap  bool `json:"border_overlap"`
	RespectGaps    bool `json:"respect_gaps"`
}

type BlurConfig struct {
	Enabled                 bool    `json:"enabled"`
	Size                    int     `json:"size"`
	Passes                  int     `json:"passes"`
	IgnoreOpacity           bool    `json:"ignore_opacity"`
	NewOptimizations        bool    `json:"new_optimizations"`
	Xray                    bool    `json:"xray"`
	Noise                   float64 `json:"noise"`
	Contrast                float64 `json:"contrast"`
	Brightness              float64 `json:"brightness"`
	Vibrancy                float64 `json:"vibrancy"`
	VibrancyDarkness        float64 `json:"vibrancy_darkness"`
	Special                 bool    `json:"special"`
	Popups                  bool    `json:"popups"`
	PopupsIgnorealpha       float64 `json:"popups_ignorealpha"`
	InputMethods            bool    `json:"input_methods"`
	InputMethodsIgnorealpha float64 `json:"input_methods_ignorealpha"`
}

type DecorationConfig struct {
	Rounding          int     `json:"rounding"`
	RoundingPower     float64 `json:"rounding_power"`
	ActiveOpacity     float64 `json:"active_opacity"`
	InactiveOpacity   float64 `json:"inactive_opacity"`
	FullscreenOpacity float64 `json:"fullscreen_opacity"`
	DimModal          bool    `json:"dim_modal"`
	DimInactive       bool    `json:"dim_inactive"`
	DimStrength       float64 `json:"dim_strength"`
	DimSpecial        float64 `json:"dim_special"`
	DimAround         float64 `json:"dim_around"`
	ScreenShader      string  `json:"screen_shader"`
	BorderPartOfWindow bool   `json:"border_part_of_window"`
}

type DecorationsFullConfig struct {
	General    GeneralConfig    `json:"general"`
	Snap       SnapConfig       `json:"snap"`
	Decoration DecorationConfig `json:"decoration"`
	Blur       BlurConfig       `json:"blur"`
}

// GetDecorationsConfig reads and parses the decorations.conf file
func (a *App) GetDecorationsConfig() (*DecorationsFullConfig, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return nil, fmt.Errorf("failed to get home directory: %w", err)
	}

	configPath := filepath.Join(homeDir, ".config", "hypr", "configs", "decorations.conf")

	content, err := os.ReadFile(configPath)
	if err != nil {
		if os.IsNotExist(err) {
			return a.getDefaultDecorationsConfig(), nil
		}
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	return a.parseDecorationsConfig(string(content))
}

// parseDecorationsConfig parses the decorations.conf content
func (a *App) parseDecorationsConfig(content string) (*DecorationsFullConfig, error) {
	config := a.getDefaultDecorationsConfig()
	lines := strings.Split(content, "\n")

	var currentSection string
	var currentSubsection string

	for _, line := range lines {
		line = strings.TrimSpace(line)

		// Skip comments and empty lines
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		// Detect section opening
		if strings.Contains(line, "{") {
			sectionName := strings.TrimSpace(strings.Split(line, "{")[0])
			if currentSection == "" {
				currentSection = sectionName
			} else {
				currentSubsection = sectionName
			}
			continue
		}

		// Detect section closing
		if strings.Contains(line, "}") {
			if currentSubsection != "" {
				currentSubsection = ""
			} else {
				currentSection = ""
			}
			continue
		}

		// Parse key-value pairs
		if strings.Contains(line, "=") {
			parts := strings.SplitN(line, "=", 2)
			if len(parts) != 2 {
				continue
			}

			key := strings.TrimSpace(parts[0])
			value := strings.TrimSpace(parts[1])

			a.setConfigValue(config, currentSection, currentSubsection, key, value)
		}
	}

	return config, nil
}

// setConfigValue sets a configuration value based on section and key
func (a *App) setConfigValue(config *DecorationsFullConfig, section, subsection, key, value string) {
	switch section {
	case "general":
		if subsection == "snap" {
			a.setSnapValue(&config.Snap, key, value)
		} else {
			a.setGeneralValue(&config.General, key, value)
		}
	case "decoration":
		if subsection == "blur" {
			a.setBlurValue(&config.Blur, key, value)
		} else {
			a.setDecorationValue(&config.Decoration, key, value)
		}
	}
}

// setGeneralValue sets a value in GeneralConfig
func (a *App) setGeneralValue(config *GeneralConfig, key, value string) {
	switch key {
	case "border_size":
		config.BorderSize, _ = strconv.Atoi(value)
	case "gaps_in":
		config.GapsIn = value
	case "gaps_out":
		config.GapsOut = value
	case "float_gaps":
		config.FloatGaps = value
	case "gaps_workspaces":
		config.GapsWorkspaces, _ = strconv.Atoi(value)
	case "col.inactive_border":
		config.ColInactiveBorder = value
	case "col.active_border":
		config.ColActiveBorder = value
	case "col.nogroup_border":
		config.ColNogroupBorder = value
	case "col.nogroup_border_active":
		config.ColNogroupBorderActive = value
	case "layout":
		config.Layout = value
	case "no_focus_fallback":
		config.NoFocusFallback = parseBool(value)
	case "resize_on_border":
		config.ResizeOnBorder = parseBool(value)
	case "extend_border_grab_area":
		config.ExtendBorderGrabArea, _ = strconv.Atoi(value)
	case "hover_icon_on_border":
		config.HoverIconOnBorder = parseBool(value)
	case "allow_tearing":
		config.AllowTearing = parseBool(value)
	case "resize_corner":
		config.ResizeCorner, _ = strconv.Atoi(value)
	case "modal_parent_blocking":
		config.ModalParentBlocking = parseBool(value)
	case "locale":
		config.Locale = value
	}
}

// setSnapValue sets a value in SnapConfig
func (a *App) setSnapValue(config *SnapConfig, key, value string) {
	switch key {
	case "enabled":
		config.Enabled = parseBool(value)
	case "window_gap":
		config.WindowGap, _ = strconv.Atoi(value)
	case "monitor_gap":
		config.MonitorGap, _ = strconv.Atoi(value)
	case "border_overlap":
		config.BorderOverlap = parseBool(value)
	case "respect_gaps":
		config.RespectGaps = parseBool(value)
	}
}

// setDecorationValue sets a value in DecorationConfig
func (a *App) setDecorationValue(config *DecorationConfig, key, value string) {
	switch key {
	case "rounding":
		config.Rounding, _ = strconv.Atoi(value)
	case "rounding_power":
		config.RoundingPower, _ = strconv.ParseFloat(value, 64)
	case "active_opacity":
		config.ActiveOpacity, _ = strconv.ParseFloat(value, 64)
	case "inactive_opacity":
		config.InactiveOpacity, _ = strconv.ParseFloat(value, 64)
	case "fullscreen_opacity":
		config.FullscreenOpacity, _ = strconv.ParseFloat(value, 64)
	case "dim_modal":
		config.DimModal = parseBool(value)
	case "dim_inactive":
		config.DimInactive = parseBool(value)
	case "dim_strength":
		config.DimStrength, _ = strconv.ParseFloat(value, 64)
	case "dim_special":
		config.DimSpecial, _ = strconv.ParseFloat(value, 64)
	case "dim_around":
		config.DimAround, _ = strconv.ParseFloat(value, 64)
	case "screen_shader":
		config.ScreenShader = value
	case "border_part_of_window":
		config.BorderPartOfWindow = parseBool(value)
	}
}

// setBlurValue sets a value in BlurConfig
func (a *App) setBlurValue(config *BlurConfig, key, value string) {
	switch key {
	case "enabled":
		config.Enabled = parseBool(value)
	case "size":
		config.Size, _ = strconv.Atoi(value)
	case "passes":
		config.Passes, _ = strconv.Atoi(value)
	case "ignore_opacity":
		config.IgnoreOpacity = parseBool(value)
	case "new_optimizations":
		config.NewOptimizations = parseBool(value)
	case "xray":
		config.Xray = parseBool(value)
	case "noise":
		config.Noise, _ = strconv.ParseFloat(value, 64)
	case "contrast":
		config.Contrast, _ = strconv.ParseFloat(value, 64)
	case "brightness":
		config.Brightness, _ = strconv.ParseFloat(value, 64)
	case "vibrancy":
		config.Vibrancy, _ = strconv.ParseFloat(value, 64)
	case "vibrancy_darkness":
		config.VibrancyDarkness, _ = strconv.ParseFloat(value, 64)
	case "special":
		config.Special = parseBool(value)
	case "popups":
		config.Popups = parseBool(value)
	case "popups_ignorealpha":
		config.PopupsIgnorealpha, _ = strconv.ParseFloat(value, 64)
	case "input_methods":
		config.InputMethods = parseBool(value)
	case "input_methods_ignorealpha":
		config.InputMethodsIgnorealpha, _ = strconv.ParseFloat(value, 64)
	}
}

// SaveDecorationsConfig saves the decorations configuration to file
func (a *App) SaveDecorationsConfig(config *DecorationsFullConfig) error {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return fmt.Errorf("failed to get home directory: %w", err)
	}

	configPath := filepath.Join(homeDir, ".config", "hypr", "configs", "decorations.conf")

	// Ensure the directory exists
	configDir := filepath.Dir(configPath)
	if err := os.MkdirAll(configDir, 0755); err != nil {
		return fmt.Errorf("failed to create config directory: %w", err)
	}

	content := a.buildDecorationsConfig(config)

	if err := os.WriteFile(configPath, []byte(content), 0644); err != nil {
		return fmt.Errorf("failed to write config file: %w", err)
	}

	return nil
}

// buildDecorationsConfig builds the configuration file content
func (a *App) buildDecorationsConfig(config *DecorationsFullConfig) string {
	var builder strings.Builder

	builder.WriteString("# Decorations Configuration\n")
	builder.WriteString("# Generated by Hecate Helper\n\n")

	// General section
	builder.WriteString("general {\n")
	builder.WriteString(fmt.Sprintf("    border_size = %d\n", config.General.BorderSize))
	builder.WriteString(fmt.Sprintf("    gaps_in = %s\n", config.General.GapsIn))
	builder.WriteString(fmt.Sprintf("    gaps_out = %s\n", config.General.GapsOut))
	builder.WriteString(fmt.Sprintf("    float_gaps = %s\n", config.General.FloatGaps))
	builder.WriteString(fmt.Sprintf("    gaps_workspaces = %d\n", config.General.GapsWorkspaces))
	builder.WriteString(fmt.Sprintf("    col.inactive_border = %s\n", config.General.ColInactiveBorder))
	builder.WriteString(fmt.Sprintf("    col.active_border = %s\n", config.General.ColActiveBorder))
	builder.WriteString(fmt.Sprintf("    col.nogroup_border = %s\n", config.General.ColNogroupBorder))
	builder.WriteString(fmt.Sprintf("    col.nogroup_border_active = %s\n", config.General.ColNogroupBorderActive))
	builder.WriteString(fmt.Sprintf("    layout = %s\n", config.General.Layout))
	builder.WriteString(fmt.Sprintf("    no_focus_fallback = %s\n", formatBool(config.General.NoFocusFallback)))
	builder.WriteString(fmt.Sprintf("    resize_on_border = %s\n", formatBool(config.General.ResizeOnBorder)))
	builder.WriteString(fmt.Sprintf("    extend_border_grab_area = %d\n", config.General.ExtendBorderGrabArea))
	builder.WriteString(fmt.Sprintf("    hover_icon_on_border = %s\n", formatBool(config.General.HoverIconOnBorder)))
	builder.WriteString(fmt.Sprintf("    allow_tearing = %s\n", formatBool(config.General.AllowTearing)))
	builder.WriteString(fmt.Sprintf("    resize_corner = %d\n", config.General.ResizeCorner))
	builder.WriteString(fmt.Sprintf("    modal_parent_blocking = %s\n", formatBool(config.General.ModalParentBlocking)))
	if config.General.Locale != "" {
		builder.WriteString(fmt.Sprintf("    locale = %s\n", config.General.Locale))
	}

	// Snap subsection
	builder.WriteString("\n    snap {\n")
	builder.WriteString(fmt.Sprintf("        enabled = %s\n", formatBool(config.Snap.Enabled)))
	builder.WriteString(fmt.Sprintf("        window_gap = %d\n", config.Snap.WindowGap))
	builder.WriteString(fmt.Sprintf("        monitor_gap = %d\n", config.Snap.MonitorGap))
	builder.WriteString(fmt.Sprintf("        border_overlap = %s\n", formatBool(config.Snap.BorderOverlap)))
	builder.WriteString(fmt.Sprintf("        respect_gaps = %s\n", formatBool(config.Snap.RespectGaps)))
	builder.WriteString("    }\n")
	builder.WriteString("}\n\n")

	// Decoration section
	builder.WriteString("decoration {\n")
	builder.WriteString(fmt.Sprintf("    rounding = %d\n", config.Decoration.Rounding))
	builder.WriteString(fmt.Sprintf("    rounding_power = %.1f\n", config.Decoration.RoundingPower))
	builder.WriteString(fmt.Sprintf("    active_opacity = %.1f\n", config.Decoration.ActiveOpacity))
	builder.WriteString(fmt.Sprintf("    inactive_opacity = %.1f\n", config.Decoration.InactiveOpacity))
	builder.WriteString(fmt.Sprintf("    fullscreen_opacity = %.1f\n", config.Decoration.FullscreenOpacity))
	builder.WriteString(fmt.Sprintf("    dim_modal = %s\n", formatBool(config.Decoration.DimModal)))
	builder.WriteString(fmt.Sprintf("    dim_inactive = %s\n", formatBool(config.Decoration.DimInactive)))
	builder.WriteString(fmt.Sprintf("    dim_strength = %.1f\n", config.Decoration.DimStrength))
	builder.WriteString(fmt.Sprintf("    dim_special = %.1f\n", config.Decoration.DimSpecial))
	builder.WriteString(fmt.Sprintf("    dim_around = %.1f\n", config.Decoration.DimAround))
	if config.Decoration.ScreenShader != "" {
		builder.WriteString(fmt.Sprintf("    screen_shader = %s\n", config.Decoration.ScreenShader))
	}
	builder.WriteString(fmt.Sprintf("    border_part_of_window = %s\n", formatBool(config.Decoration.BorderPartOfWindow)))

	// Blur subsection
	builder.WriteString("\n    blur {\n")
	builder.WriteString(fmt.Sprintf("        enabled = %s\n", formatBool(config.Blur.Enabled)))
	builder.WriteString(fmt.Sprintf("        size = %d\n", config.Blur.Size))
	builder.WriteString(fmt.Sprintf("        passes = %d\n", config.Blur.Passes))
	builder.WriteString(fmt.Sprintf("        ignore_opacity = %s\n", formatBool(config.Blur.IgnoreOpacity)))
	builder.WriteString(fmt.Sprintf("        new_optimizations = %s\n", formatBool(config.Blur.NewOptimizations)))
	builder.WriteString(fmt.Sprintf("        xray = %s\n", formatBool(config.Blur.Xray)))
	builder.WriteString(fmt.Sprintf("        noise = %.4f\n", config.Blur.Noise))
	builder.WriteString(fmt.Sprintf("        contrast = %.4f\n", config.Blur.Contrast))
	builder.WriteString(fmt.Sprintf("        brightness = %.4f\n", config.Blur.Brightness))
	builder.WriteString(fmt.Sprintf("        vibrancy = %.4f\n", config.Blur.Vibrancy))
	builder.WriteString(fmt.Sprintf("        vibrancy_darkness = %.1f\n", config.Blur.VibrancyDarkness))
	builder.WriteString(fmt.Sprintf("        special = %s\n", formatBool(config.Blur.Special)))
	builder.WriteString(fmt.Sprintf("        popups = %s\n", formatBool(config.Blur.Popups)))
	builder.WriteString(fmt.Sprintf("        popups_ignorealpha = %.1f\n", config.Blur.PopupsIgnorealpha))
	builder.WriteString(fmt.Sprintf("        input_methods = %s\n", formatBool(config.Blur.InputMethods)))
	builder.WriteString(fmt.Sprintf("        input_methods_ignorealpha = %.1f\n", config.Blur.InputMethodsIgnorealpha))
	builder.WriteString("    }\n")
	builder.WriteString("}\n")

	return builder.String()
}

// getDefaultDecorationsConfig returns default configuration values
func (a *App) getDefaultDecorationsConfig() *DecorationsFullConfig {
	return &DecorationsFullConfig{
		General: GeneralConfig{
			BorderSize:             1,
			GapsIn:                 "5",
			GapsOut:                "20",
			FloatGaps:              "0",
			GapsWorkspaces:         0,
			ColInactiveBorder:      "0xff444444",
			ColActiveBorder:        "0xffffffff",
			ColNogroupBorder:       "0xffffaaff",
			ColNogroupBorderActive: "0xffff00ff",
			Layout:                 "dwindle",
			NoFocusFallback:        false,
			ResizeOnBorder:         false,
			ExtendBorderGrabArea:   15,
			HoverIconOnBorder:      true,
			AllowTearing:           false,
			ResizeCorner:           0,
			ModalParentBlocking:    true,
			Locale:                 "",
		},
		Snap: SnapConfig{
			Enabled:       false,
			WindowGap:     10,
			MonitorGap:    10,
			BorderOverlap: false,
			RespectGaps:   false,
		},
		Decoration: DecorationConfig{
			Rounding:           0,
			RoundingPower:      2.0,
			ActiveOpacity:      1.0,
			InactiveOpacity:    1.0,
			FullscreenOpacity:  1.0,
			DimModal:           true,
			DimInactive:        false,
			DimStrength:        0.5,
			DimSpecial:         0.2,
			DimAround:          0.4,
			ScreenShader:       "",
			BorderPartOfWindow: true,
		},
		Blur: BlurConfig{
			Enabled:                 true,
			Size:                    8,
			Passes:                  1,
			IgnoreOpacity:           true,
			NewOptimizations:        true,
			Xray:                    false,
			Noise:                   0.0117,
			Contrast:                0.8916,
			Brightness:              0.8172,
			Vibrancy:                0.1696,
			VibrancyDarkness:        0.0,
			Special:                 false,
			Popups:                  false,
			PopupsIgnorealpha:       0.2,
			InputMethods:            false,
			InputMethodsIgnorealpha: 0.2,
		},
	}
}

// Helper functions
func parseBool(value string) bool {
	value = strings.ToLower(strings.TrimSpace(value))
	return value == "true" || value == "1" || value == "yes"
}

func formatBool(value bool) string {
	if value {
		return "true"
	}
	return "false"
}
