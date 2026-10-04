import QtQuick 2.15
import QtQuick.Controls 2.0

Item {
    id: root

    property string text: ""
    property string prevText: "<"
    property string nextText: ">"
    property int fontPointSize: sessionsFontSize
    property string fontFamily: defaultFont

    signal prevClicked()
    signal nextClicked()

    // ---- Previous button ----
    Text {
        id: prevButton
        text: root.prevText
        color: textColor
        font.pointSize: root.fontPointSize
        font.family: root.fontFamily
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            // rightMargin has no effect on a left anchor; use leftMargin on the label instead
        }
        opacity: 0.7

        Behavior on opacity { NumberAnimation { duration: 120 } }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.prevClicked()
            onEntered: prevButton.opacity = 1
            onExited:  prevButton.opacity = 0.7
        }
    }

    // ---- Session label ----
    Text {
        id: sessionLabel
        text: root.text
        color: textColor
        font.pointSize: root.fontPointSize
        font.family: root.fontFamily
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        anchors {
            left: prevButton.right
            right: nextButton.left
            leftMargin: 8
            rightMargin: 8
            verticalCenter: parent.verticalCenter
        }
    }

    // ---- Next button ----
    Text {
        id: nextButton
        text: root.nextText
        color: textColor
        font.pointSize: root.fontPointSize
        font.family: root.fontFamily
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        opacity: 0.7

        Behavior on opacity { NumberAnimation { duration: 120 } }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.nextClicked()
            onEntered: nextButton.opacity = 1
            onExited:  nextButton.opacity = 0.7
        }
    }
}
