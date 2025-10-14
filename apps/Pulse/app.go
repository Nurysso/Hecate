
package main

import (
	"fmt"
	"os/exec"
	"strconv"
	"strings"
	"context"
	"bufio"
	"os"
	"path/filepath"
	"regexp"
	"io/ioutil"
	"time"
    "github.com/wailsapp/wails/v2/pkg/runtime"
)

type GTKColors struct {
	AccentColor      string `json:"accentColor"`
	AccentFgColor    string `json:"accentFgColor"`
	AccentBgColor    string `json:"accentBgColor"`
	WindowBgColor    string `json:"windowBgColor"`
	WindowFgColor    string `json:"windowFgColor"`
	HeaderbarBgColor string `json:"headerbarBgColor"`
	HeaderbarFgColor string `json:"headerbarFgColor"`
	PopoverBgColor   string `json:"popoverBgColor"`
	PopoverFgColor   string `json:"popoverFgColor"`
	ViewBgColor      string `json:"viewBgColor"`
	ViewFgColor      string `json:"viewFgColor"`
	CardBgColor      string `json:"cardBgColor"`
	CardFgColor      string `json:"cardFgColor"`
	SidebarBgColor   string `json:"sidebarBgColor"`
	SidebarFgColor   string `json:"sidebarFgColor"`
}
// App struct
type App struct {
    ctx context.Context
}

// NewApp creates a new App application struct
func NewApp() *App {
    return &App{}
}
// Enhanced SystemStats with more details
type EnhancedSystemStats struct {
	CPU         CPUStats       `json:"cpu"`
	RAM         MemoryStats    `json:"ram"`
	Swap        MemoryStats    `json:"swap"`
	GPU         GPUStats       `json:"gpu"`
	Temp        TempStats      `json:"temp"`
	Disks       []DiskStats    `json:"disks"`
	Network     NetworkStats   `json:"network"`
	Uptime      string         `json:"uptime"`
	ProcessCount int           `json:"processCount"`
}

type SystemStats struct {
    CPU     float64      `json:"cpu"`
    RAM     float64      `json:"ram"`
    Swap    float64      `json:"swap"`
    Storage float64      `json:"storage"`
    Temp    float64      `json:"temp"`
    GPU     float64      `json:"gpu"`
    Network NetworkStats `json:"network"`
}

type NetworkStats struct {
    Down     string  `json:"down"`
    Up       string  `json:"up"`
    Activity float64 `json:"activity"`
}
type CPUStats struct {
	Usage   float64 `json:"usage"`
	Cores   int     `json:"cores"`
	Model   string  `json:"model"`
}

type MemoryStats struct {
	Used    float64 `json:"used"`
	Total   float64 `json:"total"`
	Percent float64 `json:"percent"`
	Unit    string  `json:"unit"`
}

type GPUStats struct {
	Usage   float64 `json:"usage"`
	Memory  float64 `json:"memory"`
	Temp    float64 `json:"temp"`
	Name    string  `json:"name"`
}

type TempStats struct {
	CPU  float64 `json:"cpu"`
	Max  float64 `json:"max"`
	Unit string  `json:"unit"`
}

type DiskStats struct {
	Device     string  `json:"device"`
	MountPoint string  `json:"mountPoint"`
	Used       float64 `json:"used"`
	Total      float64 `json:"total"`
	Percent    float64 `json:"percent"`
	FileSystem string  `json:"fileSystem"`
}

// startup is called when the app starts. The context is saved
// so we can call the runtime methods
func (a *App) startup(ctx context.Context) {
    a.ctx = ctx

    // Position window at top left after startup
    runtime.WindowSetPosition(ctx, 20, 20)
}



func getCPU() float64 {
    cmd := exec.Command("sh", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'")
    out, _ := cmd.Output()
    val, _ := strconv.ParseFloat(strings.TrimSpace(string(out)), 64)
    return val
}
func getCPUStats() CPUStats {
	usage := getCPU()

	// Get CPU cores
	cmd := exec.Command("sh", "-c", "nproc")
	out, _ := cmd.Output()
	cores, _ := strconv.Atoi(strings.TrimSpace(string(out)))

	// Get CPU model
	cmd = exec.Command("sh", "-c", "lscpu | grep 'Model name' | cut -d':' -f2 | xargs")
	out, _ = cmd.Output()
	model := strings.TrimSpace(string(out))

	return CPUStats{
		Usage: usage,
		Cores: cores,
		Model: model,
	}
}

func getRAMStats() MemoryStats {
	cmd := exec.Command("sh", "-c", "free -m | awk 'NR==2{print $3,$2}'")
	out, _ := cmd.Output()
	parts := strings.Fields(string(out))

	used, _ := strconv.ParseFloat(parts[0], 64)
	total, _ := strconv.ParseFloat(parts[1], 64)
	percent := (used / total) * 100

	return MemoryStats{
		Used:    used,
		Total:   total,
		Percent: percent,
		Unit:    "MB",
	}
}

func getSwapStats() MemoryStats {
	cmd := exec.Command("sh", "-c", "free -m | awk 'NR==3{print $3,$2}'")
	out, _ := cmd.Output()
	parts := strings.Fields(string(out))

	if len(parts) < 2 {
		return MemoryStats{Used: 0, Total: 0, Percent: 0, Unit: "MB"}
	}

	used, _ := strconv.ParseFloat(parts[0], 64)
	total, _ := strconv.ParseFloat(parts[1], 64)
	percent := 0.0
	if total > 0 {
		percent = (used / total) * 100
	}

	return MemoryStats{
		Used:    used,
		Total:   total,
		Percent: percent,
		Unit:    "MB",
	}
}
func getGPUStats() GPUStats {
	stats := GPUStats{Usage: 0, Memory: 0, Temp: 0, Name: "No GPU Detected"}

	// Method 1: Try NVIDIA
	cmd := exec.Command("nvidia-smi", "--query-gpu=utilization.gpu,memory.used,temperature.gpu,name", "--format=csv,noheader,nounits")
	out, err := cmd.Output()
	if err == nil && len(out) > 0 {
		lines := strings.Split(strings.TrimSpace(string(out)), "\n")
		if len(lines) > 0 {
			parts := strings.Split(lines[0], ",")
			if len(parts) >= 4 {
				stats.Usage, _ = strconv.ParseFloat(strings.TrimSpace(parts[0]), 64)
				stats.Memory, _ = strconv.ParseFloat(strings.TrimSpace(parts[1]), 64)
				stats.Temp, _ = strconv.ParseFloat(strings.TrimSpace(parts[2]), 64)
				stats.Name = strings.TrimSpace(parts[3])
				return stats
			}
		}
	}

	// Method 2: Try AMD via sysfs
	amdPaths := []string{
		"/sys/class/drm/card0/device/gpu_busy_percent",
		"/sys/class/drm/card1/device/gpu_busy_percent",
	}

	for _, path := range amdPaths {
		data, err := ioutil.ReadFile(path)
		if err == nil {
			usage, err := strconv.ParseFloat(strings.TrimSpace(string(data)), 64)
			if err == nil {
				stats.Usage = usage
				stats.Name = "AMD GPU"

				// Try to get AMD temp
				tempPath := strings.Replace(path, "gpu_busy_percent", "hwmon/hwmon*/temp1_input", 1)
				cmd = exec.Command("sh", "-c", fmt.Sprintf("cat %s 2>/dev/null", tempPath))
				out, err = cmd.Output()
				if err == nil && len(out) > 0 {
					temp, _ := strconv.ParseFloat(strings.TrimSpace(string(out)), 64)
					stats.Temp = temp / 1000.0 // Convert from millidegrees
				}

				return stats
			}
		}
	}

	// Method 3: Try Intel integrated graphics
	intelPath := "/sys/class/drm/card0/gt_cur_freq_mhz"
	if _, err := os.Stat(intelPath); err == nil {
		stats.Name = "Intel Integrated GPU"
		// Intel GPU usage is harder to get, might need radeontop or intel_gpu_top
	}

	return stats
}
func getTempStats() TempStats {
	cpu := 0.0
	max := 85.0

	// Method 1: Try sensors command
	cmd := exec.Command("sh", "-c", "sensors 2>/dev/null")
	out, err := cmd.Output()
	if err == nil && len(out) > 0 {
		output := string(out)

		// Try different temperature patterns
		patterns := []string{
			`Package id 0:\s+\+(\d+\.\d+)°C`,
			`Tctl:\s+\+(\d+\.\d+)°C`,
			`Core 0:\s+\+(\d+\.\d+)°C`,
			`CPU:\s+\+(\d+\.\d+)°C`,
			`temp1:\s+\+(\d+\.\d+)°C`,
		}

		for _, pattern := range patterns {
			re := regexp.MustCompile(pattern)
			matches := re.FindStringSubmatch(output)
			if len(matches) > 1 {
				cpu, _ = strconv.ParseFloat(matches[1], 64)
				break
			}
		}
	}

	// Method 2: Try reading from /sys/class/thermal
	if cpu == 0.0 {
		// Try thermal zones
		for i := 0; i < 10; i++ {
			tempPath := fmt.Sprintf("/sys/class/thermal/thermal_zone%d/temp", i)
			data, err := ioutil.ReadFile(tempPath)
			if err == nil {
				temp, err := strconv.ParseFloat(strings.TrimSpace(string(data)), 64)
				if err == nil && temp > 1000 {
					// Temperature is in millidegrees
					cpu = temp / 1000.0
					break
				}
			}
		}
	}

	// Method 3: Try hwmon
	if cpu == 0.0 {
		cmd = exec.Command("sh", "-c", "find /sys/class/hwmon -name 'temp*_input' -exec cat {} \\; 2>/dev/null | head -1")
		out, err = cmd.Output()
		if err == nil && len(out) > 0 {
			temp, err := strconv.ParseFloat(strings.TrimSpace(string(out)), 64)
			if err == nil && temp > 1000 {
				cpu = temp / 1000.0
			}
		}
	}

	return TempStats{
		CPU:  cpu,
		Max:  max,
		Unit: "°C",
	}
}
func getDiskStats() []DiskStats {
	var disks []DiskStats

	// Get all mounted filesystems
	cmd := exec.Command("sh", "-c", "df -h -x tmpfs -x devtmpfs -x squashfs | tail -n +2")
	out, _ := cmd.Output()

	lines := strings.Split(string(out), "\n")
	for _, line := range lines {
		if line == "" {
			continue
		}

		fields := strings.Fields(line)
		if len(fields) < 6 {
			continue
		}

		// Parse used and total (convert from human readable)
		usedStr := fields[2]
		totalStr := fields[1]
		percentStr := strings.TrimSuffix(fields[4], "%")

		percent, _ := strconv.ParseFloat(percentStr, 64)

		disks = append(disks, DiskStats{
			Device:     fields[0],
			MountPoint: fields[5],
			Used:       parseSize(usedStr),
			Total:      parseSize(totalStr),
			Percent:    percent,
			FileSystem: getFileSystem(fields[0]),
		})
	}

	return disks
}
func parseSize(sizeStr string) float64 {
	sizeStr = strings.TrimSpace(sizeStr)
	if len(sizeStr) < 2 {
		return 0
	}

	unit := sizeStr[len(sizeStr)-1:]
	numStr := sizeStr[:len(sizeStr)-1]
	num, _ := strconv.ParseFloat(numStr, 64)

	switch unit {
	case "K":
		return num / 1024 / 1024 // Convert to GB
	case "M":
		return num / 1024 // Convert to GB
	case "G":
		return num
	case "T":
		return num * 1024
	default:
		return num
	}
}

func getFileSystem(device string) string {
	cmd := exec.Command("sh", "-c", fmt.Sprintf("lsblk -no FSTYPE %s 2>/dev/null", device))
	out, _ := cmd.Output()
	fs := strings.TrimSpace(string(out))
	if fs == "" {
		return "Unknown"
	}
	return fs
}

func getUptime() string {
	cmd := exec.Command("sh", "-c", "uptime -p | sed 's/up //'")
	out, _ := cmd.Output()
	return strings.TrimSpace(string(out))
}

func getProcessCount() int {
	cmd := exec.Command("sh", "-c", "ps aux | wc -l")
	out, _ := cmd.Output()
	count, _ := strconv.Atoi(strings.TrimSpace(string(out)))
	return count - 1 // Subtract header line
}
func getStorage() float64 {
    cmd := exec.Command("sh", "-c", "df -h / | awk 'NR==2{print int($5)}'")
    out, _ := cmd.Output()
    val, _ := strconv.ParseFloat(strings.TrimSpace(string(out)), 64)
    return val
}

func getTemp() float64 {
    cmd := exec.Command("sh", "-c", "sensors 2>/dev/null | grep 'Package id 0:' | awk '{print int($4)}' || sensors 2>/dev/null | grep 'Tctl:' | awk '{print int($2)}' || echo '0'")
    out, _ := cmd.Output()
    val, _ := strconv.ParseFloat(strings.TrimSpace(string(out)), 64)
    return val
}

func getGPU() float64 {
    // Try nvidia-smi first
    cmd := exec.Command("sh", "-c", "nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1")
    out, err := cmd.Output()
    if err == nil && len(out) > 0 {
        val, _ := strconv.ParseFloat(strings.TrimSpace(string(out)), 64)
        return val
    }
    // Fallback for AMD
    cmd = exec.Command("sh", "-c", "cat /sys/class/drm/card0/device/gpu_busy_percent 2>/dev/null")
    out, _ = cmd.Output()
    val, _ := strconv.ParseFloat(strings.TrimSpace(string(out)), 64)
    return val
}

// Network stats cache to avoid timing issues
var networkCache = struct {
	Down     string
	Up       string
	Activity float64
	LastUpdate time.Time
}{
	Down:     "0 B/s",
	Up:       "0 B/s",
	Activity: 0,
	LastUpdate: time.Time{},
}
func getNetwork() NetworkStats {
	// Return cached values if updated recently (within 500ms)
	if time.Since(networkCache.LastUpdate) < 500*time.Millisecond {
		return NetworkStats{
			Down:     networkCache.Down,
			Up:       networkCache.Up,
			Activity: networkCache.Activity,
		}
	}

	stats := NetworkStats{
		Down:     "0 B/s",
		Up:       "0 B/s",
		Activity: 0,
	}

	// Method 1: Try custom script
	homeDir, _ := os.UserHomeDir()
	scriptPath := filepath.Join(homeDir, ".config", "hecate", "scripts", "network.sh")

	if _, err := os.Stat(scriptPath); err == nil {
		// Run both commands concurrently to save time
		downChan := make(chan string, 1)
		upChan := make(chan string, 1)

		go func() {
			cmd := exec.Command("bash", scriptPath, "down")
			down, err := cmd.Output()
			if err == nil {
				downChan <- strings.TrimSpace(string(down))
			} else {
				downChan <- "0 B/s"
			}
		}()

		go func() {
			cmd := exec.Command("bash", scriptPath, "up")
			up, err := cmd.Output()
			if err == nil {
				upChan <- strings.TrimSpace(string(up))
			} else {
				upChan <- "0 B/s"
			}
		}()

		// Wait for both with timeout
		timeout := time.After(2 * time.Second)
		downReceived := false
		upReceived := false

		for !downReceived || !upReceived {
			select {
			case stats.Down = <-downChan:
				downReceived = true
			case stats.Up = <-upChan:
				upReceived = true
			case <-timeout:
				if !downReceived {
					stats.Down = "0 B/s"
				}
				if !upReceived {
					stats.Up = "0 B/s"
				}
				downReceived = true
				upReceived = true
			}
		}

		// Calculate activity based on the speeds
		stats.Activity = calculateActivityFromStrings(stats.Down, stats.Up)

		// Update cache
		networkCache.Down = stats.Down
		networkCache.Up = stats.Up
		networkCache.Activity = stats.Activity
		networkCache.LastUpdate = time.Now()

		return stats
	}

	// Method 2: Calculate network speed manually using same logic as script
	cmd := exec.Command("sh", "-c", "ip route | grep '^default' | awk '{print $5}' | head -n1")
	out, err := cmd.Output()
	if err != nil {
		return stats
	}

	iface := strings.TrimSpace(string(out))
	if iface == "" {
		return stats
	}

	rxPath := fmt.Sprintf("/sys/class/net/%s/statistics/rx_bytes", iface)
	txPath := fmt.Sprintf("/sys/class/net/%s/statistics/tx_bytes", iface)

	// Check if interface exists
	if _, err := os.Stat(rxPath); err != nil {
		return stats
	}

	// Get cached file location
	cacheDir := "/tmp/go_network"
	cacheFile := filepath.Join(cacheDir, "network_stats")
	os.MkdirAll(cacheDir, 0755)

	// Read current bytes
	rx, _ := readNetworkBytes(rxPath)
	tx, _ := readNetworkBytes(txPath)
	currentTime := time.Now().Unix()

	// Read previous values
	var prevRx, prevTx, prevTime uint64
	if data, err := ioutil.ReadFile(cacheFile); err == nil {
		fmt.Sscanf(string(data), "%d %d %d", &prevRx, &prevTx, &prevTime)
	}

	// Calculate speeds
	if prevTime > 0 {
		timeDiff := currentTime - int64(prevTime)
		if timeDiff > 0 {
			rxSpeed := float64(rx-prevRx) / float64(timeDiff)
			txSpeed := float64(tx-prevTx) / float64(timeDiff)

			// Handle negative values (interface reset)
			if rxSpeed < 0 {
				rxSpeed = 0
			}
			if txSpeed < 0 {
				txSpeed = 0
			}

			stats.Down = formatNetworkSpeed(rxSpeed / 1024.0) // Convert to KB/s
			stats.Up = formatNetworkSpeed(txSpeed / 1024.0)
			stats.Activity = calculateActivity(rxSpeed/1024.0, txSpeed/1024.0)
		}
	}

	// Save current values
	cacheData := fmt.Sprintf("%d %d %d", rx, tx, currentTime)
	ioutil.WriteFile(cacheFile, []byte(cacheData), 0644)

	// Update cache
	networkCache.Down = stats.Down
	networkCache.Up = stats.Up
	networkCache.Activity = stats.Activity
	networkCache.LastUpdate = time.Now()

	return stats
}

// Calculate activity from formatted strings like "1.5MB/s"
func calculateActivityFromStrings(down, up string) float64 {
	downKB := parseNetworkSpeed(down)
	upKB := parseNetworkSpeed(up)
	return calculateActivity(downKB, upKB)
}

// Parse network speed string to KB/s
func parseNetworkSpeed(speedStr string) float64 {
	speedStr = strings.TrimSpace(speedStr)

	// Extract number and unit
	re := regexp.MustCompile(`([\d.]+)\s*([KMGT]?B)/s`)
	matches := re.FindStringSubmatch(speedStr)

	if len(matches) < 3 {
		return 0
	}

	value, _ := strconv.ParseFloat(matches[1], 64)
	unit := matches[2]

	switch unit {
	case "B":
		return value / 1024.0
	case "KB":
		return value
	case "MB":
		return value * 1024.0
	case "GB":
		return value * 1024.0 * 1024.0
	default:
		return value
	}
}

func readNetworkBytes(path string) (uint64, error) {
	data, err := ioutil.ReadFile(path)
	if err != nil {
		return 0, err
	}
	return strconv.ParseUint(strings.TrimSpace(string(data)), 10, 64)
}

func formatNetworkSpeed(kbps float64) string {
	if kbps < 1 {
		return fmt.Sprintf("%.0f B/s", kbps*1024)
	} else if kbps < 1024 {
		return fmt.Sprintf("%.1f KB/s", kbps)
	} else {
		return fmt.Sprintf("%.2f MB/s", kbps/1024)
	}
}

func calculateActivity(down, up float64) float64 {
	total := down + up
	if total < 10 {
		return 10.0
	} else if total < 100 {
		return 30.0
	} else if total < 1024 {
		return 60.0
	} else {
		return 90.0
	}
}



// GetGTKColors reads the GTK CSS file and extracts color definitions
func (a *App) GetGTKColors() GTKColors {
	colors := GTKColors{
		// Default fallback colors
		AccentColor:      "#85d2e8",
		AccentFgColor:    "#003641",
		AccentBgColor:    "#85d2e8",
		WindowBgColor:    "#0f1416",
		WindowFgColor:    "#dee3e6",
		HeaderbarBgColor: "#0f1416",
		HeaderbarFgColor: "#dee3e6",
		PopoverBgColor:   "#0f1416",
		PopoverFgColor:   "#dee3e6",
		ViewBgColor:      "#0f1416",
		ViewFgColor:      "#dee3e6",
		CardBgColor:      "#0f1416",
		CardFgColor:      "#dee3e6",
		SidebarBgColor:   "#0f1416",
		SidebarFgColor:   "#dee3e6",
	}

	// Get home directory
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return colors
	}

	// Path to GTK CSS file
	gtkPath := filepath.Join(homeDir, ".config", "gtk-3.0", "gtk.css")

	// Open the file
	file, err := os.Open(gtkPath)
	if err != nil {
		return colors
	}
	defer file.Close()

	// Regular expression to match @define-color lines
	colorRegex := regexp.MustCompile(`@define-color\s+([a-z_]+)\s+(#[0-9a-fA-F]{6}|@[a-z_]+);`)

	// Map to store raw values (including references)
	colorMap := make(map[string]string)

	// Read and parse the file
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		matches := colorRegex.FindStringSubmatch(line)
		if len(matches) == 3 {
			colorName := matches[1]
			colorValue := matches[2]
			colorMap[colorName] = colorValue
		}
	}

	// Helper function to resolve color references (recursive)
	var resolveColor func(string) string
	resolveColor = func(value string) string {
		if strings.HasPrefix(value, "@") {
			refName := strings.TrimPrefix(value, "@")
			if resolved, ok := colorMap[refName]; ok {
				return resolveColor(resolved)
			}
		}
		return value
	}

	// Populate the struct with resolved colors
	if val := resolveColor(colorMap["accent_color"]); val != "" {
		colors.AccentColor = val
	}
	if val := resolveColor(colorMap["accent_fg_color"]); val != "" {
		colors.AccentFgColor = val
	}
	if val := resolveColor(colorMap["accent_bg_color"]); val != "" {
		colors.AccentBgColor = val
	}
	if val := resolveColor(colorMap["window_bg_color"]); val != "" {
		colors.WindowBgColor = val
	}
	if val := resolveColor(colorMap["window_fg_color"]); val != "" {
		colors.WindowFgColor = val
	}
	if val := resolveColor(colorMap["headerbar_bg_color"]); val != "" {
		colors.HeaderbarBgColor = val
	}
	if val := resolveColor(colorMap["headerbar_fg_color"]); val != "" {
		colors.HeaderbarFgColor = val
	}
	if val := resolveColor(colorMap["popover_bg_color"]); val != "" {
		colors.PopoverBgColor = val
	}
	if val := resolveColor(colorMap["popover_fg_color"]); val != "" {
		colors.PopoverFgColor = val
	}
	if val := resolveColor(colorMap["view_bg_color"]); val != "" {
		colors.ViewBgColor = val
	}
	if val := resolveColor(colorMap["view_fg_color"]); val != "" {
		colors.ViewFgColor = val
	}
	if val := resolveColor(colorMap["card_bg_color"]); val != "" {
		colors.CardBgColor = val
	}
	if val := resolveColor(colorMap["card_fg_color"]); val != "" {
		colors.CardFgColor = val
	}
	if val := resolveColor(colorMap["sidebar_bg_color"]); val != "" {
		colors.SidebarBgColor = val
	}
	if val := resolveColor(colorMap["sidebar_fg_color"]); val != "" {
		colors.SidebarFgColor = val
	}

	return colors
}
// GetEnhancedSystemStats returns comprehensive system information
func (a *App) GetEnhancedSystemStats() EnhancedSystemStats {
	return EnhancedSystemStats{
		CPU:          getCPUStats(),
		RAM:          getRAMStats(),
		Swap:         getSwapStats(),
		GPU:          getGPUStats(),
		Temp:         getTempStats(),
		Disks:        getDiskStats(),
		Network:      getNetwork(),
		Uptime:       getUptime(),
		ProcessCount: getProcessCount(),
	}
}
// Add debug logging version
func (a *App) GetEnhancedSystemStatsDebug() map[string]interface{} {
	stats := a.GetEnhancedSystemStats()

	// Log to see what we're getting
	fmt.Printf("Temperature: %.2f°C\n", stats.Temp.CPU)
	fmt.Printf("GPU: %s - Usage: %.2f%%, Temp: %.2f°C\n", stats.GPU.Name, stats.GPU.Usage, stats.GPU.Temp)
	fmt.Printf("Network: Down=%s, Up=%s\n", stats.Network.Down, stats.Network.Up)

	return map[string]interface{}{
		"stats": stats,
		"debug": map[string]string{
			"temp_method": "check console output",
			"gpu_method":  "check console output",
			"net_method":  "check console output",
		},
	}
}
