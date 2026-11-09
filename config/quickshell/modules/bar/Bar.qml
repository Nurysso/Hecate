import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.components

// A bar on each monitor ([bar] monitors picks which). Widgets come from [bar] left, center and right;
// "foo" loads widgets/Foo.qml. style = "islands" puts each section on its own glass, "floating" draws
// one rounded bar, "full" runs edge to edge.
Variants {
    model: Quickshell.screens.filter(s => !Config.bar.monitors.length || Config.bar.monitors.includes(s.name))

    PanelWindow {
        id: bar
        required property ShellScreen modelData
        readonly property bool islands: Config.bar.style === "islands"
        readonly property var glass: islands ? [left, center, right] : [base]

        screen: modelData
        anchors { top: !Theme.barBottom; bottom: Theme.barBottom; left: true; right: true }
        implicitHeight: Theme.barExtent
        color: "transparent"
        WlrLayershell.namespace: "hecate-bar"
        // held back until the bar has half faded in, or the blur would show before the glass
        readonly property bool faded: frame.opacity > 0.5   // flips once, so the region isn't rebuilt every frame of the fade
        BackgroundEffect.blurRegion: Region { regions: Theme.blur && bar.faded ? bar.glass.filter(g => g.glass).map(g => g.blur) : [] }

        // Widgets are created straight into the row (not through Loaders), so one that hides itself
        // leaves no gap. Only a change to this section's list rebuilds it.
        // A section with nothing to show collapses rather than hiding: a hidden parent makes its children
        // read as hidden too, and it would never come back.
        component Section: Glass {
            id: section
            property var names: []
            property string built
            readonly property bool shown: row.visibleChildren.length > 0

            glass: bar.islands && shown
            radius: Theme.radius
            implicitWidth: shown ? row.implicitWidth + Theme.barInset * 2 : 0
            width: implicitWidth
            height: parent.height
            opacity: shown ? 1 : 0
            Behavior on width { Anim {} }
            Behavior on opacity { Anim {} }

            onNamesChanged: build()
            Component.onCompleted: build()
            function build() {
                const key = JSON.stringify(names)
                if (key === built) return
                built = key
                for (const c of row.children) c.destroy()
                for (const n of names) {
                    const c = Qt.createComponent(Qt.resolvedUrl(`widgets/${n[0].toUpperCase()}${n.slice(1)}.qml`))
                    if (c.status === Component.Ready) c.createObject(row)
                    else console.warn(`hecate.toml: bar widget "${n}" not loaded: ${c.errorString()}`)
                }
            }

            Row {
                id: row
                anchors.centerIn: parent
                spacing: Theme.px(2)
                move: Transition { Anim { property: "x" } }
            }
        }

        // Keep awake (caffeine): the bar is always mapped, so it holds the inhibitor
        IdleInhibitor { window: bar; enabled: GlobalStates.caffeine }

        // A click on an empty part of the bar closes the open panel
        MouseArea { anchors.fill: parent; onClicked: GlobalStates.close() }

        Item {
            id: frame
            anchors.fill: parent
            anchors.topMargin: Theme.barBottom ? 0 : Theme.barMargin
            anchors.bottomMargin: Theme.barBottom ? Theme.barMargin : 0
            anchors.leftMargin: Theme.barMargin
            anchors.rightMargin: Theme.barMargin
            opacity: Theme.behindReveal ? 1 : 0
            Component.onCompleted: opacity = 1
            Behavior on opacity { Anim { duration: Theme.ms(900); easing.type: Easing.InOutQuad } }

            Glass {
                id: base
                anchors.fill: parent
                glass: !bar.islands
                radius: Config.bar.style === "full" ? 0 : Theme.radius
            }

            Section { id: left; names: Config.ready ? Config.bar.left : []; anchors.left: parent.left }
            Section { id: center; names: Config.ready ? Config.bar.center : []; anchors.horizontalCenter: parent.horizontalCenter }
            Section { id: right; names: Config.ready ? Config.bar.right : []; anchors.right: parent.right }
        }
    }
}
