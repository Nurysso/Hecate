package main

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/wailsapp/wails/v2/pkg/runtime"
)

// HyprlandClient represents a window from hyprctl clients -j
type HyprlandClient struct {
	Address          string                 `json:"address"`
	Mapped           bool                   `json:"mapped"`
	Hidden           bool                   `json:"hidden"`
	At               []int                  `json:"at"`
	Size             []int                  `json:"size"`
	Workspace        map[string]interface{} `json:"workspace"`
	Floating         bool                   `json:"floating"`
	Pseudo           bool                   `json:"pseudo"`
	Monitor          int                    `json:"monitor"`
	Class            string                 `json:"class"`
	Title            string                 `json:"title"`
	InitialClass     string                 `json:"initialClass"`
	InitialTitle     string                 `json:"initialTitle"`
	PID              int                    `json:"pid"`
	Xwayland         bool                   `json:"xwayland"`
	Pinned           bool                   `json:"pinned"`
	Fullscreen       int                    `json:"fullscreen"`
	FullscreenClient int                    `json:"fullscreenClient"`
	Grouped          []string               `json:"grouped"`
	Tags             []string               `json:"tags"`
	Swallowing       string                 `json:"swallowing"`
	FocusHistoryID   int                    `json:"focusHistoryID"`
}

// WindowRule represents a Hyprland window rule
type WindowRule struct {
	Rule       string `json:"rule"`
	Class      string `json:"class"`
	Title      string `json:"title"`
	UseInitial bool   `json:"useInitial"`
}

// GetOpenWindows retrieves all open windows from Hyprland
func (a *App) GetOpenWindows() ([]HyprlandClient, error) {
	cmd := exec.Command("hyprctl", "clients", "-j")
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to execute hyprctl: %v", err)
	}

	var clients []HyprlandClient
	if err := json.Unmarshal(output, &clients); err != nil {
		return nil, fmt.Errorf("failed to parse hyprctl output: %v", err)
	}

	return clients, nil
}

// GenerateWindowRule creates a window rule string
func (a *App) GenerateWindowRule(rule, class, title string, useInitial bool) string {
	var params []string

	if class != "" {
		if useInitial {
			params = append(params, fmt.Sprintf("initialClass:^(%s)$", class))
		} else {
			params = append(params, fmt.Sprintf("class:^(%s)$", class))
		}
	}

	if title != "" {
		if useInitial {
			params = append(params, fmt.Sprintf("initialTitle:^(%s)$", title))
		} else {
			params = append(params, fmt.Sprintf("title:^(%s)$", title))
		}
	}

	if len(params) == 0 {
		return ""
	}

	// Format with spaces to match your config file style
	return fmt.Sprintf("windowrulev2 = %s, %s", rule, strings.Join(params, ", "))
}

// SaveWindowRule saves a window rule to hyprland.conf
func (a *App) SaveWindowRule(ruleStr string) error {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return fmt.Errorf("failed to get home directory: %v", err)
	}

	configPath := filepath.Join(homeDir, ".config", "hypr", "configs", "WindowRules.conf")

	// Check if file exists, create if it doesn't
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		// Create directory structure if it doesn't exist
		dir := filepath.Dir(configPath)
		if err := os.MkdirAll(dir, 0755); err != nil {
			return fmt.Errorf("failed to create config directory: %v", err)
		}
		// Create empty file
		if err := os.WriteFile(configPath, []byte{}, 0644); err != nil {
			return fmt.Errorf("failed to create config file: %v", err)
		}
	}

	// Read existing config
	content, err := os.ReadFile(configPath)
	if err != nil {
		return fmt.Errorf("failed to read config file: %v", err)
	}

	// Check if rule already exists
	lines := strings.Split(string(content), "\n")
	for _, line := range lines {
		if strings.TrimSpace(line) == ruleStr {
			return fmt.Errorf("rule already exists")
		}
	}

	// Append the new rule
	newContent := string(content)
	if len(newContent) > 0 && !strings.HasSuffix(newContent, "\n") {
		newContent += "\n"
	}
	newContent += ruleStr + "\n"

	// Write back to file
	if err := os.WriteFile(configPath, []byte(newContent), 0644); err != nil {
		return fmt.Errorf("failed to write config file: %v", err)
	}

	// Reload Hyprland config
	cmd := exec.Command("hyprctl", "reload")
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to reload hyprland config: %v", err)
	}

	return nil
}

// GetExistingRules retrieves existing window rules from hyprland.conf
func (a *App) GetExistingRules() ([]string, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return nil, fmt.Errorf("failed to get home directory: %v", err)
	}

	configPath := filepath.Join(homeDir, ".config", "hypr", "configs", "WindowRules.conf")

	// Check if file exists
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		return []string{}, nil // Return empty slice if file doesn't exist
	}

	content, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %v", err)
	}

	var rules []string
	lines := strings.Split(string(content), "\n")
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		// Skip empty lines and comments
		if trimmed == "" || strings.HasPrefix(trimmed, "#") {
			continue
		}
		// Only include window rules (not layer rules)
		// Check for both with and without spaces after the keyword
		if strings.HasPrefix(trimmed, "windowrulev2") || strings.HasPrefix(trimmed, "windowrule") {
			// Make sure it's not a layerrule
			if !strings.HasPrefix(trimmed, "layerrule") {
				rules = append(rules, trimmed)
			}
		}
	}

    fmt.Printf("Config path: %s\n", configPath)
    fmt.Printf("File content length: %d bytes\n", len(content))
    fmt.Printf("Total lines: %d\n", len(lines))
    fmt.Printf("Rules found: %d\n", len(rules))


	return rules, nil
}

// RemoveWindowRule removes a window rule from hyprland.conf
func (a *App) RemoveWindowRule(ruleStr string) error {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return fmt.Errorf("failed to get home directory: %v", err)
	}

	configPath := filepath.Join(homeDir, ".config", "hypr", "configs", "WindowRules.conf")
	content, err := os.ReadFile(configPath)
	if err != nil {
		return fmt.Errorf("failed to read config file: %v", err)
	}

	lines := strings.Split(string(content), "\n")
	var newLines []string
	found := false
	for _, line := range lines {
		if strings.TrimSpace(line) == ruleStr {
			found = true
			continue // Skip this line (remove it)
		}
		newLines = append(newLines, line)
	}

	if !found {
		return fmt.Errorf("rule not found in config file")
	}

	newContent := strings.Join(newLines, "\n")
	if err := os.WriteFile(configPath, []byte(newContent), 0644); err != nil {
		return fmt.Errorf("failed to write config file: %v", err)
	}

	// Reload Hyprland config
	cmd := exec.Command("hyprctl", "reload")
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to reload hyprland config: %v", err)
	}

	return nil
}

// ShowMessage displays a message dialog
func (a *App) ShowMessage(title, message string) {
	runtime.MessageDialog(a.ctx, runtime.MessageDialogOptions{
		Type:    runtime.InfoDialog,
		Title:   title,
		Message: message,
	})
}

// ShowError displays an error dialog
func (a *App) ShowError(title, message string) {
	runtime.MessageDialog(a.ctx, runtime.MessageDialogOptions{
		Type:    runtime.ErrorDialog,
		Title:   title,
		Message: message,
	})
}
