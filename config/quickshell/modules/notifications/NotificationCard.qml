import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.config
import qs.components

Rectangle {
    id: root
    required property Notification modelData
    readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
    readonly property color fg: critical ? Theme.on_error_container : Theme.on_surface
    readonly property alias hovered: hover.containsMouse

    implicitHeight: body.implicitHeight + Theme.pad * 2
    radius: Theme.radius
    color: critical ? Theme.error_container : Theme.surface_container_high
    border.color: Theme.outline_variant
    Behavior on color { CAnim {} }

    RetainableLock { object: root.modelData; locked: true }

    StateLayer {
        id: hover
        tint: root.fg
        onClicked: root.modelData.actions.find(a => a.identifier === "default")?.invoke()
    }

    RowLayout {
        id: body
        anchors.fill: parent
        anchors.margins: Theme.pad
        spacing: 12

        ClippingRectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 40
            implicitHeight: 40
            radius: 12
            color: Theme.secondary_container

            IconImage {
                id: img
                anchors.fill: parent
                source: root.modelData.image || Quickshell.iconPath(root.modelData.appIcon, true)
                visible: source != ""
            }
            Icon { anchors.centerIn: parent; text: Theme.icon.bell; color: Theme.on_secondary_container; visible: !img.visible }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                StyledText {
                    Layout.fillWidth: true
                    text: root.modelData.appName
                    color: root.critical ? root.fg : Theme.on_surface_variant
                    font.pixelSize: Theme.fontSize - 2
                }
                Icon {
                    text: Theme.icon.close
                    color: root.fg
                    font.pixelSize: 16
                    StateLayer { anchors.margins: -6; onClicked: root.modelData.dismiss() }
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.modelData.summary
                color: root.fg
                font.weight: Font.DemiBold
            }

            StyledText {
                Layout.fillWidth: true
                text: root.modelData.body
                visible: text
                color: root.fg
                opacity: 0.85
                wrapMode: Text.Wrap
                maximumLineCount: 4
                textFormat: Text.StyledText
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: Theme.gap / 2
                visible: children.length > 1

                Repeater {
                    model: root.modelData.actions.filter(a => a.identifier !== "default")
                    Pill {
                        required property NotificationAction modelData
                        label: modelData.text
                        color: Theme.secondary_container
                        implicitHeight: 32
                        onClicked: modelData.invoke()
                    }
                }
            }
        }
    }
}
