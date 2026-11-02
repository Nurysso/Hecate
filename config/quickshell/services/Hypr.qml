pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.config

// Hyprland beyond what Quickshell tracks for us: dispatching in either config language, the submap,
// keyboard layouts, open special workspaces, game mode, and the layer rules the shell's surfaces need.
// State comes from one hyprctl query at start and on config reload, then from socket events.
Singleton {
    id: root

    property string submap: ""
    property list<string> layouts: []      // input:kb_layout, e.g. ["us", "de"]
    property int layoutIndex: 0            // active layout of the main keyboard
    property var specials: ({})            // output → name of its open special workspace ("" when none)
    readonly property string layout: layouts[layoutIndex] ?? ""

    // Lua configs take hl.dsp.* expressions, hyprlang configs the classic dispatcher strings
    function dispatch(lua, classic) { Hyprland.dispatch(Hyprland.usingLua ? lua : classic) }
    function focusWorkspace(id) { dispatch(`hl.dsp.focus({ workspace = "${id}" })`, `workspace ${id}`) }
    function toggleSpecial(name) { dispatch(`hl.dsp.workspace.toggle_special(${JSON.stringify(name)})`, `togglespecialworkspace ${name}`) }
    function resetSubmap() { dispatch(`hl.dsp.submap("reset")`, "submap reset") }
    function nextLayout() { Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"]) }

    // Animations, blur, shadows, gaps and rounding off for games; Hyprland's own config brings them back
    function setGamemode(on) {
        if (!Hyprland.usingLua) return
        GlobalStates.gamemode = on
        if (on) run.exec(["hyprctl", "eval", "hl.config({ animations = { enabled = false }, decoration = { blur = { enabled = false }, "
            + "shadow = { enabled = false }, rounding = 0 }, general = { gaps_in = 0, gaps_out = 0 } })"])
        else run.exec(["hyprctl", "reload", "config-only"])
    }

    // The shell animates its own surfaces, so Hyprland's layer animations would play on top of them.
    // Rules made with hyprctl eval vanish on config reload, so they're made again then.
    function applyRules() {
        if (Hyprland.usingLua) rules.exec(["hyprctl", "eval", 'hl.layer_rule({ name = "hecate-shell", match = { namespace = "^hecate-" }, no_anim = true })'])
    }

    function refresh() { query.running = true }

    Process {
        id: query
        running: true
        command: ["sh", "-c", "hyprctl -j getoption input:kb_layout; echo; hyprctl -j devices; echo; hyprctl -j monitors"]
        stdout: StdioCollector {
            onStreamFinished: {
                // three JSON documents, one after the other
                const docs = text.split(/\n(?=[\[{])/).map(s => { try { return JSON.parse(s) } catch (e) { return null } })
                const [option, devices, monitors] = docs
                if (option) root.layouts = String(option.str ?? "").split(",").map(s => s.trim()).filter(s => s)
                const kb = devices?.keyboards?.find(k => k.main) ?? devices?.keyboards?.[0]
                if (kb) root.layoutIndex = kb.active_layout_index ?? 0
                if (monitors) {
                    const s = {}
                    for (const m of monitors) s[m.name] = (m.specialWorkspace?.name ?? "").replace(/^special:/, "")
                    root.specials = s
                }
            }
        }
    }

    // hyprctl answers "ok", or reports what went wrong on stdout
    Process {
        id: rules
        stdout: StdioCollector { onStreamFinished: if (text.trim() !== "ok") console.warn("hecate: layer rules not applied: " + text.trim()) }
    }
    Process {
        id: run
        stdout: StdioCollector { onStreamFinished: if (text.trim() !== "ok") console.warn("hecate: " + text.trim()) }
        onExited: Theme.refreshGaps()   // the bar's margin follows gaps_out
    }

    Connections {
        target: Hyprland
        // usingLua turns true a moment after start, once the Hyprland module has connected
        function onUsingLuaChanged() { root.applyRules() }
        function onRawEvent(event) {
            const d = event.data
            switch (event.name) {
            case "submap": root.submap = d; break
            case "activelayout": {
                // "<keyboard>,<layout name>": names aren't codes, so ask which index is active now
                root.refresh()
                break
            }
            case "activespecial": {
                const i = d.lastIndexOf(",")
                root.specials = Object.assign({}, root.specials, { [d.slice(i + 1)]: d.slice(0, i).replace(/^special:/, "") })
                break
            }
            case "configreloaded":
                GlobalStates.gamemode = false
                root.refresh()
                root.applyRules()
                Theme.refreshGaps()
                break
            }
        }
    }
}
