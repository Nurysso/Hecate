import QtQuick
import QtQuick.Layouts
import com.hecate.settings

ColumnLayout {
    id: page
    property var monitors: []
    property real k: 0.1
    property real cx
    property real cy
    property bool failed

    function size(m) {
        const r = m.transform % 2 === 1
        return { w: (r ? m.height : m.width) / m.scale, h: (r ? m.width : m.height) / m.scale }
    }

    function reload() {
        monitors = JSON.parse(sys.monitors())
        if (!monitors.length) return
        const xs = [].concat(...monitors.map(m => [m.x, m.x + size(m).w]))
        const ys = [].concat(...monitors.map(m => [m.y, m.y + size(m).h]))
        const w = Math.max(...xs) - Math.min(...xs)
        const h = Math.max(...ys) - Math.min(...ys)
        k = Math.min(canvas.width / w, canvas.height / h) * 0.6
        cx = (Math.max(...xs) + Math.min(...xs)) / 2
        cy = (Math.max(...ys) + Math.min(...ys)) / 2
    }

    function place(m, x, y) {
        failed = !sys.applyMonitorLayout(m.name, Math.round(x), Math.round(y), m.width, m.height, m.scale, m.refreshRate)
        reload()
    }

    Backend { id: sys }

    onVisibleChanged: if (visible) reload()
    spacing: Theme.pad

    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: Theme.radius
        color: Theme.surface_container_low
        border.color: Theme.outline_variant

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.pad * 1.5
            spacing: Theme.gap

            StyledText {
                text: "Monitors"
                color: Theme.primary
                font.weight: Font.DemiBold
                font.pixelSize: Theme.fontSize + 4
            }
            StyledText {
                text: page.failed
                    ? "Hyprland rejected that layout"
                    : "Drag a monitor, or focus it and use the arrow keys (Shift for bigger steps). Changes apply live and reset when Hyprland reloads its config."
                color: page.failed ? Theme.error : Theme.on_surface_variant
                wrapMode: Text.Wrap
                elide: Text.ElideNone
                Layout.fillWidth: true
            }

            Rectangle {
                id: canvas
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: Theme.gap
                radius: Theme.radiusSmall
                color: Theme.surface_container
                clip: true
                onWidthChanged: Qt.callLater(page.reload)
                onHeightChanged: Qt.callLater(page.reload)

                StyledText {
                    visible: page.monitors.length === 0
                    anchors.centerIn: parent
                    text: "No monitors reported by hyprctl"
                    color: Theme.on_surface_variant
                }

                Repeater {
                    model: page.monitors

                    Rectangle {
                        id: screen
                        required property var modelData
                        readonly property var dim: page.size(modelData)
                        x: canvas.width / 2 + (modelData.x - page.cx) * page.k
                        y: canvas.height / 2 + (modelData.y - page.cy) * page.k
                        width: dim.w * page.k
                        height: dim.h * page.k
                        radius: 8
                        color: drag.active ? Theme.primary_container : Theme.secondary_container
                        border.width: drag.active || activeFocus ? 3 : 1
                        border.color: drag.active || activeFocus ? Theme.primary : Theme.outline
                        z: drag.active ? 1 : 0
                        activeFocusOnTab: true
                        Accessible.role: Accessible.Graphic
                        Accessible.name: modelData.name + ", position " + modelData.x + " by " + modelData.y

                        function commit() {
                            page.place(modelData, (x - canvas.width / 2) / page.k + page.cx, (y - canvas.height / 2) / page.k + page.cy)
                        }

                        Keys.onPressed: e => {
                            const step = e.modifiers & Qt.ShiftModifier ? 100 : 10
                            const d = { [Qt.Key_Left]: [-step, 0], [Qt.Key_Right]: [step, 0], [Qt.Key_Up]: [0, -step], [Qt.Key_Down]: [0, step] }[e.key]
                            if (!d) return
                            e.accepted = true
                            page.place(modelData, modelData.x + d[0], modelData.y + d[1])
                        }

                        HoverHandler { cursorShape: Qt.SizeAllCursor }
                        DragHandler {
                            id: drag
                            onActiveChanged: if (!active) screen.commit()
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2

                            StyledText {
                                text: screen.modelData.name
                                color: drag.active ? Theme.on_primary_container : Theme.on_secondary_container
                                font.weight: Font.DemiBold
                                Layout.alignment: Qt.AlignHCenter
                            }
                            StyledText {
                                text: screen.modelData.width + "×" + screen.modelData.height + " @ " + Math.round(screen.modelData.refreshRate) + " Hz"
                                color: drag.active ? Theme.on_primary_container : Theme.on_secondary_container
                                font.pixelSize: Theme.fontSize - 2
                                Layout.alignment: Qt.AlignHCenter
                            }
                            StyledText {
                                text: screen.modelData.x + ", " + screen.modelData.y + (screen.modelData.scale !== 1 ? "  ·  ×" + screen.modelData.scale : "")
                                color: drag.active ? Theme.on_primary_container : Theme.on_secondary_container
                                font.pixelSize: Theme.fontSize - 3
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }
            }
        }
    }
}
