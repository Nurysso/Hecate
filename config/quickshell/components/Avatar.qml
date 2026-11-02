import QtQuick
import Quickshell.Widgets
import qs.config

// The user's picture (~/.config/hecate/user.png), or an account icon without one.
ClippingRectangle {
    id: root
    property int size: Theme.px(44)

    implicitWidth: size
    implicitHeight: size
    radius: size / 2
    color: Theme.primary_container

    Icon {
        anchors.centerIn: parent
        visible: img.status !== Image.Ready
        text: Theme.icon.account
        color: Theme.on_primary_container
        font.pixelSize: Math.round(root.size * 0.6)
    }

    Image {
        id: img
        anchors.fill: parent
        source: "file://" + Config.home + "/.config/hecate/user.png"
        sourceSize.width: root.size * 2
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }
}
