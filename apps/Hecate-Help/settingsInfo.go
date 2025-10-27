package main

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	// "runtime"
	"strings"
	"regexp"
)

type SystemInfo struct {
	ctx context.Context
}

type SystemInfoData struct {
	HyprlandVersion string `json:"hyprlandVersion"`
	Kernel          string `json:"kernel"`
	OS              string `json:"os"`
	Hostname        string `json:"hostname"`
	CPU             string `json:"cpu"`
	Memory          string `json:"memory"`
	GPU             string `json:"gpu"`
	GPUDriver       string `json:"gpuDriver"`
	Uptime          string `json:"uptime"`
	// Architecture    string `json:"architecture"`
	Shell           string `json:"shell"`
	// Resolution      string `json:"resolution"`
}

func NewSystemInfo() *SystemInfo {
	return &SystemInfo{}
}

func (s *SystemInfo) GetSystemInfo() SystemInfoData {
	return SystemInfoData{
		HyprlandVersion: s.getHyprlandVersion(),
		Kernel:          s.getKernel(),
		OS:              s.getOS(),
		Hostname:        s.getHostname(),
		CPU:             s.getCPU(),
		Memory:          s.getMemory(),
		GPU:             s.getGPU(),
		GPUDriver:       s.getGPUDriver(),
		Uptime:          s.getUptime(),
		// Architecture:    runtime.GOARCH,
		Shell:           s.getShell(),
		// Resolution:      s.getResolution(),
	}
}
func (a *App) GetSystemInfo() SystemInfoData {
    sysInfo := NewSystemInfo()
    return sysInfo.GetSystemInfo()
}
func (s *SystemInfo) getHyprlandVersion() string {
	out, err := exec.Command("hyprctl", "version").Output()
	if err != nil {
		return "Not installed"
	}
	lines := strings.Split(string(out), "\n")
	for _, line := range lines {
		if strings.Contains(line, "Tag:") {
			parts := strings.Split(line, ":")
			if len(parts) > 1 {
				return strings.TrimSpace(parts[1])
			}
		}
	}
	return "Unknown"
}

func (s *SystemInfo) getKernel() string {
	out, err := exec.Command("uname", "-r").Output()
	if err != nil {
		return "Unknown"
	}
	return strings.TrimSpace(string(out))
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

func (s *SystemInfo) getGPU() string {
	out, err := exec.Command("lspci").Output()
	if err != nil {
		return "Unknown"
	}

	lines := strings.Split(string(out), "\n")
	for _, line := range lines {
		lower := strings.ToLower(line)
		if strings.Contains(lower, "vga") || strings.Contains(lower, "3d controller") {
			// Remove vendor info like "Advanced Micro Devices, Inc. [AMD/ATI]"
			reVendor := regexp.MustCompile(`^[^\]]+\]\s*`)
			lineClean := reVendor.ReplaceAllString(line, "")

			// Remove revision info like "(rev c1)"
			reRev := regexp.MustCompile(`\s*\(rev.*\)$`)
			lineClean = reRev.ReplaceAllString(lineClean, "")

			// Remove bracketed codename inside, e.g., "[Radeon RX 6700 XT]" -> "Radeon RX 6700 XT"
			reBrackets := regexp.MustCompile(`\[([^\]]+)\]`)
			match := reBrackets.FindStringSubmatch(lineClean)
			if len(match) > 1 {
				return strings.TrimSpace(match[1])
			}

			// Fallback: return everything after first colon
			parts := strings.SplitN(lineClean, ":", 3)
			if len(parts) == 3 {
				return strings.TrimSpace(parts[2])
			}

			return strings.TrimSpace(lineClean)
		}
	}
	return "Unknown"
}

func (s *SystemInfo) getGPUDriver() string {
	// Check for NVIDIA
	if _, err := exec.Command("nvidia-smi", "--version").Output(); err == nil {
		out, err := exec.Command("nvidia-smi", "--query-gpu=driver_version", "--format=csv,noheader").Output()
		if err == nil {
			return "NVIDIA " + strings.TrimSpace(string(out))
		}
	}

	// Check for AMD
	out, err := exec.Command("modinfo", "amdgpu").Output()
	if err == nil {
		lines := strings.Split(string(out), "\n")
		for _, line := range lines {
			if strings.HasPrefix(line, "version:") {
				parts := strings.Split(line, ":")
				if len(parts) > 1 {
					return "AMDGPU " + strings.TrimSpace(parts[1])
				}
			}
		}
		return "AMDGPU"
	}

	// Check for Intel
	if _, err := exec.Command("modinfo", "i915").Output(); err == nil {
		return "Intel i915"
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

func (s *SystemInfo) getShell() string {
	shell := os.Getenv("SHELL")
	if shell == "" {
		return "Unknown"
	}
	parts := strings.Split(shell, "/")
	return parts[len(parts)-1]
}

// func (s *SystemInfo) getResolution() string {
// 	// Try hyprctl for Hyprland
// 	out, err := exec.Command("hyprctl", "monitors", "-j").Output()
// 	if err == nil && len(out) > 0 {
// 		// Parse JSON to get resolution
// 		outStr := string(out)
// 		if strings.Contains(outStr, "\"width\"") {
// 			// Simple extraction (for production, use proper JSON parsing)
// 			return "Check hyprctl monitors"
// 		}
// 	}

// 	// Fallback to xrandr
// 	out, err = exec.Command("xrandr", "--current").Output()
// 	if err == nil {
// 		lines := strings.Split(string(out), "\n")
// 		for _, line := range lines {
// 			if strings.Contains(line, "*") {
// 				fields := strings.Fields(line)
// 				if len(fields) > 0 {
// 					return fields[0]
// 				}
// 			}
// 		}
// 	}

// 	return "Unknown"
// }
