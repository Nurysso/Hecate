pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: manager
    // Font settings
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 13
    readonly property int iconSize: 15

    // Spacing
    readonly property int spacing: 8
    readonly property int spacingSmall: 4
    readonly property int padding: 12
    readonly property int barHeight: 44

    // Border radius
    readonly property int radius: 8
    readonly property int radiusSmall: 4
    readonly property int radiusLarge: 12

    // Nerd Font Icons (unicode characters)
    readonly property string iconLogo: "\uf313"          // nf-linux
    readonly property string iconCpu: "\uf2db"           // nf-md-chip
    readonly property string iconMemory: "\uefc5"        // nf-md-memory
    readonly property string iconDisk: "\uf0a0"          // nf-md-harddisk
    readonly property string iconVolume: "\uf028"        // nf-md-volume_high
    readonly property string iconVolumeMute: "\uf6a9"    // nf-md-volume_mute
    readonly property string iconClock: "\uf017"         // nf-fa-clock_o
    readonly property string iconCalendar: "\uf073"      // nf-fa-calendar
    readonly property string iconWindow: "\uf2d0"        // nf-md-window_maximize
    readonly property string iconLayout: "\uf4af"        // nf-oct-layout
    readonly property string iconTiled: "\uf009"         // nf-fa-th
    readonly property string iconFloating: "\uf2d2"      // nf-md-window_restore
    readonly property string iconFullscreen: "\uf31e"    // nf-md-fullscreen
    readonly property string iconWorkspace: "\uf24d"     // nf-oct-browser

    // Color properties with better defaults
    property string primaryColor: "#4B9EEA"
    property string accentColor: "#c8c4cb"
    property string mutedColor: "#716379"
    property string warningColor: "#E5A564"
    property string criticalColor: "#E55564"
    property string successColor: "#85E564"
    property string magentaColor: "#475DD4"
    property string cyanColor: "#4B9EEA"
    property string greenColor: "#85E564"

    // Background colors with guaranteed contrast
    property string bgColor: "#1a1b26"
    property string bgLightColor: "#24283b"
    property string bgDarkColor: "#16161e"
    property string fgColor: "#c0caf5"
    property string fgDimColor: "#9aa5ce"

    // Wallpaper-aware properties
    property string wallpaperPath: ""
    property real wallpaperLuminance: 0.5
    property bool isDarkWallpaper: true
    property bool useAdaptiveContrast: true

    property bool loaded: false
    property string cssPath: Quickshell.env("HOME") + "/.config/hecate/hecate.css"

    // Enhanced contrast ratios for better visibility
    readonly property real minContrastTextBg: 7.0      // Text on background
    readonly property real minContrastAccentBg: 5.5    // Accent colors on background
    readonly property real minContrastWidgetWallpaper: 6.0  // Widgets on wallpaper

    // Helper function to calculate relative luminance
    function getLuminance(hexColor) {
        const hex = hexColor.replace('#', '')
        const r = parseInt(hex.substr(0, 2), 16) / 255
        const g = parseInt(hex.substr(2, 2), 16) / 255
        const b = parseInt(hex.substr(4, 2), 16) / 255

        const rs = r <= 0.03928 ? r / 12.92 : Math.pow((r + 0.055) / 1.055, 2.4)
        const gs = g <= 0.03928 ? g / 12.92 : Math.pow((g + 0.055) / 1.055, 2.4)
        const bs = b <= 0.03928 ? b / 12.92 : Math.pow((b + 0.055) / 1.055, 2.4)

        return 0.2126 * rs + 0.7152 * gs + 0.0722 * bs
    }

    // Calculate contrast ratio between two colors
    function getContrastRatio(color1, color2) {
        const lum1 = getLuminance(color1)
        const lum2 = getLuminance(color2)
        const lighter = Math.max(lum1, lum2)
        const darker = Math.min(lum1, lum2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    // Enhance color saturation for better visibility
    function enhanceSaturation(hexColor, boostPercent = 30) {
        const hex = hexColor.replace('#', '')
        let r = parseInt(hex.substr(0, 2), 16)
        let g = parseInt(hex.substr(2, 2), 16)
        let b = parseInt(hex.substr(4, 2), 16)

        // Convert to HSL
        r /= 255; g /= 255; b /= 255
        const max = Math.max(r, g, b)
        const min = Math.min(r, g, b)
        let h, s, l = (max + min) / 2

        if (max === min) {
            h = s = 0
        } else {
            const d = max - min
            s = l > 0.5 ? d / (2 - max - min) : d / (max + min)
            switch (max) {
                case r: h = ((g - b) / d + (g < b ? 6 : 0)) / 6; break
                case g: h = ((b - r) / d + 2) / 6; break
                case b: h = ((r - g) / d + 4) / 6; break
            }
        }

        // Boost saturation
        s = Math.min(1, s * (1 + boostPercent / 100))

        // Convert back to RGB
        function hue2rgb(p, q, t) {
            if (t < 0) t += 1
            if (t > 1) t -= 1
            if (t < 1/6) return p + (q - p) * 6 * t
            if (t < 1/2) return q
            if (t < 2/3) return p + (q - p) * (2/3 - t) * 6
            return p
        }

        let r2, g2, b2
        if (s === 0) {
            r2 = g2 = b2 = l
        } else {
            const q = l < 0.5 ? l * (1 + s) : l + s - l * s
            const p = 2 * l - q
            r2 = hue2rgb(p, q, h + 1/3)
            g2 = hue2rgb(p, q, h)
            b2 = hue2rgb(p, q, h - 1/3)
        }

        return '#' +
            Math.round(r2 * 255).toString(16).padStart(2, '0') +
            Math.round(g2 * 255).toString(16).padStart(2, '0') +
            Math.round(b2 * 255).toString(16).padStart(2, '0')
    }

    // Advanced contrast ensuring with wallpaper awareness
    function ensureContrast(fgColor, bgColor, minRatio = 4.5, enhanceSat = true) {
        let workingColor = fgColor

        // First, enhance saturation for better visibility
        if (enhanceSat && useAdaptiveContrast) {
            workingColor = enhanceSaturation(workingColor, isDarkWallpaper ? 40 : 30)
        }

        let currentRatio = getContrastRatio(workingColor, bgColor)

        if (currentRatio >= minRatio) {
            return workingColor
        }

        const bgLum = getLuminance(bgColor)
        const shouldLighten = bgLum < 0.5

        // Parse the color
        const hex = workingColor.replace('#', '')
        let r = parseInt(hex.substr(0, 2), 16)
        let g = parseInt(hex.substr(2, 2), 16)
        let b = parseInt(hex.substr(4, 2), 16)

        // More aggressive adjustment for better visibility
        const step = shouldLighten ? 15 : -15
        let attempts = 0
        const maxAttempts = 30

        while (currentRatio < minRatio && attempts < maxAttempts) {
            if (shouldLighten) {
                r = Math.min(255, r + step)
                g = Math.min(255, g + step)
                b = Math.min(255, b + step)
            } else {
                r = Math.max(0, r + step)
                g = Math.max(0, g + step)
                b = Math.max(0, b + step)
            }

            const newColor = '#' +
                r.toString(16).padStart(2, '0') +
                g.toString(16).padStart(2, '0') +
                b.toString(16).padStart(2, '0')

            currentRatio = getContrastRatio(newColor, bgColor)

            if (currentRatio >= minRatio) {
                return newColor
            }

            attempts++
        }

        // Fallback with high contrast
        return shouldLighten ? '#ffffff' : '#000000'
    }

    // Add glow/outline effect color for maximum visibility
    function getGlowColor(baseColor) {
        const lum = getLuminance(baseColor)
        if (lum > 0.5) {
            return "#000000"  // Dark glow for light colors
        } else {
            return "#ffffff"  // Light glow for dark colors
        }
    }

    // Get widget background with adaptive opacity
    function getWidgetBackground(baseColor) {
        const lum = wallpaperLuminance
        // Adjust opacity based on wallpaper brightness
        let opacity = 0.85

        if (Math.abs(lum - getLuminance(baseColor)) < 0.2) {
            // Similar colors, increase opacity
            opacity = 0.95
        }

        const hex = baseColor.replace('#', '')
        const r = parseInt(hex.substr(0, 2), 16)
        const g = parseInt(hex.substr(2, 2), 16)
        const b = parseInt(hex.substr(4, 2), 16)

        return `rgba(${r}, ${g}, ${b}, ${opacity})`
    }

    // Darken a color by a percentage
    function darkenColor(hexColor, percent) {
        const hex = hexColor.replace('#', '')
        const r = Math.max(0, parseInt(hex.substr(0, 2), 16) * (1 - percent / 100))
        const g = Math.max(0, parseInt(hex.substr(2, 2), 16) * (1 - percent / 100))
        const b = Math.max(0, parseInt(hex.substr(4, 2), 16) * (1 - percent / 100))

        return '#' +
            Math.round(r).toString(16).padStart(2, '0') +
            Math.round(g).toString(16).padStart(2, '0') +
            Math.round(b).toString(16).padStart(2, '0')
    }

    // Lighten a color by a percentage
    function lightenColor(hexColor, percent) {
        const hex = hexColor.replace('#', '')
        const r = Math.min(255, parseInt(hex.substr(0, 2), 16) + (255 - parseInt(hex.substr(0, 2), 16)) * percent / 100)
        const g = Math.min(255, parseInt(hex.substr(2, 2), 16) + (255 - parseInt(hex.substr(2, 2), 16)) * percent / 100)
        const b = Math.min(255, parseInt(hex.substr(4, 2), 16) + (255 - parseInt(hex.substr(4, 2), 16)) * percent / 100)

        return '#' +
            Math.round(r).toString(16).padStart(2, '0') +
            Math.round(g).toString(16).padStart(2, '0') +
            Math.round(b).toString(16).padStart(2, '0')
    }

    Component.onCompleted: {
        // console.debug("ColorManager: Initializing with wallpaper-adaptive contrast...")
        detectWallpaper.running = true
        colorReader.running = true
    }

    // Detect current wallpaper and analyze luminance
    property Process detectWallpaper: Process {
        id: detectWallpaper
        command: ["sh", "-c", "swww query | grep 'image:' | awk '{print $NF}'"]
        running: false
        property string output: ""

        stdout: SplitParser {
            onRead: data => {
                detectWallpaper.output += data
            }
        }

        onRunningChanged: {
            if (!running && output) {
                const path = output.trim()
                if (path) {
                    wallpaperPath = path
                    analyzeWallpaper.running = true
                }
                output = ""
            }
        }
    }

    // Analyze wallpaper average luminance using ImageMagick
    property Process analyzeWallpaper: Process {
        id: analyzeWallpaper
        command: ["sh", "-c", `convert "${wallpaperPath}" -scale 1x1\! -format '%[fx:mean]' info:`]
        running: false
        property string output: ""

        stdout: SplitParser {
            onRead: data => {
                analyzeWallpaper.output += data
            }
        }

        onRunningChanged: {
            if (!running && output) {
                const lum = parseFloat(output.trim())
                if (!isNaN(lum)) {
                    wallpaperLuminance = lum
                    isDarkWallpaper = lum < 0.4
                    // console.debug("ColorManager: Wallpaper luminance:", lum.toFixed(2),
                    //            isDarkWallpaper ? "(dark)" : "(light)")

                    // Reload colors with new wallpaper context
                    colorReader.running = true
                }
                output = ""
            }
        }
    }

    // CSS reader process
    property Process colorReader: Process {
        id: colorReader
        command: ["cat", manager.cssPath]
        running: false
        property string cssContent: ""

        stdout: SplitParser {
            onRead: data => {
                colorReader.cssContent += data
            }
        }

        onRunningChanged: {
            if (!running && cssContent) {
                // console.debug("ColorManager: Parsing colors with wallpaper-adaptive contrast...")

                // Parse base colors
                const bgMatch = cssContent.match(/@define-color bg (#[0-9A-Fa-f]{6});/)
                const fgMatch = cssContent.match(/@define-color fg (#[0-9A-Fa-f]{6});/)
                const bgAltMatch = cssContent.match(/@define-color bg-alt (#[0-9A-Fa-f]{6});/)
                const bgDimMatch = cssContent.match(/@define-color bg-dim (#[0-9A-Fa-f]{6});/)
                const fgDimMatch = cssContent.match(/@define-color fg-dim (#[0-9A-Fa-f]{6});/)

                // Parse color palette
                const cyanMatch = cssContent.match(/@define-color cyan (#[0-9A-Fa-f]{6});/)
                const magentaMatch = cssContent.match(/@define-color magenta (#[0-9A-Fa-f]{6});/)
                const greenMatch = cssContent.match(/@define-color green (#[0-9A-Fa-f]{6});/)
                const redMatch = cssContent.match(/@define-color red (#[0-9A-Fa-f]{6});/)
                const yellowMatch = cssContent.match(/@define-color yellow (#[0-9A-Fa-f]{6});/)
                const blueMatch = cssContent.match(/@define-color blue (#[0-9A-Fa-f]{6});/)

                // Set background colors
                let baseBg = bgMatch ? bgMatch[1] : manager.bgColor
                manager.bgColor = baseBg

                if (bgDimMatch) {
                    manager.bgDarkColor = bgDimMatch[1]
                } else {
                    manager.bgDarkColor = darkenColor(baseBg, 25)
                }

                if (bgAltMatch) {
                    manager.bgLightColor = bgAltMatch[1]
                } else {
                    manager.bgLightColor = lightenColor(baseBg, 20)
                }

                // Set and ensure contrast for foreground colors with wallpaper awareness
                let baseFg = fgMatch ? fgMatch[1] : manager.fgColor
                manager.fgColor = ensureContrast(baseFg, baseBg, minContrastTextBg, true)

                if (fgDimMatch) {
                    manager.fgDimColor = ensureContrast(fgDimMatch[1], baseBg, minContrastAccentBg, true)
                } else {
                    manager.fgDimColor = ensureContrast(
                        isDarkWallpaper ? lightenColor(manager.fgColor, 15) : darkenColor(manager.fgColor, 20),
                        baseBg,
                        minContrastAccentBg,
                        true
                    )
                }

                // Set and ensure contrast for semantic colors with enhanced saturation
                if (cyanMatch) {
                    manager.cyanColor = ensureContrast(cyanMatch[1], baseBg, minContrastAccentBg, true)
                    manager.primaryColor = manager.cyanColor
                }

                if (magentaMatch) {
                    manager.magentaColor = ensureContrast(magentaMatch[1], baseBg, minContrastAccentBg, true)
                    manager.accentColor = manager.magentaColor
                }

                if (greenMatch) {
                    manager.greenColor = ensureContrast(greenMatch[1], baseBg, minContrastAccentBg, true)
                    manager.successColor = manager.greenColor
                }

                if (redMatch) {
                    manager.criticalColor = ensureContrast(redMatch[1], baseBg, minContrastAccentBg, true)
                }

                if (yellowMatch) {
                    manager.warningColor = ensureContrast(yellowMatch[1], baseBg, minContrastAccentBg, true)
                }

                if (blueMatch) {
                    const blueColor = ensureContrast(blueMatch[1], baseBg, minContrastAccentBg, true)
                    if (!cyanMatch) {
                        manager.primaryColor = blueColor
                    }
                }

                // Set muted color with better visibility
                manager.mutedColor = ensureContrast(
                    fgDimMatch ? fgDimMatch[1] :
                    isDarkWallpaper ? lightenColor(manager.fgColor, 25) : darkenColor(manager.fgColor, 35),
                    baseBg,
                    4.0,
                    false
                )

                manager.loaded = true
                cssContent = ""

                // console.debug("ColorManager: Colors loaded with enhanced contrast:")
                // console.debug("  - Wallpaper:", isDarkWallpaper ? "dark" : "light", `(${wallpaperLuminance.toFixed(2)})`)
                // console.debug("  - FG contrast:", getContrastRatio(manager.fgColor, manager.bgColor).toFixed(2))
                // console.debug("  - Primary contrast:", getContrastRatio(manager.primaryColor, manager.bgColor).toFixed(2))
                // console.debug("  - Accent contrast:", getContrastRatio(manager.accentColor, manager.bgColor).toFixed(2))
            }
        }
    }

    // Reload timer - also checks wallpaper changes
    property Timer reloadTimer: Timer {
        interval: 10000  // Check every 10 seconds
        running: true
        repeat: true
        triggeredOnStart: false
        onTriggered: {
            detectWallpaper.running = true
            colorReader.running = true
        }
    }

    // Manual reload function
    function reload() {
        console.debug("ColorManager: Manual reload triggered")
        detectWallpaper.running = true
        colorReader.running = true
    }
}
