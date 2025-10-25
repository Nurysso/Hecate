package main

import (
	"bufio"
	"bytes"
	"embed"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/wailsapp/wails/v2"
	"github.com/wailsapp/wails/v2/pkg/options"
	"github.com/wailsapp/wails/v2/pkg/options/assetserver"
)

//go:embed all:frontend/dist
var assets embed.FS

type Keybind struct {
	Mods        string `json:"mods"`
	Key         string `json:"key"`
	Action      string `json:"action"`
	Description string `json:"description"`
	Category    string `json:"category"`
	IsCommented bool   `json:"isCommented"`
	RawLine     string `json:"rawLine"`
}

// GetKeybinds reads and parses the keybinds.conf file
func (a *App) GetKeybinds() []Keybind {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return []Keybind{}
	}

	configPath := filepath.Join(homeDir, ".config", "hypr", "configs", "keybinds.conf")
	file, err := os.Open(configPath)
	if err != nil {
		return []Keybind{}
	}
	defer file.Close()

	var keybinds []Keybind
	scanner := bufio.NewScanner(file)

	// Improved regex to match all bind variants: bind, bindl, binde, bindr, bindt, bindm
	// Matches: bind[lertm]* = MODS, KEY, ACTION or # bind[lertm]* = MODS, KEY, ACTION
	bindPattern := regexp.MustCompile(`^\s*(#)?\s*bind([lertm]*)\s*=\s*([^,]*),\s*([^,]+),\s*(.+)$`)

	currentCategory := "General"

	for scanner.Scan() {
		line := scanner.Text()
		trimmedLine := strings.TrimSpace(line)

		// Skip empty lines
		if trimmedLine == "" {
			continue
		}

		// Check for ignore marker (#.) - skip these lines completely
		if strings.HasPrefix(trimmedLine, "#.") {
			continue
		}

		// Check for category markers (#/) BEFORE anything else
		if strings.HasPrefix(trimmedLine, "#/") {
			categoryText := strings.TrimPrefix(trimmedLine, "#/")
			categoryText = strings.TrimSpace(categoryText)
			if categoryText != "" {
				currentCategory = categoryText
			}
			continue
		}

		// Check if it's a commented bind (# bind...) - DON'T skip these
		// They'll be caught by the regex below with isCommented = true
		isCommentedBind := strings.HasPrefix(trimmedLine, "#") &&
			strings.Contains(trimmedLine, "bind")

		// Skip regular comment lines (starting with # but not bind-related)
		if strings.HasPrefix(trimmedLine, "#") && !isCommentedBind {
			continue
		}

		// Parse bind lines (including bindm, bindl, etc.)
		matches := bindPattern.FindStringSubmatch(line)
		if len(matches) >= 6 {
			isCommented := matches[1] == "#"
			bindType := matches[2] // l, e, r, t, m, or empty
			mods := strings.TrimSpace(matches[3])
			key := strings.TrimSpace(matches[4])
			action := strings.TrimSpace(matches[5])

			// Skip invalid entries (must have at least a key and action)
			if key == "" || action == "" {
				continue
			}

			actionName, description := parseActionAndDescription(action)

			// Skip if action name is empty after parsing
			if actionName == "" {
				continue
			}

			keybind := Keybind{
				Mods:        formatModifiers(mods),
				Key:         formatKey(key),
				Action:      actionName,
				Description: description,
				Category:    currentCategory,
				IsCommented: isCommented,
				RawLine:     line,
			}

			// Optionally add bind type to description for special binds
			if bindType == "m" && description == actionName {
				keybind.Description = formatBindTypeDescription(bindType, actionName)
			}

			keybinds = append(keybinds, keybind)
		}
	}

	return keybinds
}

// parseActionAndDescription extracts action and description from the action string
func parseActionAndDescription(action string) (string, string) {
	actionName := action
	description := action

	// Try to extract description from inline comments first
	if commentIdx := strings.Index(action, "#"); commentIdx != -1 {
		actionName = strings.TrimSpace(action[:commentIdx])
		description = strings.TrimSpace(action[commentIdx+1:])
	}

	// Keep the full action name (including parameters after commas)
	// Don't truncate at commas - they're part of the dispatcher command
	return actionName, description
}

// formatBindTypeDescription creates a description for special bind types
func formatBindTypeDescription(bindType, actionName string) string {
	switch bindType {
	case "m":
		return "Mouse: " + actionName
	case "l":
		return "Locked: " + actionName
	case "e":
		return "On Release: " + actionName
	case "r":
		return "Repeat: " + actionName
	case "t":
		return "Transparent: " + actionName
	default:
		return actionName
	}
}

// formatModifiers converts Hyprland modifiers to readable format
func formatModifiers(mods string) string {
	if mods == "" {
		return ""
	}

	mods = strings.ToUpper(strings.TrimSpace(mods))

	// Replace common modifier names
	replacements := map[string]string{
		"SUPER":    "SUPER",
		"ALT":      "ALT",
		"CTRL":     "CTRL",
		"CONTROL":  "CTRL",
		"SHIFT":    "SHIFT",
		"MOD4":     "SUPER",
		"MOD1":     "ALT",
		"$MAINMOD": "SUPER",
	}

	for old, new := range replacements {
		mods = strings.ReplaceAll(mods, old, new)
	}

	// Handle various separator formats
	mods = strings.ReplaceAll(mods, "_", " + ")
	mods = strings.ReplaceAll(mods, "+", " + ")

	// Clean up multiple spaces and separators
	parts := strings.Fields(mods)
	cleaned := make([]string, 0, len(parts))
	for _, part := range parts {
		if part != "+" {
			cleaned = append(cleaned, part)
		}
	}

	return strings.Join(cleaned, " + ")
}

// formatKey formats the key name for display
func formatKey(key string) string {
	key = strings.TrimSpace(key)

	// Common key replacements
	replacements := map[string]string{
		"return":     "Return",
		"space":      "Space",
		"tab":        "Tab",
		"print":      "Print",
		"escape":     "Escape",
		"backspace":  "Backspace",
		"delete":     "Delete",
		"insert":     "Insert",
		"home":       "Home",
		"end":        "End",
		"pageup":     "PageUp",
		"pagedown":   "PageDown",
		"up":         "↑",
		"down":       "↓",
		"left":       "←",
		"right":      "→",
		"mouse:272":  "Mouse Left",
		"mouse:273":  "Mouse Right",
		"mouse:274":  "Mouse Middle",
	}

	lowerKey := strings.ToLower(key)
	if replacement, exists := replacements[lowerKey]; exists {
		return replacement
	}

	// Handle special keys that might have codes
	if strings.HasPrefix(lowerKey, "code:") {
		return strings.TrimPrefix(key, "code:")
	}

	// Capitalize first letter for other keys
	if len(key) > 0 {
		return strings.ToUpper(string(key[0])) + strings.ToLower(key[1:])
	}

	return key
}

// OpenConfigInNeovim opens the keybinds config file in neovim
func (a *App) OpenConfigInNeovim() error {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return err
	}

	scriptPath := filepath.Join(homeDir, ".local", "bin", "hecate")
	configFile := filepath.Join(homeDir, ".config", "hypr", "configs", "keybinds.conf")

	// Try to get terminal from script
	terminal := "kitty" // default fallback
	cmdGetTerm := exec.Command("bash", scriptPath, "term")

	var out bytes.Buffer
	cmdGetTerm.Stdout = &out

	if err := cmdGetTerm.Run(); err == nil {
		if term := strings.TrimSpace(out.String()); term != "" {
			terminal = term
		}
	}

	// Launch Neovim in the detected terminal
	cmd := exec.Command(terminal, "-e", "nvim", configFile)
	return cmd.Start()
}

func main() {
	app := NewApp()

	err := wails.Run(&options.App{
		Title:            "Hecate Helper",
		Width:            1200,
		Height:           800,
		AssetServer:      &assetserver.Options{Assets: assets},
		BackgroundColour: &options.RGBA{R: 15, G: 20, B: 22, A: 1},
		OnStartup:        app.startup,
		Bind:             []interface{}{app},
	})

	if err != nil {
		println("Error:", err.Error())
	}
}
