import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    implicitWidth: row.implicitWidth + 10
    implicitHeight: 28

    property int cpu: 0
    property int ram: 0
    property real prevIdle: 0
    property real prevTotal: 0

    Process {
        id: proc
        command: ["bash", "-lc", "awk '/^cpu /{idle=$5+$6; total=0; for (i=2; i<=NF; ++i) total+=$i; printf \"cpu %d %d\\n\", idle, total} /^MemTotal:/{memTotal=$2} /^MemAvailable:/{memAvail=$2} END{if (memTotal > 0) printf \"ram %d\\n\", int((memTotal-memAvail)/memTotal*100)}' /proc/stat /proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var l = lines[i]
                    if (l.startsWith("cpu ")) {
                        var parts = l.split(" ")
                        var idle = parseInt(parts[1]) || 0
                        var total = parseInt(parts[2]) || 0
                        if (prevTotal > 0 && total > prevTotal) {
                            var totalDiff = total - prevTotal
                            var idleDiff = idle - prevIdle
                            cpu = Math.max(0, Math.min(100, Math.round((totalDiff - idleDiff) * 100 / totalDiff)))
                        }
                        prevIdle = idle
                        prevTotal = total
                    }
                    if (l.startsWith("ram ")) ram = parseInt(l.split(" ")[1]) || 0
                }
            }
        }
    }

    Timer { interval: 3000; running: true; repeat: true; onTriggered: proc.running = true }
    Component.onCompleted: proc.running = true

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: 8
        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 6
            Text { text: "󰻠"; color: "#c792ea"; font.family: "Maple Mono NF"; font.pixelSize: 13 }
            Text { text: cpu + "%"; color: "#cdd6f4"; font.family: "Maple Mono NF"; font.pixelSize: 13 }
            Text { text: "󰍛"; color: "#c792ea"; font.family: "Maple Mono NF"; font.pixelSize: 13 }
            Text { text: ram + "%"; color: "#cdd6f4"; font.family: "Maple Mono NF"; font.pixelSize: 13 }
        }
    }
}
