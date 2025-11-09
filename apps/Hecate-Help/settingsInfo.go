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
	OS              string `json:"os"`
	Hostname        string `json:"hostname"`
	CPU             string `json:"cpu"`
	Memory          string `json:"memory"`
	Uptime          string `json:"uptime"`
    WallpaperBase64 string `json:"wallpaperBase64"`

}

func NewSystemInfo() *SystemInfo {
	return &SystemInfo{}
}

func (s *SystemInfo) GetSystemInfo() SystemInfoData {
	return SystemInfoData{
		OS:              s.getOS(),
		Hostname:        s.getHostname(),
		CPU:             s.getCPU(),
		Memory:          s.getMemory(),
		Uptime:          s.getUptime(),
        WallpaperBase64: s.getWallpaper(),
	}
}
func (a *App) GetSystemInfo() SystemInfoData {
    sysInfo := NewSystemInfo()
    return sysInfo.GetSystemInfo()
}

func (s *SystemInfo) getOS() string {
	// Try /etc/os-release first
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

	// Fallback
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

func (s *SystemInfo) getUptime() string {
	out, err := exec.Command("uptime", "-p").Output()
	if err != nil {
		return "Unknown"
	}
	uptime := strings.TrimSpace(string(out))
	return strings.TrimPrefix(uptime, "up ")
}

// getWallpaper gets wallpaper based on waypaper
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
        // Handle both "wallpaper=path" and "wallpaper = path" formats
        if strings.HasPrefix(line, "wallpaper") {
            parts := strings.SplitN(line, "=", 2)
            if len(parts) == 2 {
                wallpaperPath = strings.TrimSpace(parts[1])
                // Expand ~ to home directory
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

    return compressImage(wallpaperPath)
}


// Compress image to base64
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

    // FIX: Use base64 encoding
    encoded := base64.StdEncoding.EncodeToString(buf.Bytes())
    return fmt.Sprintf("data:image/jpeg;base64,%s", encoded)
}

// Add to App struct methods
func (a *App) LaunchWaypaper() error {
    cmd := exec.Command("waypaper")
    return cmd.Start()
}
