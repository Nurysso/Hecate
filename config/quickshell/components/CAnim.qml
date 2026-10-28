import QtQuick
import qs.config

ColorAnimation {
    duration: Theme.anim
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Theme.curve
}
