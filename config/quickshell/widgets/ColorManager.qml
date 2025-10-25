pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: manager

    // Color properties
    property string primaryColor: "#4B9EEA"
    property string accentColor: "#c8c4cb"
    property string mutedColor: "#716379"
    property string warningColor: "#E5A564"
    property string criticalColor: "#E55564"
    property string successColor: "#85E564"
    property string magentaColor: "#475DD4"
    property string cyanColor: "#4B9EEA"
    property string greenColor: "#85E564"

    property bool loaded: false
    property string cssPath: Quickshell.env("HOME") + "/.config/hecate/hecate.css"

    Component.onCompleted: {
        console.log("ColorManager: Initializing...")
        colorReader.running = true
    }

    // CSS reader process
    property Process colorReader: Process {
        id: colorReader
        command: ["cat", manager.cssPath]
        running: false
        property string cssContent: ""

        stdout: SplitParser {
            onRead: data => {
                colorReader.cssContent += data
            }
        }

        onRunningChanged: {
            if (!running && cssContent) {
                console.log("ColorManager: CSS loaded, parsing colors...")

                const cyanMatch = cssContent.match(/@define-color cyan (#[0-9A-Fa-f]{6});/)
                const magentaMatch = cssContent.match(/@define-color magenta (#[0-9A-Fa-f]{6});/)
                const fgMatch = cssContent.match(/@define-color foreground (#[0-9A-Fa-f]{6});/)
                const mutedMatch = cssContent.match(/@define-color muted (#[0-9A-Fa-f]{6});/)
                const greenMatch = cssContent.match(/@define-color green (#[0-9A-Fa-f]{6});/)

                if (cyanMatch) {
                    manager.cyanColor = cyanMatch[1]
                    manager.primaryColor = cyanMatch[1]
                    console.log("ColorManager: cyan =", cyanMatch[1])
                }
                if (magentaMatch) {
                    manager.magentaColor = magentaMatch[1]
                    manager.accentColor = magentaMatch[1]
                    console.log("ColorManager: magenta =", magentaMatch[1])
                }
                if (fgMatch) {
                    manager.accentColor = fgMatch[1]
                    console.log("ColorManager: foreground =", fgMatch[1])
                }
                if (mutedMatch) {
                    manager.mutedColor = mutedMatch[1]
                    console.log("ColorManager: muted =", mutedMatch[1])
                }
                if (greenMatch) {
                    manager.greenColor = greenMatch[1]
                    manager.successColor = greenMatch[1]
                    console.log("ColorManager: green =", greenMatch[1])
                }

                manager.loaded = true
                cssContent = ""
                console.log("ColorManager: Colors loaded successfully")
            }
        }
    }

    // Reload timer
    property Timer reloadTimer: Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: false
        onTriggered: {
            console.log("ColorManager: Reloading colors...")
            colorReader.running = true
        }
    }

    // Manual reload function
    function reload() {
        console.log("ColorManager: Manual reload triggered")
        colorReader.running = true
    }
}
