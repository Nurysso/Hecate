import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services

// One notification. As a popup it sits on its own glass with a countdown along its bottom edge
// (paused while hovered) and can be swiped sideways to put it away.
Glass {
    id: root
    required property Notification modelData
    property bool popup
    property real countdown: 1
    readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
    readonly property color fg: critical ? Theme.on_error_container : Theme.on_surface
    readonly property alias hovered: hover.containsMouse
    readonly property string picture: modelData.image || (modelData.appIcon ? Quickshell.iconPath(modelData.appIcon, true) : "")
    property real now: Date.now()
    signal swiped

    glass: popup
    tint: critical ? Theme.error_container : Theme.surface_container
    color: popup ? Theme.alpha(tint, Math.max(Theme.opacity, critical ? 0.92 : 0)) : critical ? Theme.alpha(Theme.error_container, 0.75) : Theme.layer
    radius: popup ? Theme.radiusLarge : Theme.radiusSmall + Theme.px(2)
    implicitHeight: body.implicitHeight + Theme.pad * 2
    clip: true

    Timer { running: true; repeat: true; interval: 30000; onTriggered: root.now = Date.now() }
    RetainableLock { object: root.modelData; locked: true }

    StateLayer {
        id: hover
        tint: root.fg
        radius: root.radius
        onClicked: {
            const action = root.modelData.actions.find(a => a.identifier === "default")
            if (action) action.invoke()
            if (root.popup) root.swiped()
        }
    }

    // Swipe sideways to put the popup away (it stays in the history); a short drag springs back
    DragHandler {
        id: drag
        enabled: root.popup
        yAxis.enabled: false
        target: null
        onTranslationChanged: if (active) root.x = translation.x
        onActiveChanged: {
            if (active) return
            if (Math.abs(root.x) > root.width * 0.3) root.swiped()
            else root.x = 0
        }
    }
    Behavior on x { enabled: !drag.active; Anim { duration: Theme.animFast } }

    RowLayout {
        id: body
        anchors.fill: parent
        anchors.margins: Theme.pad
        spacing: Theme.px(12)

        ClippingRectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: Theme.px(40)
            implicitHeight: Theme.px(40)
            radius: Theme.radiusSmall
            color: root.critical ? Theme.error : Theme.secondary_container

            IconImage { id: pic; anchors.fill: parent; source: root.picture; visible: root.picture !== "" }
            Icon {
                anchors.centerIn: parent
                visible: !pic.visible
                text: Theme.icon.bell
                color: root.critical ? Theme.on_error : Theme.on_secondary_container
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.px(2)

            RowLayout {
                spacing: Theme.px(6)
                StyledText {
                    Layout.fillWidth: true
                    text: [root.modelData.appName, Notifs.ago(root.modelData, root.now)].filter(s => s).join("  ·  ")
                    color: root.critical ? root.fg : Theme.on_surface_variant
                    font.pixelSize: Theme.fontSmall
                }
                IconButton {
                    size: Theme.px(24)
                    icon: Theme.icon.close
                    fg: root.fg
                    opacity: root.hovered || !root.popup ? 1 : 0.5
                    onClicked: root.modelData.dismiss()
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.modelData.summary
                color: root.fg
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
                maximumLineCount: 2
            }

            StyledText {
                Layout.fillWidth: true
                visible: text
                text: root.modelData.body
                color: root.fg
                opacity: 0.85
                wrapMode: Text.Wrap
                maximumLineCount: root.popup ? 3 : 5
                textFormat: Text.StyledText
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: Theme.px(8)
                spacing: Theme.px(6)
                visible: actions.count > 0

                Repeater {
                    id: actions
                    model: root.modelData.actions.filter(a => a.identifier !== "default")

                    Rectangle {
                        required property NotificationAction modelData
                        implicitWidth: label.implicitWidth + Theme.px(24)
                        implicitHeight: Theme.px(32)
                        radius: height / 2
                        color: root.critical ? Theme.alpha(Theme.on_error_container, 0.14) : Theme.layerHigh
                        StyledText { id: label; anchors.centerIn: parent; text: parent.modelData.text; color: root.fg; font.weight: Font.Medium; font.pixelSize: Theme.fontSmall }
                        StateLayer { tint: root.fg; onClicked: parent.modelData.invoke() }
                    }
                }
            }
        }
    }

    // Time left before the popup goes away
    Rectangle {
        visible: root.popup && !root.critical
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.bottomMargin: Theme.px(3)
        anchors.leftMargin: root.radius
        width: (parent.width - root.radius * 2) * root.countdown
        height: Theme.px(2)
        radius: height / 2
        color: Theme.alpha(Theme.primary, 0.7)
    }
}
