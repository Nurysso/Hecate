package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

type WaybarConfig struct {
	CurrentConfig    string   `json:"currentConfig"`
	CurrentStyle     string   `json:"currentStyle"`
	AvailableConfigs []string `json:"availableConfigs"`
	AvailableStyles  []string `json:"availableStyles"`
}

type WaybarSelection struct {
	Config string `json:"config"`
	Style  string `json:"style"`
}

// GetWaybarConfig reads current waybar configuration
func (a *App) GetWaybarConfig() (WaybarConfig, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return WaybarConfig{}, err
	}

	waybarDir := filepath.Join(homeDir, ".config", "waybar")
	configsDir := filepath.Join(waybarDir, "configs")
	stylesDir := filepath.Join(waybarDir, "style")

	config := WaybarConfig{
		AvailableConfigs: []string{},
		AvailableStyles:  []string{},
	}

	// Get current config (resolve symlink)
	configLink := filepath.Join(waybarDir, "config")
	if target, err := os.Readlink(configLink); err == nil {
		// Handle both relative and absolute paths
		if filepath.IsAbs(target) {
			config.CurrentConfig = filepath.Base(target)
		} else {
			config.CurrentConfig = filepath.Base(target)
		}
	}

	// Get current style (resolve symlink)
	styleLink := filepath.Join(waybarDir, "style.css")
	if target, err := os.Readlink(styleLink); err == nil {
		// Handle both relative and absolute paths
		if filepath.IsAbs(target) {
			config.CurrentStyle = filepath.Base(target)
		} else {
			config.CurrentStyle = filepath.Base(target)
		}
	}

	// List available configs
	if entries, err := os.ReadDir(configsDir); err == nil {
		for _, entry := range entries {
			if !entry.IsDir() && !strings.HasPrefix(entry.Name(), ".") {
				config.AvailableConfigs = append(config.AvailableConfigs, entry.Name())
			}
		}
	}

	// List available styles
	if entries, err := os.ReadDir(stylesDir); err == nil {
		for _, entry := range entries {
			if !entry.IsDir() && strings.HasSuffix(entry.Name(), ".css") && !strings.HasPrefix(entry.Name(), ".") {
				config.AvailableStyles = append(config.AvailableStyles, entry.Name())
			}
		}
	}

	return config, nil
}

// ApplyWaybarConfig updates the waybar symlinks
func (a *App) ApplyWaybarConfig(selection WaybarSelection) error {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return err
	}

	waybarDir := filepath.Join(homeDir, ".config", "waybar")
	configsDir := filepath.Join(waybarDir, "configs")
	stylesDir := filepath.Join(waybarDir, "style")

	// Validate directories exist
	if _, err := os.Stat(configsDir); os.IsNotExist(err) {
		return fmt.Errorf("configs directory not found: %s", configsDir)
	}
	if _, err := os.Stat(stylesDir); os.IsNotExist(err) {
		return fmt.Errorf("styles directory not found: %s", stylesDir)
	}

	// Validate config exists
	configPath := filepath.Join(configsDir, selection.Config)
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		return fmt.Errorf("config not found: %s", selection.Config)
	}

	// Validate style exists
	stylePath := filepath.Join(stylesDir, selection.Style)
	if _, err := os.Stat(stylePath); os.IsNotExist(err) {
		return fmt.Errorf("style not found: %s", selection.Style)
	}

	// Update config symlink (use absolute path for safety)
	configLink := filepath.Join(waybarDir, "config")
	if err := updateSymlink(configLink, configPath); err != nil {
		return fmt.Errorf("failed to update config symlink: %w", err)
	}

	// Update style symlink (use absolute path for safety)
	styleLink := filepath.Join(waybarDir, "style.css")
	if err := updateSymlink(styleLink, stylePath); err != nil {
		return fmt.Errorf("failed to update style symlink: %w", err)
	}

	// Reload waybar
	if err := a.ReloadWaybar(); err != nil {
		// Don't fail if reload doesn't work, just log
		fmt.Printf("Warning: failed to reload waybar: %v\n", err)
	}

	return nil
}

// GetWaybarPreview reads a preview or description of a config/style
func (a *App) GetWaybarPreview(configType string, name string) (string, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}

	waybarDir := filepath.Join(homeDir, ".config", "waybar")
	var filePath string

	if configType == "config" {
		filePath = filepath.Join(waybarDir, "configs", name) // Fixed: was "config", should be "configs"
	} else if configType == "style" {
		filePath = filepath.Join(waybarDir, "style", name)
	} else {
		return "", fmt.Errorf("invalid config type: %s", configType)
	}

	// Check if file exists
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		return "", fmt.Errorf("file not found: %s", name)
	}

	// Read first 500 bytes as preview
	data, err := os.ReadFile(filePath)
	if err != nil {
		return "", err
	}

	preview := string(data)
	if len(preview) > 500 {
		preview = preview[:500] + "..."
	}

	return preview, nil
}

// updateSymlink removes old symlink and creates new one
func updateSymlink(linkPath string, targetPath string) error {
	// Remove existing symlink or file
	if _, err := os.Lstat(linkPath); err == nil {
		if err := os.Remove(linkPath); err != nil {
			return fmt.Errorf("failed to remove old symlink: %w", err)
		}
	}

	// Create new symlink with absolute path
	if err := os.Symlink(targetPath, linkPath); err != nil {
		return fmt.Errorf("failed to create symlink: %w", err)
	}

	return nil
}

// CreateWaybarBackup creates a backup of current waybar config
func (a *App) CreateWaybarBackup() (string, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}

	waybarDir := filepath.Join(homeDir, ".config", "waybar")
	backupDir := filepath.Join(waybarDir, "backups")

	// Create backups directory if it doesn't exist
	if err := os.MkdirAll(backupDir, 0755); err != nil {
		return "", fmt.Errorf("failed to create backup directory: %w", err)
	}

	// Create timestamped backup
	timestamp := fmt.Sprintf("%d", os.Getpid()) // Using PID as simple timestamp
	backupName := fmt.Sprintf("backup_%s", timestamp)
	backupPath := filepath.Join(backupDir, backupName)

	if err := os.MkdirAll(backupPath, 0755); err != nil {
		return "", err
	}

	// Copy current config
	configLink := filepath.Join(waybarDir, "config")
	if target, err := os.Readlink(configLink); err == nil {
		var srcPath string
		if filepath.IsAbs(target) {
			srcPath = target
		} else {
			srcPath = filepath.Join(waybarDir, target)
		}
		dstPath := filepath.Join(backupPath, "config")
		if err := copyFile(srcPath, dstPath); err != nil {
			return "", fmt.Errorf("failed to backup config: %w", err)
		}
	}

	// Copy current style
	styleLink := filepath.Join(waybarDir, "style.css")
	if target, err := os.Readlink(styleLink); err == nil {
		var srcPath string
		if filepath.IsAbs(target) {
			srcPath = target
		} else {
			srcPath = filepath.Join(waybarDir, target)
		}
		dstPath := filepath.Join(backupPath, "style.css")
		if err := copyFile(srcPath, dstPath); err != nil {
			return "", fmt.Errorf("failed to backup style: %w", err)
		}
	}

	return backupName, nil
}

// copyFile copies a file from src to dst
func copyFile(src, dst string) error {
	data, err := os.ReadFile(src)
	if err != nil {
		return err
	}
	return os.WriteFile(dst, data, 0644)
}

// ListWaybarBackups returns list of available backups
func (a *App) ListWaybarBackups() ([]string, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return nil, err
	}

	backupDir := filepath.Join(homeDir, ".config", "waybar", "backups")

	// Check if backup directory exists
	if _, err := os.Stat(backupDir); os.IsNotExist(err) {
		return []string{}, nil
	}

	entries, err := os.ReadDir(backupDir)
	if err != nil {
		return nil, err
	}

	backups := []string{}
	for _, entry := range entries {
		if entry.IsDir() && strings.HasPrefix(entry.Name(), "backup_") {
			backups = append(backups, entry.Name())
		}
	}

	return backups, nil
}

// RestoreWaybarBackup restores a backup
func (a *App) RestoreWaybarBackup(backupName string) error {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return err
	}

	waybarDir := filepath.Join(homeDir, ".config", "waybar")
	backupPath := filepath.Join(waybarDir, "backups", backupName)

	// Validate backup exists
	if _, err := os.Stat(backupPath); os.IsNotExist(err) {
		return fmt.Errorf("backup not found: %s", backupName)
	}

	// Restore config
	configBackup := filepath.Join(backupPath, "config")
	if _, err := os.Stat(configBackup); err == nil {
		configLink := filepath.Join(waybarDir, "config")
		if err := updateSymlink(configLink, configBackup); err != nil {
			return fmt.Errorf("failed to restore config: %w", err)
		}
	}

	// Restore style
	styleBackup := filepath.Join(backupPath, "style.css")
	if _, err := os.Stat(styleBackup); err == nil {
		styleLink := filepath.Join(waybarDir, "style.css")
		if err := updateSymlink(styleLink, styleBackup); err != nil {
			return fmt.Errorf("failed to restore style: %w", err)
		}
	}

	// Reload waybar
	if err := a.ReloadWaybar(); err != nil {
		fmt.Printf("Warning: failed to reload waybar: %v\n", err)
	}

	return nil
}
