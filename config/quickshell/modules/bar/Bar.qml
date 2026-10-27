import QtQuick
import Quickshell
import qs.config
import qs.components

// Widgets are picked in hecate.toml [bar]; "foo" loads widgets/Foo.qml.
Variants {
    model: Quickshell.screens

    PanelWindow {
        required property ShellScreen modelData
        screen: modelData
        anchors { top: true; left: true; right: true }
        implicitHeight: Theme.barHeight
        color: "transparent"

        component Section: Row {
            property var names
            spacing: Theme.gap / 2
            anchors.verticalCenter: parent.verticalCenter

            Repeater {
                model: parent.names
                Loader {
                    required property string modelData
                    source: Qt.resolvedUrl(`widgets/${modelData[0].toUpperCase()}${modelData.slice(1)}.qml`)
                }
            }
        }

        Item {
            id: content
            anchors.fill: parent
            anchors.leftMargin: Theme.gap * 1.5
            anchors.rightMargin: Theme.gap * 1.5
            opacity: 0
            transform: Translate { y: (content.opacity - 1) * 16 }
            Component.onCompleted: opacity = 1
            Behavior on opacity { Anim { duration: 700 } }

            Section { names: Config.bar.left; anchors.left: parent.left }
            Section { names: Config.bar.center; anchors.horizontalCenter: parent.horizontalCenter }
            Section { names: Config.bar.right; anchors.right: parent.right }
        }
    }
}
