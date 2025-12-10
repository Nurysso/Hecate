import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Rectangle {
    Layout.preferredHeight: theme.barHeight - 12
    Layout.preferredWidth: dockLayout.implicitWidth + theme.padding * 2


    radius: theme.radiusLarge
    color: theme.bg

    property var windows: []
    property string activeAddress: ""

    // Fetch all windows with their details
    Process {
        id: clientsProc
        command: ["sh", "-c", "hyprctl clients -j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const clients = JSON.parse(text)
                    const windowMap = new Map()

                    // Group windows by class
                    clients.forEach(client => {
                        const className = client.class || "unknown"
                        const address = client.address || ""
                        const workspace = client.workspace?.id || 1
                        const title = client.title || ""

                        if (!windowMap.has(className)) {
                            windowMap.set(className, {
                                class: className,
                                instances: []
                            })
                        }

                        windowMap.get(className).instances.push({
                            address: address,
                            workspace: workspace,
                            title: title
                        })
                    })

                    // Convert map to array
                    windows = Array.from(windowMap.values())
                } catch (e) {
                    console.log("Error parsing clients:", e)
                }
            }
        }
    }

    // Get active window
    Process {
        id: activeWindowProc
        command: ["sh", "-c", "hyprctl activewindow -j | jq -r '.address // empty'"]

        stdout: StdioCollector {
            onStreamFinished: {
                activeAddress = text ? text.trim() : ""
            }
        }
    }

    // Function to focus a window
    function focusWindow(address, workspace) {
        // First switch to the workspace
        focusWorkspaceProc.command = ["hyprctl", "dispatch", "workspace", workspace.toString()]
        focusWorkspaceProc.running = true

        // Small delay then focus the window
        Qt.callLater(() => {
            focusWindowProc.command = ["hyprctl", "dispatch", "focuswindow", "address:" + address]
            focusWindowProc.running = true
        })
    }

    Process {
        id: focusWorkspaceProc
    }

    Process {
        id: focusWindowProc
    }

    RowLayout {
        id: dockLayout
        anchors.centerIn: parent
        spacing: theme.spacingSmall

        Repeater {
            model: windows

            Rectangle {
                id: dockItem
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: theme.radiusSmall

                // Check if any instance of this app is active
                property bool isActive: {
                    const instances = modelData.instances || []
                    return instances.some(inst => inst.address === activeAddress)
                }

                color: isActive ? theme.accent : theme.bgLight

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2

                    // Icon loader
                    Item {
                        id: iconLoader
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24

                        property string iconPath: ""
                        property bool iconFound: false

                        // Improved icon search script
                        Process {
                            id: iconProc
                            command: ["sh", "-c", `
class='${modelData.class}'
class_lower=$(echo "$class" | tr '[:upper:]' '[:lower:]')

# Search locations in order of priority
search_paths=(
    "$HOME/.local/share/applications"
    "/usr/share/applications"
    "/usr/local/share/applications"
    "/var/lib/flatpak/exports/share/applications"
    "$HOME/.local/share/flatpak/exports/share/applications"
)

# Function to extract icon from desktop file
get_icon() {
    local file="$1"
    grep -m 1 '^Icon=' "$file" | cut -d= -f2- | tr -d '\\r\\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Try exact match first
for dir in "\${search_paths[@]}"; do
    [ -d "$dir" ] || continue

    # Try exact matches
    for pattern in "$class_lower.desktop" "$class.desktop"; do
        file="$dir/$pattern"
        if [ -f "$file" ]; then
            icon=$(get_icon "$file")
            if [ -n "$icon" ]; then
                echo "$icon"
                exit 0
            fi
        fi
    done
done

# Try fuzzy match if exact match fails
for dir in "\${search_paths[@]}"; do
    [ -d "$dir" ] || continue

    # Case-insensitive fuzzy match
    while IFS= read -r file; do
        icon=$(get_icon "$file")
        if [ -n "$icon" ]; then
            echo "$icon"
            exit 0
        fi
    done < <(find "$dir" -maxdepth 1 -iname "*$class_lower*.desktop" 2>/dev/null)
done

# No icon found
exit 1
`]

                            stdout: StdioCollector {
                                onStreamFinished: {
                                    const icon = text.trim()
                                    if (icon && icon.length > 0) {
                                        iconLoader.iconPath = icon
                                        iconLoader.iconFound = true
                                    } else {
                                        console.log("No icon found for:", modelData.class)
                                        iconLoader.iconFound = false
                                    }
                                }
                            }
                        }

                        Component.onCompleted: {
                            iconProc.running = true
                        }

                        // Show icon if found
                        Image {
                            anchors.fill: parent
                            visible: iconLoader.iconFound
                            source: iconLoader.iconFound ? "image://icon/" + iconLoader.iconPath : ""
                            sourceSize: Qt.size(24, 24)
                            fillMode: Image.PreserveAspectFit
                            smooth: true

                            onStatusChanged: {
                                if (status === Image.Error) {
                                    console.log("Failed to load icon:", iconLoader.iconPath, "for", modelData.class)
                                    iconLoader.iconFound = false
                                }
                            }
                        }

                        // Fallback icon
                        Text {
                            anchors.centerIn: parent
                            visible: !iconLoader.iconFound
                            text: "󰂭"
                            color: theme.fg
                            font.pixelSize: 20
                            font.family: "Symbols Nerd Font"
                        }
                    }

                    // Indicator dots for multiple instances
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 2
                        visible: modelData.instances.length > 1

                        // Indicator dots for multiple instances
                        Repeater {
                            model: Math.min(modelData.instances.length, 4)

                            Rectangle {
                                Layout.preferredWidth: 3
                                Layout.preferredHeight: 3
                                radius: 1.5
                                color: dockItem.isActive ? theme.fg : (theme.fgDim || theme.fg)
                            }
                        }
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onEntered: {
                        dockItem.color = Qt.lighter(dockItem.isActive ? theme.accent : theme.bgLight, 1.2)
                    }

                    onExited: {
                        dockItem.color = dockItem.isActive ? theme.accent : theme.bgLight
                    }

                    onClicked: {
                        const instances = modelData.instances || []
                        if (instances.length > 0) {
                            // Find currently active instance index
                            let currentIndex = instances.findIndex(inst => inst.address === activeAddress)

                            // If this app is active, cycle to next instance, otherwise focus first
                            if (currentIndex !== -1 && instances.length > 1) {
                                currentIndex = (currentIndex + 1) % instances.length
                            } else {
                                currentIndex = 0
                            }

                            const instance = instances[currentIndex]
                            focusWindow(instance.address, instance.workspace)
                        }
                    }
                }

                // Tooltip showing all instances
                Rectangle {
                    id: tooltip
                    visible: mouseArea.containsMouse && modelData.instances.length > 1
                    color: theme.bg
                    border.color: theme.bgLight
                    border.width: 1
                    radius: theme.radiusSmall

                    width: tooltipText.width + 16
                    height: tooltipText.height + 12

                    anchors.bottom: parent.top
                    anchors.bottomMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        id: tooltipText
                        anchors.centerIn: parent
                        color: theme.fg
                        font.pixelSize: 11
                        text: {
                            const instances = modelData.instances || []
                            return instances.map((inst, i) =>
                                `${i + 1}. WS${inst.workspace}: ${inst.title.substring(0, 30)}`
                            ).join('\n')
                        }
                    }
                }
            }
        }
    }

    // React to Hyprland events
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            // Only update on relevant events
            const eventName = event.name || ""
            if (eventName === "openwindow" ||
                eventName === "closewindow" ||
                eventName === "activewindow" ||
                eventName === "workspace") {
                clientsProc.running = true
                activeWindowProc.running = true
            }
        }
    }

    // Reduced timer interval for better responsiveness
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            clientsProc.running = true
            activeWindowProc.running = true
        }
    }

    // Initial load
    Component.onCompleted: {
        clientsProc.running = true
        activeWindowProc.running = true
    }
}
