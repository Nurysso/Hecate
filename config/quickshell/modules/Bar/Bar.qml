import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../../utils"

Scope {
    // Load singletons first
    SystemStats { id: systemStats }


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

            implicitHeight: ColorManager.barHeight
            color: "transparent"

            // Main bar - clean and minimal
            Rectangle {
                anchors.fill: parent
                color: ColorManager.bgColor

                // Subtle bottom border for definition
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Qt.rgba(ColorManager.fg.r, ColorManager.fg.g, ColorManager.fg.b, 0.08);
                }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: ColorManager.padding * 2
                anchors.rightMargin: ColorManager.padding * 2
                spacing: 0 // Spacing is handled by the Spacers and nested layouts

                // Left section
                RowLayout {
                    Layout.alignment: Qt.AlignLeft
                    spacing: ColorManager.spacing
                    Launcher {}
                    Workspaces {}
                    }

                    // Spacer 1
                    Item { Layout.fillWidth: true }

                    // Center section
                    RowLayout {
                        Layout.alignment: Qt.AlignCenter
                        // Important: give center section its own preferred width if it's drifting
                        WindowDock {}
                    }

                    // Spacer 2
                    Item { Layout.fillWidth: true }
                    RowLayout {
                            id: rightSection
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                            // Change spacing to something smaller, or 0 if you want to handle
                            // margins inside the components themselves.
                            spacing: 4

                            // Explicitly prevent this section from expanding into the center
                            Layout.fillWidth: false

                            SystemStats { Layout.alignment: Qt.AlignVCenter }
                            Notification { Layout.alignment: Qt.AlignVCenter }
                            Bluetooth { Layout.alignment: Qt.AlignVCenter }
                            Power { Layout.alignment: Qt.AlignVCenter }

                            // Separator
                            Rectangle {
                                Layout.preferredWidth: 1
                                Layout.preferredHeight: 14
                                Layout.leftMargin: 4
                                Layout.rightMargin: 4
                                color: ColorManager.mutedColor
                                opacity: 0.3
                            }

                            Clock {
                                // Crucial: Use Layout.preferredWidth so RowLayout respects the implicitWidth
                                Layout.preferredWidth: implicitWidth
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                }
            }
        }
    }
}
