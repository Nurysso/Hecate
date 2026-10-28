import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Shapes
import com.hecate.settings

RowLayout {
    id: page
    property var curves: []
    signal save(string name, var def)

    property string selected
    readonly property var curve: curves.find(c => c.name === selected) ?? curves[0] ?? null
    readonly property bool bezier: Array.isArray(curve?.def?.points)
    property real x1
    property real y1
    property real x2
    property real y2
    readonly property var spline: [x1, y1, x2, y2, 1, 1]

    onCurveChanged: {
        const p = curve?.def?.points
        if (!Array.isArray(p)) return
        x1 = p[0][0]; y1 = p[0][1]; x2 = p[1][0]; y2 = p[1][1]
    }
    onSplineChanged: preview.restart()

    function commit() {
        save(curve.name, Object.assign({}, curve.def, { points: [[x1, y1], [x2, y2]] }))
    }

    spacing: Theme.pad

    Rectangle {
        Layout.fillHeight: true
        Layout.preferredWidth: 220
        radius: Theme.radius
        color: Theme.surface_container
        border.color: Theme.outline_variant

        ListView {
            anchors.fill: parent
            anchors.margins: Theme.pad
            clip: true
            spacing: 4
            model: page.curves

            delegate: Rectangle {
                id: pill
                required property var modelData
                readonly property bool active: modelData.name === page.curve?.name
                width: ListView.view.width
                height: 40
                radius: height / 2
                color: active ? Theme.secondary_container : "transparent"
                Behavior on color { CAnim {} }

                StateLayer { onClicked: page.selected = pill.modelData.name }
                StyledText {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.pad
                    text: pill.modelData.name
                    color: pill.active ? Theme.on_secondary_container : Theme.on_surface_variant
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: Theme.radius
        color: Theme.surface_container
        border.color: Theme.outline_variant

        StyledText {
            visible: page.curve && !page.bezier
            anchors.centerIn: parent
            width: parent.width - Theme.pad * 4
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            color: Theme.on_surface_variant
            text: page.curve ? Object.entries(page.curve.def).map(([k, v]) => k + " = " + v).join("    ") + "\nSpring curves are read-only here" : ""
        }

        ColumnLayout {
            visible: page.bezier
            anchors.fill: parent
            anchors.margins: Theme.pad * 2
            spacing: Theme.pad

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Item {
                    id: plot
                    readonly property real unit: Math.min(parent.width, parent.height / 1.6) - 20
                    width: unit
                    height: unit * 1.6
                    anchors.centerIn: parent

                    function px(x) { return x * unit }
                    function py(y) { return (1.3 - y) * unit }
                    function move(i, scene) {
                        const p = mapFromItem(null, scene.x, scene.y)
                        const x = Number(Math.max(0, Math.min(1, p.x / unit)).toFixed(3))
                        const y = Number(Math.max(-0.5, Math.min(1.5, 1.3 - p.y / unit)).toFixed(3))
                        if (i === 0) { page.x1 = x; page.y1 = y } else { page.x2 = x; page.y2 = y }
                    }

                    Rectangle {
                        x: plot.px(0)
                        y: plot.py(1)
                        width: plot.px(1)
                        height: plot.py(0) - plot.py(1)
                        color: Theme.surface_container_low
                        border.color: Theme.outline_variant
                        radius: 4
                    }

                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer

                        ShapePath {
                            strokeColor: Theme.outline
                            strokeWidth: 1.5
                            fillColor: "transparent"
                            startX: plot.px(0); startY: plot.py(0)
                            PathLine { x: plot.px(page.x1); y: plot.py(page.y1) }
                        }
                        ShapePath {
                            strokeColor: Theme.outline
                            strokeWidth: 1.5
                            fillColor: "transparent"
                            startX: plot.px(1); startY: plot.py(1)
                            PathLine { x: plot.px(page.x2); y: plot.py(page.y2) }
                        }
                        ShapePath {
                            strokeColor: Theme.primary
                            strokeWidth: 3
                            fillColor: "transparent"
                            startX: plot.px(0); startY: plot.py(0)
                            PathCubic {
                                control1X: plot.px(page.x1); control1Y: plot.py(page.y1)
                                control2X: plot.px(page.x2); control2Y: plot.py(page.y2)
                                x: plot.px(1); y: plot.py(1)
                            }
                        }
                    }

                    Repeater {
                        model: [[0, 0], [1, 1]]

                        Rectangle {
                            required property var modelData
                            x: plot.px(modelData[0]) - 6
                            y: plot.py(modelData[1]) - 6
                            width: 12
                            height: 12
                            radius: 6
                            color: Theme.outline
                        }
                    }

                    Repeater {
                        model: 2

                        Rectangle {
                            id: handle
                            required property int index
                            x: plot.px(index ? page.x2 : page.x1) - width / 2
                            y: plot.py(index ? page.y2 : page.y1) - height / 2
                            width: drag.active ? 26 : 20
                            height: width
                            radius: width / 2
                            color: index ? Theme.tertiary : Theme.primary
                            border.width: 3
                            border.color: Theme.surface_container
                            Behavior on width { Anim { duration: Theme.animFast } }

                            HoverHandler { cursorShape: Qt.SizeAllCursor }
                            DragHandler {
                                id: drag
                                target: null
                                onCentroidChanged: if (active) plot.move(handle.index, centroid.scenePosition)
                                onActiveChanged: if (!active) page.commit()
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: track
                Layout.fillWidth: true
                implicitHeight: 12
                radius: 6
                color: Theme.surface_container_highest

                Rectangle {
                    id: dot
                    width: 24
                    height: 24
                    radius: 12
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.primary

                    SequentialAnimation on x {
                        id: preview
                        running: page.bezier
                        loops: Animation.Infinite
                        NumberAnimation {
                            from: 0
                            to: track.width - dot.width
                            duration: 900
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: page.spline
                        }
                        PauseAnimation { duration: 500 }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.gap

                Repeater {
                    model: ["x1", "y1", "x2", "y2"]

                    Field {
                        required property string modelData
                        Layout.fillWidth: true
                        implicitHeight: 40
                        text: page[modelData].toFixed(3)
                        validator: DoubleValidator {}
                        Accessible.name: modelData
                        onEditingFinished: {
                            page[modelData] = Number(text)
                            page.commit()
                        }
                    }
                }
            }
        }
    }
}
