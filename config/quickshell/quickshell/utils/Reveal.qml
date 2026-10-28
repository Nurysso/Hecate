pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    // total length of the whole reveal, in ms
    // (last widget's delay + its span, see usage below)
    property real total: 1400
    property real t: 0   // 0 -> 1 over `total` ms

    NumberAnimation {
        id: anim
        target: root
        property: "t"
        from: 0
        to: 1
        duration: root.total
    }

    // tiny delay so the first frame renders fully hidden
    Timer {
        interval: 50
        running: true
        onTriggered: anim.start()
    }

    // 0..1 progress for a widget that starts at `delay` ms and takes `span` ms
    function fade(delay, span) {
        const x = Math.max(0, Math.min(1, (t * total - delay) / span))
        return 1 - Math.pow(1 - x, 3)   // ease-out cubic
    }
}
