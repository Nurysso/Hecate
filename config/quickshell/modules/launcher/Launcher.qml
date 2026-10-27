import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components

Panel {
    id: root
    name: "launcher"

    ColumnLayout {
        width: 560
        height: 520
        spacing: Theme.gap * 1.5

        SearchField {
            id: search
            Layout.fillWidth: true
            placeholderText: "Search apps"
            focus: true
            Keys.onDownPressed: list.incrementCurrentIndex()
            Keys.onUpPressed: list.decrementCurrentIndex()
            onAccepted: list.currentItem?.clicked()
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            highlightMoveDuration: Theme.animFast
            highlight: Rectangle { radius: Theme.radiusSmall; color: Theme.secondary_container }
            model: ScriptModel {
                onValuesChanged: list.currentIndex = 0
                values: {
                    const q = search.text.toLowerCase()
                    const hit = a => `${a.name} ${a.genericName} ${a.keywords.join(" ")}`.toLowerCase().includes(q)
                    const starts = a => a.name.toLowerCase().startsWith(q)
                    return DesktopEntries.applications.values
                        .filter(a => !a.noDisplay && hit(a))
                        .sort((a, b) => starts(b) - starts(a) || a.name.localeCompare(b.name))
                }
            }

            delegate: Tile {
                required property DesktopEntry modelData
                width: ListView.view.width
                image: Quickshell.iconPath(modelData.icon, true)
                icon: Theme.icon.apps
                title: modelData.name
                subtitle: modelData.genericName || modelData.comment
                onClicked: {
                    modelData.execute()
                    GlobalStates.panel = ""
                }
            }

            add: Transition { Anim { property: "opacity"; from: 0; to: 1 } }
            displaced: Displaced {}
        }
    }
}
