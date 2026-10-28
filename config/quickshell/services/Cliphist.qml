pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Entries are raw `cliphist list` lines: "<id>\t<preview>". Passed as argv, never interpolated.
Singleton {
    id: root
    property list<string> entries: []

    function refresh() { lister.running = true }
    function copy(entry) { Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", entry.split("\t")[0]]) }
    function remove(entry) { mutate.exec(["sh", "-c", 'printf "%s" "$1" | cliphist delete', "sh", entry]) }
    function wipe() { mutate.exec(["cliphist", "wipe"]) }

    Process {
        id: lister
        command: ["cliphist", "list"]
        stdout: StdioCollector { onStreamFinished: root.entries = text.split("\n").filter(l => l) }
    }

    Process { id: mutate; onExited: root.refresh() }
}
