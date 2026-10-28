pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// CPU, memory, GPU and disk readings from /proc and sysfs, shared by the bar and the desktop.
// Temperatures are °C and sizes bytes; NaN means the sensor isn't there.
Singleton {
    id: root

    property string cpuName: "CPU"
    property real cpu
    property var cores: []
    property real ghz
    property real memUsed
    property real memTotal: 1
    property real uptime
    property real disk
    property real diskUsed
    property real diskSize
    readonly property real mem: memUsed / memTotal
    readonly property real cpuTemp: cpuTempFile.value / 1000
    readonly property bool hasGpu: gpuDir !== ""
    readonly property real gpu: (gpuBusy.value || 0) / 100
    readonly property real gpuTemp: gpuTempFile.value / 1000
    readonly property real gpuPower: gpuPowerFile.value / 1e6
    readonly property real gpuFan: gpuFanFile.value
    readonly property real vramUsed: vramUsedFile.value
    readonly property real vramTotal: vramTotalFile.value

    property string cpuTempPath
    property string gpuDir      // /sys/class/drm/cardN/device
    property string gpuHwmon
    property var prevStat: []

    // Finds sensors once: hwmon numbering and the DRM card index change between boots
    Process {
        running: true
        command: ["sh", "-c", `
            for h in /sys/class/hwmon/hwmon*; do
                case $(cat $h/name) in
                    k10temp|zenpower|coretemp) echo "cputemp $h/temp1_input" ;;
                esac
            done
            for d in /sys/class/drm/card*/device; do
                [ -r $d/gpu_busy_percent ] || continue
                echo "gpu $d"; echo "gpuhwmon $(echo $d/hwmon/hwmon*)"; break
            done
            echo "cpuname $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2)"`]
        stdout: SplitParser {
            onRead: line => {
                const [key, ...rest] = line.split(" ")
                const v = rest.join(" ").trim()
                if (key === "cputemp" && !root.cpuTempPath) root.cpuTempPath = v
                else if (key === "gpu") root.gpuDir = v
                else if (key === "gpuhwmon") root.gpuHwmon = v
                else if (key === "cpuname") root.cpuName = v.replace(/\(R\)|\(TM\)|CPU|Processor|\d+-Core/gi, "").replace(/\s+/g, " ").trim()
            }
        }
    }

    component Probe: FileView {
        property real value: NaN
        printErrors: false
        onLoaded: value = parseFloat(text())
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const rows = text().split("\n").filter(l => l.startsWith("cpu")).map(l => {
                const n = l.split(/\s+/).slice(1).map(Number)
                return { total: n.reduce((a, b) => a + b, 0), idle: n[3] + n[4] }
            })
            const prev = root.prevStat
            const usage = rows.map((r, i) => {
                const p = prev[i]
                if (!p || r.total === p.total) return 0
                return 1 - (r.idle - p.idle) / (r.total - p.total)
            })
            root.prevStat = rows
            root.cpu = usage[0]
            root.cores = usage.slice(1)
        }
    }
    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const kb = k => Number(text().match(new RegExp(`^${k}:\\s+(\\d+)`, "m"))?.[1] ?? 0) * 1024
            root.memTotal = kb("MemTotal") || 1
            root.memUsed = root.memTotal - kb("MemAvailable")
        }
    }
    FileView {
        id: cpuinfo
        path: "/proc/cpuinfo"
        onLoaded: {
            const mhz = (text().match(/^cpu MHz\s*:\s*[\d.]+/gm) ?? []).map(l => Number(l.split(":")[1]))
            root.ghz = mhz.length ? Math.max(...mhz) / 1000 : 0
        }
    }
    FileView { id: uptimeFile; path: "/proc/uptime"; onLoaded: root.uptime = parseFloat(text()) }

    Probe { id: cpuTempFile; path: root.cpuTempPath }
    Probe { id: gpuBusy; path: root.hasGpu ? root.gpuDir + "/gpu_busy_percent" : "" }
    Probe { id: vramUsedFile; path: root.hasGpu ? root.gpuDir + "/mem_info_vram_used" : "" }
    Probe { id: vramTotalFile; path: root.hasGpu ? root.gpuDir + "/mem_info_vram_total" : "" }
    Probe { id: gpuTempFile; path: root.gpuHwmon ? root.gpuHwmon + "/temp1_input" : "" }
    Probe { id: gpuPowerFile; path: root.gpuHwmon ? root.gpuHwmon + "/power1_average" : "" }
    Probe { id: gpuFanFile; path: root.gpuHwmon ? root.gpuHwmon + "/fan1_input" : "" }

    Timer {
        running: true
        repeat: true
        triggeredOnStart: true
        interval: 2000
        onTriggered: [stat, meminfo, cpuinfo, uptimeFile, cpuTempFile, gpuBusy, vramUsedFile, gpuTempFile, gpuPowerFile, gpuFanFile]
            .forEach(f => { if (f.path) f.reload() })
    }

    Process {
        id: df
        running: true
        command: ["df", "-B1", "--output=used,size", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [used, size] = text.trim().split("\n").pop().trim().split(/\s+/).map(Number)
                root.diskUsed = used
                root.diskSize = size
                root.disk = used / size
            }
        }
    }
    Timer { running: true; repeat: true; interval: 60000; onTriggered: df.running = true }
}
