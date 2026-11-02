pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// emojis.tsv parsed once, not on every open: one "<emoji>\t<name>\t<keywords>" per line (from the Unicode
// CLDR names). The last 24 picks are kept in ~/.cache/hecate/emoji.json and listed first.
Singleton {
    id: root

    property var all: []
    property list<string> recent: []

    function pick(e) {
        Quickshell.execDetached(["wl-copy", "--", e.char])
        recent = [e.char, ...recent.filter(c => c !== e.char)].slice(0, 24)
        store.setText(JSON.stringify(recent))
    }

    FileView {
        path: Quickshell.shellPath("modules/emoji/emojis.tsv")
        printErrors: false
        onLoaded: root.all = text().split("\n").filter(l => l).map(l => {
            const f = l.split("\t")
            return { char: f[0], name: f[1], search: (f[1] + " " + f[2]).toLowerCase() }
        })
    }

    FileView {
        id: store
        path: Config.home + "/.cache/hecate/emoji.json"
        printErrors: false
        onLoaded: { try { root.recent = JSON.parse(text()) } catch (e) {} }
    }
}
