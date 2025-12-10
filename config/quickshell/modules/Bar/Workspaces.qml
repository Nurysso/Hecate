import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: workspaces
    spacing: 8

    Theme { id: theme }

    Repeater {
        model: 9

        Item {
            Layout.preferredWidth: 24
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

            // Dot indicator
            Rectangle {
                anchors.centerIn: parent
                width: isActive ? 12 : (hasWindows ? 6 : 6)
                height: width
                radius: width / 2

                color: isActive ? theme.accent :
                       (hasWindows ? theme.fg : theme.fgDark)

                opacity: isActive ? 1.0 : (hasWindows ? 0.8 : 0.4)

                // Smooth animations
                Behavior on width {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on height {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }

                // Subtle glow for active workspace

            }

            // Hover/click area
            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onEntered: parent.scale = 1.2
                onExited: parent.scale = 1.0

                onClicked: {
                    if (Hyprland.dispatch) {
                        Hyprland.dispatch("workspace " + workspaceId)
                    }
                }
            }

            // Scale animation for hover
            Behavior on scale {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.5
                }
            }

            // Tooltip on hover
            Rectangle {
                id: tooltip
                visible: parent.children[1].containsMouse
                anchors.bottom: parent.top
                anchors.bottomMargin: 4
                anchors.horizontalCenter: parent.horizontalCenter

                width: tooltipText.width + 12
                height: tooltipText.height + 6
                radius: 4
                color: theme.bgLight
                border.width: 1
                border.color: theme.accentDim

                opacity: visible ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }

                Text {
                    id: tooltipText
                    text: workspaceId
                    color: theme.fg
                    font.pixelSize: theme.fontSize - 2
                    font.family: theme.fontFamily
                    anchors.centerIn: parent
                }
            }
        }
    }
}
