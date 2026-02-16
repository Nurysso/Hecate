import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: workspaces
    spacing: theme.spacing / 2

    Theme { id: theme }

    Repeater {
        model: 9

        Item {
            id: workspaceItem
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28

            required property int index
            readonly property int workspaceId: index + 1

            readonly property bool isActive: Hyprland.focusedWorkspace ?
                Hyprland.focusedWorkspace.id === workspaceId : false

            readonly property bool hasWindows: {
                if (!Hyprland.workspaces) return false
                var workspaceList = Hyprland.workspaces.values
                if (!workspaceList) return false

                for (var i = 0; i < workspaceList.length; i++) {
                    var ws = workspaceList[i]
                    if (ws && ws.id === workspaceId) {
                        return true
                    }
                }
                return false
            }

            property bool isHovered: false

            // Workspace number text - always visible
            Text {
                anchors.centerIn: parent
                text: workspaceId
                color: {
                    if (isActive) return theme.accent
                    if (hasWindows) return theme.fg
                    return Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.3)
                }
                font.pixelSize: theme.fontSize - 1
                font.family: theme.fontFamily
                font.weight: isActive ? Font.DemiBold : Font.Normal
                opacity: isActive ? 1.0 : (hasWindows ? 0.8 : 0.5)

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }
            }

            // Active indicator - clean underline
            Rectangle {
                visible: isActive
                width: 12
                height: 2
                radius: 1
                color: theme.accent
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 2

                opacity: visible ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }
            }

            // Subtle background on hover
            Rectangle {
                anchors.fill: parent
                radius: 4
                color: Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.05)
                visible: isHovered
                opacity: visible ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                anchors.margins: -2
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onEntered: workspaceItem.isHovered = true
                onExited: workspaceItem.isHovered = false

                onClicked: {
                    if (Hyprland.dispatch) {
                        Hyprland.dispatch("workspace " + workspaceId)
                    }
                }
            }

            // Subtle scale on hover
            scale: isHovered ? 1.1 : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
