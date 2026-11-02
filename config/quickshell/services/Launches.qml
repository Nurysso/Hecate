pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// How often and how recently each app was started from the launcher, so the ones you use come first.
// Kept in ~/.cache/hecate/launches.json as desktop entry id → { n: launches, t: last launch in seconds }.
Singleton {
    id: root

    property var counts: ({})

    function launch(entry) {
        entry.execute()
        const e = counts[entry.id] ?? { n: 0, t: 0 }
        counts = Object.assign({}, counts, { [entry.id]: { n: e.n + 1, t: Math.floor(Date.now() / 1000) } })
        store.setText(JSON.stringify(counts))
    }

    // Launches, each worth half as much for every week since the last one
    function score(id) {
        const e = counts[id]
        return e ? e.n * Math.pow(0.5, (Date.now() / 1000 - e.t) / 604800) : 0
    }

    FileView {
        id: store
        path: Config.home + "/.cache/hecate/launches.json"
        printErrors: false
        onLoaded: { try { root.counts = JSON.parse(text()) } catch (e) {} }
    }
}
