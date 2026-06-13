import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "../../utils"

RowLayout {
    id: workspaces
    spacing: 2

    Repeater {
        model: 9

        Item {
            id: wsItem
            required property int index
            readonly property int wsId: index + 1
            readonly property bool isActive: Hyprland.focusedWorkspace?.id === wsId ?? false
            readonly property bool hasWindows: {
                if (!Hyprland.workspaces) return false
                const list = Hyprland.workspaces.values
                if (!list) return false
                for (var i = 0; i < list.length; i++)
                    if (list[i]?.id === wsId) return true
                return false
            }
            property bool hovered: false

            Layout.preferredWidth: isActive ? 32 : 26
            Layout.preferredHeight: 26

            Behavior on Layout.preferredWidth {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            // Background pill — only visible when active or hovered
            Rectangle {
                anchors.fill: parent
                radius: 5
                color: isActive
                    ? Qt.rgba(ColorManager.accent.r, ColorManager.accent.g, ColorManager.accent.b, 0.15)
                    : Qt.rgba(1, 1, 1, hovered ? 0.07 : 0.0)
                border.width: isActive ? 1 : 0
                border.color: Qt.rgba(ColorManager.accent.r, ColorManager.accent.g, ColorManager.accent.b, 0.4)

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
            }

            Text {
                anchors.centerIn: parent
                text: wsItem.wsId
                font.pixelSize: 12
                font.weight: isActive ? Font.Medium : Font.Normal
                color: isActive ? ColorManager.accentColor
                     : hasWindows ? ColorManager.fgColor
                     : ColorManager.mutedColor
                opacity: isActive ? 1.0 : hasWindows ? 0.7 : 0.35

                Behavior on color   { ColorAnimation { duration: 150 } }
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            // Occupied dot (non-active workspaces with windows)
            Rectangle {
                visible: hasWindows && !isActive
                width: 3; height: 3; radius: 1.5
                color: ColorManager.mutedColor
                opacity: 0.6
                anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 2 }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: wsItem.hovered = true
                onExited:  wsItem.hovered = false
                onClicked: Hyprland.dispatch?.("workspace " + wsItem.wsId)
            }

            scale: hovered && !isActive ? 1.08 : 1.0
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }
    }
}
