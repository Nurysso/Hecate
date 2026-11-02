pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The MPRIS player the shell shows and the media keys control: whichever is playing,
// else the one that played last, else the first one around.
Singleton {
    id: root

    property MprisPlayer last: null
    readonly property var all: Mpris.players.values
    readonly property MprisPlayer active: all.find(p => p.isPlaying) ?? (all.includes(last) ? last : all[0]) ?? null
    readonly property bool playing: active?.isPlaying ?? false

    onActiveChanged: if (active?.isPlaying) last = active

    function control(action) {
        const p = active
        if (!p) return
        if (action === "play-pause" && p.canTogglePlaying) p.togglePlaying()
        else if (action === "next" && p.canGoNext) p.next()
        else if (action === "previous" && p.canGoPrevious) p.previous()
        else if (action === "stop") p.stop()
    }

    function time(sec) {
        const s = Math.max(0, Math.floor(sec))
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
    }
}
