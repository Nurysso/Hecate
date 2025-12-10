import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
    // Load singletons first
    Theme { id: theme }
    SystemStats { id: systemStats }
    HyprlandInfo { id: hyprlandInfo }

    // Create panel for each screen
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

            implicitHeight: theme.barHeight
            color: "transparent"

            // Main bar container
            Rectangle {
                anchors.fill: parent
                color: theme.bg

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: theme.padding
                    anchors.rightMargin: theme.padding
                    spacing: theme.spacing

                    // Left section: Logo + Workspaces
                    RowLayout {
                        Layout.alignment: Qt.AlignLeft
                        spacing: theme.spacing

                        Launcher {}
                        Separator {}
                        Workspaces {}
                    }

                    // Spacer to push center content to middle
                    Item {
                        Layout.fillWidth: true
                    }

                    // Center section: Window title
                    RowLayout {
                        Layout.alignment: Qt.AlignCenter
                        spacing: theme.spacing

                        Separator {}
                        WindowDock {}
                        Clock {}
                        Separator {}
                    }

                    // Spacer to push right content to right
                    Item {
                        Layout.fillWidth: true
                    }

                    // Right section: System info
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        spacing: theme.spacing / 2

                        Notification {}
                        Bluetooth {}
                        Network {}
                        Power {}
                    }
                }
            }

            // Details panel - outside the layout hierarchy
            DetailsPanel {
                id: detailsPanel
            }
        }
    }
}
