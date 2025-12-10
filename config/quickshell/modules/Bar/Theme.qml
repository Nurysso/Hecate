import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: theme

    // Default colors (fallback if CSS not loaded)
    property color bg: "#0E1C31"
    property color bgDark: "#0E1C31"
    property color bgLight: "#6F89B0"
    property color fg: "#e5ebf3"
    property color fgDark: "#a0a4aa"
    property color fgDim: "#a0a4aa"
    property color muted: "#a0a4aa"

    // Semantic colors
    property color cyan: "#CBDAF2"
    property color purple: "#B2C8EA"
    property color red: "#6F89B0"
    property color yellow: "#909EB4"
    property color blue: "#88ABDE"
    property color green: "#618ED3"
    property color orange: "#909EB4"
    property color magenta: "#B2C8EA"

    // Accent color for active states
    property color accent: cyan
    property color accentDim: Qt.rgba(cyan.r, cyan.g, cyan.b, 0.2)

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

    property bool loaded: false
    property string cssPath: Quickshell.env("HOME") + "/.config/hecate/hecate.css"

    // Helper function to parse hex color
    function parseColor(hex) {
        if (!hex || hex.length !== 7 || hex[0] !== '#') {
            return null
        }
        return hex
    }

    Component.onCompleted: {
        console.log("Theme: Loading colors from", cssPath)
        colorReader.running = true
    }

    // CSS reader process
    property Process colorReader: Process {
        id: colorReader
        command: ["cat", theme.cssPath]
        running: false
        property string cssContent: ""

        stdout: SplitParser {
            onRead: data => {
                colorReader.cssContent += data
            }
        }

        onRunningChanged: {
            if (!running && cssContent) {
                console.log("Theme: Parsing colors from CSS...")

                // Parse background colors
                const bgMatch = cssContent.match(/@define-color bg (#[0-9A-Fa-f]{6});/)
                const bgDimMatch = cssContent.match(/@define-color bg-dim (#[0-9A-Fa-f]{6});/)
                const bgAltMatch = cssContent.match(/@define-color bg-alt (#[0-9A-Fa-f]{6});/)

                // Parse foreground colors
                const fgMatch = cssContent.match(/@define-color fg (#[0-9A-Fa-f]{6});/)
                const fgDimMatch = cssContent.match(/@define-color fg-dim (#[0-9A-Fa-f]{6});/)
                const mutedMatch = cssContent.match(/@define-color muted (#[0-9A-Fa-f]{6});/)

                // Parse semantic colors
                const cyanMatch = cssContent.match(/@define-color cyan (#[0-9A-Fa-f]{6});/)
                const magentaMatch = cssContent.match(/@define-color magenta (#[0-9A-Fa-f]{6});/)
                const redMatch = cssContent.match(/@define-color red (#[0-9A-Fa-f]{6});/)
                const greenMatch = cssContent.match(/@define-color green (#[0-9A-Fa-f]{6});/)
                const yellowMatch = cssContent.match(/@define-color yellow (#[0-9A-Fa-f]{6});/)
                const blueMatch = cssContent.match(/@define-color blue (#[0-9A-Fa-f]{6});/)
                const accentMatch = cssContent.match(/@define-color accent (#[0-9A-Fa-f]{6});/)

                // Update colors
                if (bgMatch) {
                    theme.bg = parseColor(bgMatch[1]) || theme.bg
                    theme.bgDark = parseColor(bgMatch[1]) || theme.bgDark
                }
                if (bgDimMatch) {
                    theme.bgDark = parseColor(bgDimMatch[1]) || theme.bgDark
                }
                if (bgAltMatch) {
                    theme.bgLight = parseColor(bgAltMatch[1]) || theme.bgLight
                }
                if (fgMatch) {
                    theme.fg = parseColor(fgMatch[1]) || theme.fg
                }
                if (fgDimMatch) {
                    theme.fgDim = parseColor(fgDimMatch[1]) || theme.fgDim
                    theme.fgDark = parseColor(fgDimMatch[1]) || theme.fgDark
                }
                if (mutedMatch) {
                    theme.muted = parseColor(mutedMatch[1]) || theme.muted
                }
                if (cyanMatch) {
                    theme.cyan = parseColor(cyanMatch[1]) || theme.cyan
                }
                if (magentaMatch) {
                    theme.magenta = parseColor(magentaMatch[1]) || theme.magenta
                    theme.purple = parseColor(magentaMatch[1]) || theme.purple
                }
                if (redMatch) {
                    theme.red = parseColor(redMatch[1]) || theme.red
                }
                if (greenMatch) {
                    theme.green = parseColor(greenMatch[1]) || theme.green
                }
                if (yellowMatch) {
                    theme.yellow = parseColor(yellowMatch[1]) || theme.yellow
                    theme.orange = parseColor(yellowMatch[1]) || theme.orange
                }
                if (blueMatch) {
                    theme.blue = parseColor(blueMatch[1]) || theme.blue
                }
                if (accentMatch) {
                    theme.accent = parseColor(accentMatch[1]) || theme.accent
                } else if (cyanMatch) {
                    theme.accent = parseColor(cyanMatch[1]) || theme.accent
                }

                // Update accent dim with new accent color
                theme.accentDim = Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.2)

                theme.loaded = true
                cssContent = ""
                console.log("Theme: Colors loaded successfully")
                console.log("Theme: bg=" + theme.bg + ", fg=" + theme.fg + ", accent=" + theme.accent)
            }
        }
    }

    // Reload timer - check for CSS changes every 5 seconds
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
        console.log("Theme: Manual reload triggered")
        colorReader.running = true
    }
}
