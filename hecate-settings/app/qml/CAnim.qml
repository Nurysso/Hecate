import QtQuick
import com.hecate.settings

ColorAnimation {
    duration: Theme.anim
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Theme.curve
}
