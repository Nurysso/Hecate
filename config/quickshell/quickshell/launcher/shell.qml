import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

PanelWindow {
    id: launcherWindow

    // Layer-shell setup
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-launcher"

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    property var appList: []

    // Fetch installed applications via standard desktop entry query
    Process {
        id: appScanner
        command: ["sh", "-c", "python3 -c \"
import pkg_resources, os, glob
paths = ['/usr/share/applications/*.desktop', os.path.expanduser('~/.local/share/applications/*.desktop')]
apps = []
for p in paths:
    for f in glob.glob(p):
        name, exec_cmd, icon = '', '', ''
        with open(f, 'r', errors='ignore') as file:
            for line in file:
                if line.startswith('Name=') and not name: name = line.split('=', 1)[1].strip()
                if line.startswith('Exec=') and not exec_cmd: exec_cmd = line.split('=', 1)[1].strip().split('%')[0]
                if line.startswith('Icon=') and not icon: icon = line.split('=', 1)[1].strip()
        if name and exec_cmd: apps.append({'name': name, 'exec': exec_cmd, 'icon': icon})
import json; print(json.dumps(apps))
\""]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    launcherWindow.appList = JSON.parse(data)
                } catch(e) {}
            }
        }
    }

    // Dismiss on background click
    MouseArea {
        anchors.fill: parent
        onClicked: launcherWindow.visible = false
    }

    // Main Card
    Rectangle {
        width: 480; height: 500
        anchors.centerIn: parent
        radius: 12
        color: Qt.rgba(0.1, 0.1, 0.12, 0.95)
        border.color: Qt.rgba(1, 1, 1, 0.1)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Search Bar
            TextField {
                id: searchInput
                Layout.fillWidth: true
                placeholderText: "Search applications..."
                focus: true
                onTextChanged: appListFiltered.rebind()

                Keys.onEscapePressed: launcherWindow.visible = false
                Keys.onDownPressed: listView.incrementCurrentIndex()
                Keys.onUpPressed: listView.decrementCurrentIndex()
                Keys.onReturnPressed: {
                    if (listView.currentItem) listView.currentItem.launch()
                }
            }

            // Results List
            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                model: appList.filter(app =>
                    app.name.toLowerCase().includes(searchInput.text.toLowerCase())
                )

                delegate: ItemDelegate {
                    width: listView.width
                    height: 40

                    function launch() {
                        Process.startDetached(["sh", "-c", modelData.exec])
                        launcherWindow.visible = false
                    }

                    onClicked: launch()

                    contentItem: RowLayout {
                        spacing: 10
                        Text {
                            text: modelData.name
                            color: "#ffffff"
                            font.pixelSize: 14
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }
}
