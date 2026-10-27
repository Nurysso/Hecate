import QtQuick
import QtQuick.Shapes
import qs.config

// Circular progress, drawn clockwise from 12 o'clock; value is 0..1.
Shape {
    id: root
    property real value
    property real thickness: 6
    property color color: Theme.primary
    property color track: Theme.surface_container_highest
    property real shown: Math.max(0, Math.min(value, 1))
    readonly property real r: (Math.min(width, height) - thickness) / 2

    preferredRendererType: Shape.CurveRenderer
    Behavior on shown { Anim {} }

    ShapePath {
        fillColor: "transparent"
        strokeColor: root.track
        strokeWidth: root.thickness
        PathAngleArc { centerX: root.width / 2; centerY: root.height / 2; radiusX: root.r; radiusY: root.r; sweepAngle: 360 }
    }

    ShapePath {
        fillColor: "transparent"
        strokeColor: root.shown > 0.005 ? root.color : "transparent"
        strokeWidth: root.thickness
        capStyle: ShapePath.RoundCap
        PathAngleArc {
            centerX: root.width / 2; centerY: root.height / 2; radiusX: root.r; radiusY: root.r
            startAngle: -90
            sweepAngle: 360 * root.shown
        }
    }
}
