pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: manager

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

    property bool loaded: false
    property string cssPath: Quickshell.env("HOME") + "/.config/hecate/hecate.css"

    // Helper function to calculate relative luminance
    function getLuminance(hexColor) {
        // Remove # if present
        const hex = hexColor.replace('#', '')
        const r = parseInt(hex.substr(0, 2), 16) / 255
        const g = parseInt(hex.substr(2, 2), 16) / 255
        const b = parseInt(hex.substr(4, 2), 16) / 255

        // Apply gamma correction
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

    // Lighten or darken a color to ensure minimum contrast
    function ensureContrast(fgColor, bgColor, minRatio = 4.5) {
        let currentRatio = getContrastRatio(fgColor, bgColor)

        if (currentRatio >= minRatio) {
            return fgColor
        }

        const bgLum = getLuminance(bgColor)
        const isDarkBg = bgLum < 0.5

        // Parse the foreground color
        const hex = fgColor.replace('#', '')
        let r = parseInt(hex.substr(0, 2), 16)
        let g = parseInt(hex.substr(2, 2), 16)
        let b = parseInt(hex.substr(4, 2), 16)

        // Adjust brightness
        const step = isDarkBg ? 10 : -10
        let attempts = 0
        const maxAttempts = 25

        while (currentRatio < minRatio && attempts < maxAttempts) {
            if (isDarkBg) {
                // Lighten for dark backgrounds
                r = Math.min(255, r + step)
                g = Math.min(255, g + step)
                b = Math.min(255, b + step)
            } else {
                // Darken for light backgrounds
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

        // If we couldn't achieve the target, return white or black based on background
        return isDarkBg ? '#ffffff' : '#000000'
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
        console.log("ColorManager: Initializing with contrast improvements...")
        colorReader.running = true
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
                console.log("ColorManager: Parsing colors with contrast adjustments...")

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
                    manager.bgDarkColor = darkenColor(baseBg, 20)
                }

                if (bgAltMatch) {
                    manager.bgLightColor = bgAltMatch[1]
                } else {
                    manager.bgLightColor = lightenColor(baseBg, 15)
                }

                // Set and ensure contrast for foreground colors
                let baseFg = fgMatch ? fgMatch[1] : manager.fgColor
                manager.fgColor = ensureContrast(baseFg, baseBg, 7.0)  // WCAG AAA standard

                if (fgDimMatch) {
                    manager.fgDimColor = ensureContrast(fgDimMatch[1], baseBg, 4.5)  // WCAG AA standard
                } else {
                    manager.fgDimColor = ensureContrast(darkenColor(manager.fgColor, 25), baseBg, 4.5)
                }

                // Set and ensure contrast for semantic colors
                if (cyanMatch) {
                    manager.cyanColor = ensureContrast(cyanMatch[1], baseBg, 4.5)
                    manager.primaryColor = manager.cyanColor
                }

                if (magentaMatch) {
                    manager.magentaColor = ensureContrast(magentaMatch[1], baseBg, 4.5)
                    manager.accentColor = manager.magentaColor
                }

                if (greenMatch) {
                    manager.greenColor = ensureContrast(greenMatch[1], baseBg, 4.5)
                    manager.successColor = manager.greenColor
                }

                if (redMatch) {
                    manager.criticalColor = ensureContrast(redMatch[1], baseBg, 4.5)
                }

                if (yellowMatch) {
                    manager.warningColor = ensureContrast(yellowMatch[1], baseBg, 4.5)
                }

                if (blueMatch) {
                    const blueColor = ensureContrast(blueMatch[1], baseBg, 4.5)
                    // If cyan wasn't found, use blue as primary
                    if (!cyanMatch) {
                        manager.primaryColor = blueColor
                    }
                }

                // Set muted color
                manager.mutedColor = ensureContrast(
                    fgDimMatch ? fgDimMatch[1] : darkenColor(manager.fgColor, 40),
                    baseBg,
                    3.0  // Lower contrast for muted elements
                )

                manager.loaded = true
                cssContent = ""
                console.log("ColorManager: Colors loaded with contrast ratios:")
                console.log("  - FG contrast:", getContrastRatio(manager.fgColor, manager.bgColor).toFixed(2))
                console.log("  - Primary contrast:", getContrastRatio(manager.primaryColor, manager.bgColor).toFixed(2))
                console.log("  - Accent contrast:", getContrastRatio(manager.accentColor, manager.bgColor).toFixed(2))
            }
        }
    }

    // Reload timer
    property Timer reloadTimer: Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: false
        onTriggered: {
            colorReader.running = true
        }
    }

    // Manual reload function
    function reload() {
        console.log("ColorManager: Manual reload triggered")
        colorReader.running = true
    }
}
