import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../../utils"

Scope {
    SystemStats { id: systemStats }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: ColorManager.barHeight
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                color: ColorManager.bgColor

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: ColorManager.padding * 2
                    anchors.rightMargin: ColorManager.padding * 2
                    spacing: 0

                    //  Left
                    RowLayout {
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                        spacing: ColorManager.spacing

                        Launcher {}
                        Workspaces {}
                    }

                    Item { Layout.fillWidth: true }

                    //  Center
                    RowLayout {
                        Layout.alignment: Qt.AlignCenter
                        WindowDock {}
                    }

                    Item { Layout.fillWidth: true }

                    //  Right
                    RowLayout {
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        Layout.fillWidth: false
                        spacing: 2

                        SystemStats { Layout.alignment: Qt.AlignVCenter }

                        Separator {}

                        Notification { Layout.alignment: Qt.AlignVCenter }
                        Bluetooth   { Layout.alignment: Qt.AlignVCenter }
                        Power       { Layout.alignment: Qt.AlignVCenter }

                        Separator {}

                        Clock {
                            Layout.preferredWidth: implicitWidth
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }
                }
            }
        }
    }
}
