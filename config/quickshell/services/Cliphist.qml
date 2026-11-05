pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Entries are raw `cliphist list` lines: "<id>\t<preview>". Passed as argv, never interpolated.
// Images are decoded once into ~/.cache/hecate/cliphist/<id> for thumbnails; ones no longer in the
// history are cleared out on refresh.
Singleton {
    id: root
    property list<string> entries: []
    // id -> file name, for images whose name was recorded (screenshots); see ScreenShot.sh
    property var names: ({})
    readonly property string thumbs: Config.home + "/.cache/hecate/cliphist"

    function id(entry) { return entry.split("\t")[0] }
    function thumb(entry) { return `${thumbs}/${id(entry)}` }

    function name(entry) { return names[id(entry)] ?? "" }
    function refresh() { lister.running = true }
    function copy(entry) { Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", id(entry)]) }
    function remove(entry) { mutate.exec(["sh", "-c", 'printf "%s" "$1" | cliphist delete; rm -f "$2"', "sh", entry, thumb(entry)]) }
    function wipe() { mutate.exec(["sh", "-c", 'cliphist wipe; rm -rf "$1"', "sh", thumbs]) }

    Process {
        id: lister
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = text.split("\n").filter(l => l)
                prune.exec(["sh", "-c", 'dir=$1; shift; keep=" $* "; for f in "$dir"/*; do [ -e "$f" ] || continue; case "$keep" in *" ${f##*/} "*) ;; *) rm -f "$f" ;; esac; done',
                    "sh", root.thumbs, ...root.entries.map(e => root.id(e))])
                namer.exec(["sh", "-c", 'for i; do h=$(cliphist decode "$i" 2>/dev/null | sha1sum | cut -d" " -f1); n=$(cat "$HOME/.cache/hecate/clipnames/$h" 2>/dev/null) && printf "%s\\t%s\\n" "$i" "$n"; done',
                    "sh", ...root.entries.filter(e => e.includes("[[ binary data")).map(e => root.id(e))])
            }
        }
    }

    Process {
        id: namer
        stdout: StdioCollector {
            onStreamFinished: {
                const m = {}
                for (const l of text.split("\n")) { const [i, n] = l.split("\t"); if (i && n) m[i] = n }
                root.names = m
            }
        }
    }

    Process { id: mutate; onExited: root.refresh() }
    Process { id: prune }
}
