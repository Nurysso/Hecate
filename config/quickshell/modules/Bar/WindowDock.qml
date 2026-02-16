import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Item {
    id: windowDock
    Layout.preferredHeight: theme.barHeight
    Layout.preferredWidth: dockLayout.implicitWidth

    property var windows: []
    property string activeAddress: ""

    // Fetch all windows
    Process {
        id: clientsProc
        command: ["sh", "-c", "hyprctl clients -j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const clients = JSON.parse(text)
                    const windowMap = new Map()

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

    // Focus window function
    function focusWindow(address, workspace) {
        focusWorkspaceProc.command = ["hyprctl", "dispatch", "workspace", workspace.toString()]
        focusWorkspaceProc.running = true

        Qt.callLater(() => {
            focusWindowProc.command = ["hyprctl", "dispatch", "focuswindow", "address:" + address]
            focusWindowProc.running = true
        })
    }

    Process { id: focusWorkspaceProc }
    Process { id: focusWindowProc }

    RowLayout {
        id: dockLayout
        anchors.centerIn: parent
        spacing: theme.spacing

        Repeater {
            model: windows

            Item {
                id: dockItem
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32

                property bool isActive: {
                    const instances = modelData.instances || []
                    return instances.some(inst => inst.address === activeAddress)
                }

                property bool isHovered: false
                scale: isHovered ? 1.15 : 1.0

                Behavior on scale {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }

                // Icon container
                Item {
                    id: iconLoader
                    anchors.centerIn: parent
                    width: 24
                    height: 24

                    property string iconPath: ""
                    property bool iconFound: false

                    Process {
                        id: iconProc
                        command: ["sh", "-c", `
class='${modelData.class}'
class_lower=$(echo "$class" | tr '[:upper:]' '[:lower:]')

search_paths=(
    "$HOME/.local/share/applications"
    "/usr/share/applications"
    "/usr/local/share/applications"
    "/var/lib/flatpak/exports/share/applications"
    "$HOME/.local/share/flatpak/exports/share/applications"
)

get_icon() {
    local file="$1"
    grep -m 1 '^Icon=' "$file" | cut -d= -f2- | tr -d '\\r\\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

for dir in "\${search_paths[@]}"; do
    [ -d "$dir" ] || continue
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

for dir in "\${search_paths[@]}"; do
    [ -d "$dir" ] || continue
    while IFS= read -r file; do
        icon=$(get_icon "$file")
        if [ -n "$icon" ]; then
            echo "$icon"
            exit 0
        fi
    done < <(find "$dir" -maxdepth 1 -iname "*$class_lower*.desktop" 2>/dev/null)
done

exit 1
`]
                        stdout: StdioCollector {
                            onStreamFinished: {
                                const icon = text.trim()
                                if (icon && icon.length > 0) {
                                    iconLoader.iconPath = icon
                                    iconLoader.iconFound = true
                                } else {
                                    iconLoader.iconFound = false
                                }
                            }
                        }
                    }

                    Component.onCompleted: {
                        iconProc.running = true
                    }

                    // Icon image
                    Image {
                        anchors.fill: parent
                        visible: iconLoader.iconFound
                        source: iconLoader.iconFound ? "image://icon/" + iconLoader.iconPath : ""
                        sourceSize: Qt.size(24, 24)
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        opacity: dockItem.isActive ? 1.0 : 0.6

                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }

                        onStatusChanged: {
                            if (status === Image.Error) {
                                iconLoader.iconFound = false
                            }
                        }
                    }

                    // Fallback
                    Text {
                        anchors.centerIn: parent
                        visible: !iconLoader.iconFound
                        text: "●"
                        color: theme.fg
                        font.pixelSize: 18
                        opacity: dockItem.isActive ? 1.0 : 0.6

                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }
                    }
                }

                // Active indicator - simple line below
                Rectangle {
                    visible: dockItem.isActive
                    width: 16
                    height: 2
                    radius: 1
                    color: theme.accent
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: -6

                    opacity: visible ? 1.0 : 0.0

                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }
                }

                // Multiple instances indicator
                Row {
                    visible: modelData.instances.length > 1
                    spacing: 2
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: -4
                    anchors.rightMargin: -4

                    Repeater {
                        model: Math.min(modelData.instances.length - 1, 3)

                        Rectangle {
                            width: 3
                            height: 3
                            radius: 1.5
                            color: theme.fg
                            opacity: 0.5
                        }
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onEntered: dockItem.isHovered = true
                    onExited: dockItem.isHovered = false

                    onClicked: {
                        const instances = modelData.instances || []
                        if (instances.length > 0) {
                            let currentIndex = instances.findIndex(inst => inst.address === activeAddress)

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
            }
        }
    }

    // React to Hyprland events
    Connections {
        target: Hyprland
        function onRawEvent(event) {
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

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            clientsProc.running = true
            activeWindowProc.running = true
        }
    }

    Component.onCompleted: {
        clientsProc.running = true
        activeWindowProc.running = true
    }
}
