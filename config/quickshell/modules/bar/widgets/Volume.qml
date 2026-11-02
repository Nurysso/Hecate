import QtQuick
import qs.config
import qs.components
import qs.services

// Default output: scroll changes volume, click mutes, middle-click opens the control center.
Pill {
    id: root
    widget: "volume"

    visible: !!Audio.sink
    icon: Audio.icon
    label: cfg.percent ?? true ? Math.round(Audio.volume * 100) + "%" : ""
    tooltip: Audio.name(Audio.sink)
    onClicked: Audio.toggleMute()
    onMiddleClicked: GlobalStates.toggle("control", root)

    WheelHandler { onWheel: e => e.angleDelta.y > 0 ? Audio.raise() : Audio.lower() }
}
