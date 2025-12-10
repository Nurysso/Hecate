import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: hyprInfo

    property string activeWindow: ""
    property string activeWindowTitle: ""
    property string activeWindowIcon: ""
    property string currentLayout: "Tiled"
    property string layoutIcon: theme.iconTiled
    property var openWindows: []

    // Active window class and title
    Process {
        id: windowProc
        command: ["sh", "-c", "hyprctl activewindow -j | jq -r '.class // empty'"]
        stdout: StdioCollector {
            onStreamFinished: {
                hyprInfo.activeWindow = text ? text.trim() : ""
                hyprInfo.activeWindowIcon = getIconForClass(hyprInfo.activeWindow)
            }
        }
    }

    // Active window title
    Process {
        id: titleProc
        command: ["sh", "-c", "hyprctl activewindow -j | jq -r '.title // empty'"]
        stdout: StdioCollector {
            onStreamFinished: {
                hyprInfo.activeWindowTitle = text ? text.trim() : ""
            }
        }
    }

    // Get all open windows for dock
    Process {
        id: clientsProc
        command: ["sh", "-c", "hyprctl clients -j | jq -r '.[] | .class'"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    const windows = text.trim().split('\n').filter(w => w.length > 0)
                    const uniqueWindows = [...new Set(windows)].map(className => ({
                        class: className,
                        icon: getIconForClass(className)
                    }))
                    hyprInfo.openWindows = uniqueWindows
                } else {
                    hyprInfo.openWindows = []
                }
            }
        }
    }

    // Current layout (unchanged)
    Process {
        id: layoutProc
        command: ["sh", "-c", "hyprctl activewindow -j | jq -r 'if .floating then \"Floating\" elif .fullscreen == 1 then \"Fullscreen\" else \"Tiled\" end'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const layout = text ? text.trim() : "Tiled"
                hyprInfo.currentLayout = layout
                // Set appropriate icon
                if (layout === "Floating") {
                    hyprInfo.layoutIcon = theme.iconFloating
                } else if (layout === "Fullscreen") {
                    hyprInfo.layoutIcon = theme.iconFullscreen
                } else {
                    hyprInfo.layoutIcon = theme.iconTiled
                }
            }
        }
    }

    // Function to map window class to icon name
    function getIconForClass(className) {
        const lowerClass = className.toLowerCase()

        // Browsers
        if (lowerClass.includes("firefox")) return "firefox"
        if (lowerClass.includes("chrome") || lowerClass.includes("chromium")) return "google-chrome"
        if (lowerClass.includes("brave")) return "brave-browser"
        if (lowerClass.includes("edge")) return "microsoft-edge"
        if (lowerClass.includes("opera")) return "opera"

        // Editors & IDEs
        if (lowerClass.includes("code") || lowerClass.includes("vscode")) return "vscode"
        if (lowerClass.includes("vim") || lowerClass.includes("neovim")) return "vim"
        if (lowerClass.includes("sublime")) return "sublime-text"
        if (lowerClass.includes("intellij") || lowerClass.includes("idea")) return "intellij-idea"

        // Terminals
        if (lowerClass.includes("kitty")) return "kitty"
        if (lowerClass.includes("alacritty")) return "alacritty"
        if (lowerClass.includes("terminal") || lowerClass.includes("konsole")) return "terminal"
        if (lowerClass.includes("wezterm")) return "wezterm"

        // Communication
        if (lowerClass.includes("discord")) return "discord"
        if (lowerClass.includes("slack")) return "slack"
        if (lowerClass.includes("telegram")) return "telegram"
        if (lowerClass.includes("signal")) return "signal"

        // File managers
        if (lowerClass.includes("thunar")) return "thunar"
        if (lowerClass.includes("nautilus")) return "nautilus"
        if (lowerClass.includes("dolphin")) return "dolphin"
        if (lowerClass.includes("pcmanfm")) return "pcmanfm"

        // Media
        if (lowerClass.includes("spotify")) return "spotify"
        if (lowerClass.includes("vlc")) return "vlc"
        if (lowerClass.includes("mpv")) return "mpv"

        // Default fallback
        return "application-x-executable"
    }

    // React to Hyprland events
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            windowProc.running = true
            titleProc.running = true
            layoutProc.running = true
            clientsProc.running = true
        }
    }

    // Fallback timer
    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: {
            windowProc.running = true
            titleProc.running = true
            layoutProc.running = true
            clientsProc.running = true
        }
    }
}
