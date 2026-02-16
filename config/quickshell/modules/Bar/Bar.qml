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

            // Main bar - clean and minimal
            Rectangle {
                anchors.fill: parent
                color: theme.bg

                // Subtle bottom border for definition
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.08);
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: theme.padding * 2
                    anchors.rightMargin: theme.padding * 2
                    spacing: theme.spacing * 2

                    // Left section: Workspaces only
                    RowLayout {
                        Layout.alignment: Qt.AlignLeft
                        spacing: theme.spacing
                        Launcher {}
                        Workspaces {}
                    }

                    // Spacer
                    Item {
                        Layout.fillWidth: true
                    }

                    // Center section: Window dock
                    RowLayout {
                        Layout.alignment: Qt.AlignCenter
                        spacing: 0

                        WindowDock {}
                    }

                    // Spacer
                    Item {
                        Layout.fillWidth: true
                    }

                    // Right section: Clock + System tray
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        spacing: theme.spacing * 1.5

                        // System tray items
                        RowLayout {
                            spacing: theme.spacing
                            SystemStats {}
                            Notification {}
                            // Bluetooth {}
                            // Network {}
                            Power {}
                        }

                        // Separator
                        Rectangle {
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: theme.barHeight * 0.4
                            color: Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.1)
                        }

                        Clock {}
                    }
                }
            }

            // Details panel
            DetailsPanel {
                id: detailsPanel
            }
        }
    }
}
