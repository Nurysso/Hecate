import QtQuick
import qs.config

// Keyboard hints for a panel's footer: keys is a list of [key, what it does].
Row {
    id: root
    property var keys: []

    spacing: Theme.px(14)

    Repeater {
        model: root.keys

        Row {
            required property var modelData
            spacing: Theme.px(6)

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: Math.max(implicitHeight, key.implicitWidth + Theme.px(10))
                implicitHeight: Theme.px(20)
                radius: Theme.px(5)
                color: Theme.layerHigh
                StyledText { id: key; anchors.centerIn: parent; text: modelData[0]; font.pixelSize: Theme.fontTiny; font.weight: Font.DemiBold; color: Theme.on_surface_variant }
            }
            StyledText { anchors.verticalCenter: parent.verticalCenter; text: modelData[1]; font.pixelSize: Theme.fontSmall; color: Theme.on_surface_variant }
        }
    }
}
