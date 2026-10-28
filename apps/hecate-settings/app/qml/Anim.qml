import QtQuick
import com.hecate.settings

NumberAnimation {
    duration: Theme.anim
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Theme.curve
}
