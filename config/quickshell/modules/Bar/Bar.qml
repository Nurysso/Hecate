import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../../utils"

Scope {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: 36
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                color: ColorManager.bgColor

                // Subtle bottom border
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: ColorManager.mutedColor
                    opacity: 0.15
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 16

                    // Left: Launcher + Workspaces
                    RowLayout {
                        Layout.alignment: Qt.AlignLeft
                        spacing: 8
                        Launcher {}
                        Workspaces {}
                    }

                    Item { Layout.fillWidth: true }

                    // Center: Window dock
                    RowLayout {
                        Layout.alignment: Qt.AlignCenter
                        spacing: 0
                        WindowDock {}
                    }

                    Item { Layout.fillWidth: true }

                    // Right: System tray + Clock
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        spacing: 12

                        RowLayout {
                            spacing: 8
                            SystemStats {}
                            Notification {}
                            Bluetooth {}
                            Power {}
                        }

                        // Separator
                        Rectangle {
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 36 * 0.4
                            color: ColorManager.mutedColor
                            opacity: 0.3
                        }

                        Clock {}
                    }
                }
            }
        }
    }
}
