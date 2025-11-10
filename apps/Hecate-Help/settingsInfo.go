package main

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"image"
	"image/jpeg"
	_ "image/png"
	"bytes"
	"path/filepath"
	"encoding/base64"

	"github.com/nfnt/resize"
)

type SystemInfo struct {
	ctx context.Context
}

type SystemInfoData struct {
	OS              string  `json:"os"`
	Hostname        string  `json:"hostname"`
	CPU             string  `json:"cpu"`
	Memory          string  `json:"memory"`
	MemoryUsed      float64 `json:"memoryUsed"`
	MemoryTotal     float64 `json:"memoryTotal"`
	Uptime          string  `json:"uptime"`
	WallpaperBase64 string  `json:"wallpaperBase64"`
	LockscreenBase64 string `json:"lockscreenBase64"`
	UserPfpBase64   string  `json:"userPfpBase64"`
}

func NewSystemInfo() *SystemInfo {
	return &SystemInfo{}
}

func (s *SystemInfo) GetSystemInfo() SystemInfoData {
	memUsed, memTotal := s.getMemoryValues()
	return SystemInfoData{
		OS:               s.getOS(),
		Hostname:         s.getHostname(),
		CPU:              s.getCPU(),
		Memory:           s.getMemory(),
		MemoryUsed:       memUsed,
		MemoryTotal:      memTotal,
		Uptime:           s.getUptime(),
		WallpaperBase64:  s.getWallpaper(),
		LockscreenBase64: s.getLockscreenWallpaper(),
		UserPfpBase64:    s.getUserPfp(),
	}
}

func (a *App) GetSystemInfo() SystemInfoData {
	sysInfo := NewSystemInfo()
	return sysInfo.GetSystemInfo()
}

func (s *SystemInfo) getOS() string {
	data, err := os.ReadFile("/etc/os-release")
	if err == nil {
		lines := strings.Split(string(data), "\n")
		for _, line := range lines {
			if strings.HasPrefix(line, "PRETTY_NAME=") {
				name := strings.TrimPrefix(line, "PRETTY_NAME=")
				name = strings.Trim(name, "\"")
				return name
			}
		}
	}

	out, err := exec.Command("uname", "-o").Output()
	if err != nil {
		return "Unknown"
	}
	return strings.TrimSpace(string(out))
}

func (s *SystemInfo) getHostname() string {
	hostname, err := os.Hostname()
	if err != nil {
		return "Unknown"
	}
	return strings.TrimSpace(hostname)
}

func (s *SystemInfo) getCPU() string {
	data, err := os.ReadFile("/proc/cpuinfo")
	if err != nil {
		return "Unknown"
	}

	lines := strings.Split(string(data), "\n")
	for _, line := range lines {
		if strings.HasPrefix(line, "model name") {
			parts := strings.Split(line, ":")
			if len(parts) > 1 {
				return strings.TrimSpace(parts[1])
			}
		}
	}
	return "Unknown"
}

func (s *SystemInfo) getMemory() string {
	data, err := os.ReadFile("/proc/meminfo")
	if err != nil {
		return "Unknown"
	}

	var total, available int64
	lines := strings.Split(string(data), "\n")
	for _, line := range lines {
		if strings.HasPrefix(line, "MemTotal:") {
			fmt.Sscanf(line, "MemTotal: %d", &total)
		} else if strings.HasPrefix(line, "MemAvailable:") {
			fmt.Sscanf(line, "MemAvailable: %d", &available)
		}
	}

	if total > 0 {
		totalGB := float64(total) / 1024 / 1024
		usedGB := float64(total-available) / 1024 / 1024
		return fmt.Sprintf("%.1f GiB / %.1f GiB", usedGB, totalGB)
	}
	return "Unknown"
}

func (s *SystemInfo) getMemoryValues() (float64, float64) {
	data, err := os.ReadFile("/proc/meminfo")
	if err != nil {
		return 0, 0
	}

	var total, available int64
	lines := strings.Split(string(data), "\n")
	for _, line := range lines {
		if strings.HasPrefix(line, "MemTotal:") {
			fmt.Sscanf(line, "MemTotal: %d", &total)
		} else if strings.HasPrefix(line, "MemAvailable:") {
			fmt.Sscanf(line, "MemAvailable: %d", &available)
		}
	}

	if total > 0 {
		totalGB := float64(total) / 1024 / 1024
		usedGB := float64(total-available) / 1024 / 1024
		return usedGB, totalGB
	}
	return 0, 0
}

func (s *SystemInfo) getUptime() string {
	out, err := exec.Command("uptime", "-p").Output()
	if err != nil {
		return "Unknown"
	}
	uptime := strings.TrimSpace(string(out))
	return strings.TrimPrefix(uptime, "up ")
}

// getWallpaper gets current wallpaper from waypaper config
func (s *SystemInfo) getWallpaper() string {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return ""
	}

	configPath := filepath.Join(homeDir, ".config/waypaper/config.ini")
	data, err := os.ReadFile(configPath)
	if err != nil {
		return ""
	}

	var wallpaperPath string
	for _, line := range strings.Split(string(data), "\n") {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "wallpaper") {
			parts := strings.SplitN(line, "=", 2)
			if len(parts) == 2 {
				wallpaperPath = strings.TrimSpace(parts[1])
				if strings.HasPrefix(wallpaperPath, "~/") {
					wallpaperPath = filepath.Join(homeDir, wallpaperPath[2:])
				}
				break
			}
		}
	}

	if wallpaperPath == "" {
		return ""
	}

	if _, err := os.Stat(wallpaperPath); os.IsNotExist(err) {
		return ""
	}

	return compressImage(wallpaperPath)
}

// getLockscreenWallpaper extracts wallpaper path from hyprlock.conf
func (s *SystemInfo) getLockscreenWallpaper() string {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return ""
	}

	configPath := filepath.Join(homeDir, ".config/hypr/hyprlock.conf")
	data, err := os.ReadFile(configPath)
	if err != nil {
		return ""
	}

	content := string(data)
	lines := strings.Split(content, "\n")
	inBackground := false

	for _, line := range lines {
		line = strings.TrimSpace(line)

		if strings.Contains(line, "background") && strings.Contains(line, "{") {
			inBackground = true
			continue
		}

		if inBackground && strings.Contains(line, "}") {
			inBackground = false
			continue
		}

		if inBackground && strings.HasPrefix(line, "path") {
			parts := strings.SplitN(line, "=", 2)
			if len(parts) == 2 {
				wallpaperPath := strings.TrimSpace(parts[1])

				if idx := strings.Index(wallpaperPath, "#"); idx != -1 {
					wallpaperPath = strings.TrimSpace(wallpaperPath[:idx])
				}

				wallpaperPath = strings.Replace(wallpaperPath, "$HOME", homeDir, -1)

				if strings.HasPrefix(wallpaperPath, "~/") {
					wallpaperPath = filepath.Join(homeDir, wallpaperPath[2:])
				}

				if _, err := os.Stat(wallpaperPath); os.IsNotExist(err) {
					return ""
				}

				return compressImage(wallpaperPath)
			}
		}
	}

	return ""
}

// getUserPfp loads user profile picture
func (s *SystemInfo) getUserPfp() string {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return ""
	}

	pfpPath := filepath.Join(homeDir, ".config/hecate/user.png")

	if _, err := os.Stat(pfpPath); os.IsNotExist(err) {
		return ""
	}

	return compressImage(pfpPath)
}

// compressImage compresses and converts image to base64
func compressImage(path string) string {
	file, err := os.Open(path)
	if err != nil {
		return ""
	}
	defer file.Close()

	img, _, err := image.Decode(file)
	if err != nil {
		return ""
	}

	resized := resize.Resize(800, 0, img, resize.Lanczos3)

	var buf bytes.Buffer
	err = jpeg.Encode(&buf, resized, &jpeg.Options{Quality: 75})
	if err != nil {
		return ""
	}

	encoded := base64.StdEncoding.EncodeToString(buf.Bytes())
	return fmt.Sprintf("data:image/jpeg;base64,%s", encoded)
}

// OpenFileDialog opens file picker dialog and filters for images only
func (a *App) OpenFileDialog() (string, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		homeDir = "/"
	}

	// Default to Pictures directory if it exists
	picturesDir := filepath.Join(homeDir, "Pictures")
	if _, err := os.Stat(picturesDir); os.IsNotExist(err) {
		picturesDir = homeDir
	}

	var selectedPath string
	var lastErr error

	// 1. Try yad (Yet Another Dialog - common in Arch/Hyprland setups)
	if yadPath, err := exec.LookPath("yad"); err == nil {
		cmd := exec.Command(yadPath,
			"--file",
			"--title=Select Wallpaper",
			"--filename="+picturesDir+"/",
			"--file-filter=Images|*.jpg *.jpeg *.png *.webp *.JPG *.JPEG *.PNG *.WEBP",
			"--file-filter=All files|*",
		)
		output, err := cmd.Output()
		if err != nil {
			// User likely cancelled
			return "", fmt.Errorf("file selection cancelled")
		}
		selectedPath = strings.TrimSpace(string(output))
		selectedPath = strings.TrimSuffix(selectedPath, "|")
		lastErr = nil
	} else if zenityPath, err := exec.LookPath("zenity"); err == nil {
		// 2. Try zenity if yad not available
		cmd := exec.Command(zenityPath,
			"--file-selection",
			"--title=Select Wallpaper",
			"--filename="+picturesDir+"/",
			"--file-filter=Images | *.jpg *.jpeg *.png *.webp *.JPG *.JPEG *.PNG *.WEBP",
			"--file-filter=All files | *",
		)
		output, err := cmd.Output()
		if err != nil {
			// User likely cancelled
			return "", fmt.Errorf("file selection cancelled")
		}
		selectedPath = strings.TrimSpace(string(output))
		lastErr = nil
	} else if kdialogPath, err := exec.LookPath("kdialog"); err == nil {
		// 3. Try kdialog if others not available
		cmd := exec.Command(kdialogPath,
			"--getopenfilename",
			picturesDir,
			"*.jpg *.jpeg *.png *.webp *.JPG *.JPEG *.PNG *.WEBP|Image files",
		)
		output, err := cmd.Output()
		if err != nil {
			// User likely cancelled
			return "", fmt.Errorf("file selection cancelled")
		}
		selectedPath = strings.TrimSpace(string(output))
		lastErr = nil
	} else {
		// No dialog tool found
		if thunarPath, err := exec.LookPath("thunar"); err == nil {
			exec.Command(thunarPath, picturesDir).Start()
		}
		return "", fmt.Errorf("no file picker dialog found. Please install 'yad' or 'zenity': sudo pacman -S yad")
	}

	// If we got here but selectedPath is empty, user cancelled
	if selectedPath == "" {
		if lastErr != nil {
			return "", lastErr
		}
		return "", fmt.Errorf("file selection cancelled")
	}

	// Validate it's an image file
	ext := strings.ToLower(filepath.Ext(selectedPath))
	validExts := []string{".jpg", ".jpeg", ".png", ".webp"}
	isValid := false
	for _, validExt := range validExts {
		if ext == validExt {
			isValid = true
			break
		}
	}

	if !isValid {
		return "", fmt.Errorf("selected file is not a valid image format")
	}

	return selectedPath, nil
}

// SetWallpaper sets wallpaper using waypaper with hyprland backend
func (a *App) SetWallpaper(wallpaperPath string) error {
	// Verify the file exists
	if _, err := os.Stat(wallpaperPath); os.IsNotExist(err) {
		return fmt.Errorf("wallpaper file does not exist: %s", wallpaperPath)
	}

	// Use waypaper with hyprland backend and the wallpaper path
	cmd := exec.Command("waypaper", "--wallpaper", wallpaperPath)

	// Capture output for debugging
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("failed to set wallpaper: %v (output: %s)", err, string(output))
	}

	return nil
}

// SetLockscreenWallpaper updates hyprlock.conf with new wallpaper path
func (a *App) SetLockscreenWallpaper(wallpaperPath string) error {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return fmt.Errorf("failed to get home directory: %v", err)
	}

	// Verify the wallpaper file exists
	if _, err := os.Stat(wallpaperPath); os.IsNotExist(err) {
		return fmt.Errorf("wallpaper file does not exist: %s", wallpaperPath)
	}

	configPath := filepath.Join(homeDir, ".config/hypr/hyprlock.conf")
	data, err := os.ReadFile(configPath)
	if err != nil {
		return fmt.Errorf("failed to read hyprlock.conf: %v", err)
	}

	content := string(data)
	lines := strings.Split(content, "\n")
	inBackground := false
	modified := false
	braceDepth := 0

	for i, line := range lines {
		trimmedLine := strings.TrimSpace(line)

		// Track brace depth to handle nested blocks
		if strings.Contains(trimmedLine, "{") {
			braceDepth++
		}

		// Check if we're entering a background block
		if strings.HasPrefix(trimmedLine, "background") && strings.Contains(trimmedLine, "{") {
			inBackground = true
			continue
		}

		// Exit background block when we hit closing brace
		if inBackground && strings.Contains(trimmedLine, "}") {
			braceDepth--
			if braceDepth == 0 {
				inBackground = false
			}
			continue
		}

		// Update the path line if we're inside background block
		if inBackground && (strings.HasPrefix(trimmedLine, "path") || strings.Contains(trimmedLine, "path")) {
			// Extract current indentation
			indent := ""
			for _, ch := range line {
				if ch == ' ' || ch == '\t' {
					indent += string(ch)
				} else {
					break
				}
			}

			// Write new path line
			lines[i] = fmt.Sprintf("%spath = %s", indent, wallpaperPath)
			modified = true
			break
		}
	}

	if !modified {
		return fmt.Errorf("could not find 'path' line inside 'background' block in hyprlock.conf")
	}

	// Write back to file
	newContent := strings.Join(lines, "\n")
	if err := os.WriteFile(configPath, []byte(newContent), 0644); err != nil {
		return fmt.Errorf("failed to write hyprlock.conf: %v", err)
	}

	return nil
}

// LaunchWaypaper launches waypaper GUI (kept for backwards compatibility)
func (a *App) LaunchWaypaper() error {
	cmd := exec.Command("waypaper")
	return cmd.Start()
}
