import QtQuick
import QtQuick.Layouts

Rectangle {
    id: pill
    Layout.preferredHeight: 24
    Layout.preferredWidth: pillLayout.implicitWidth + 12
    radius: theme.radiusSmall
    color: isActive ? Qt.rgba(iconColor.r, iconColor.g, iconColor.b, 0.2) : "transparent"

    property string icon: ""
    property string value: "0%"
    property color iconColor: theme.fg
    property color valueColor: theme.fg
    property string panelType: "" // "cpu", "memory", "disk", "volume"
    property bool isActive: detailsPanel.activePanelType === panelType

    RowLayout {
        id: pillLayout
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: icon
            color: iconColor
            font.pixelSize: theme.iconSize
            font.family: theme.fontFamily
        }

        Text {
            text: value
            color: valueColor
            font.pixelSize: theme.fontSize - 1
            font.family: theme.fontFamily
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: pill.opacity = 0.8
        onExited: pill.opacity = 1.0
        onClicked: {
            if (detailsPanel.activePanelType === panelType) {
                detailsPanel.activePanelType = ""
            } else {
                detailsPanel.activePanelType = panelType
                detailsPanel.pillParent = pill
            }
        }
    }

    Behavior on opacity {
        NumberAnimation { duration: 100 }
    }
}
