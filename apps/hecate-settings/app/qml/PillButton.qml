import QtQuick
import com.hecate.settings

Rectangle {
    id: root
    property string text
    property string icon
    property color fg: Theme.on_primary
    signal clicked

    implicitWidth: text ? row.implicitWidth + Theme.pad * 2 : implicitHeight
    implicitHeight: 36
    radius: height / 2
    color: Theme.primary
    opacity: enabled ? 1 : 0.4
    Accessible.role: Accessible.Button
    Accessible.name: text
    Behavior on color { CAnim {} }

    StateLayer { tint: root.fg; onClicked: root.clicked() }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.gap

        StyledText { visible: root.icon; text: root.icon; color: root.fg; font.family: Theme.iconFont; font.pixelSize: 18 }
        StyledText { visible: root.text; text: root.text; color: root.fg; font.weight: Font.Medium }
    }
}
