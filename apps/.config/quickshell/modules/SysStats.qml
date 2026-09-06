import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../Theme.js" as Theme

Item {
    id: root

    implicitWidth: compact ? 32 : row.implicitWidth + 10
    implicitHeight: 28

    property var barWindow
    property bool compact: false
    property int cpu: 0
    property int ram: 0
    property real ramUsedGiB: 0
    property real ramTotalGiB: 0
    property real prevIdle: 0
    property real prevTotal: 0
    property string host: ""
    property string cpuModel: ""
    property string kernel: ""
    property string loadAverage: ""
    property string temperature: ""
    property int uptimeSeconds: 0
    property real diskUsedGiB: 0
    property real diskTotalGiB: 0
    property int diskPercent: 0

    function parseValues(text) {
        var values = {}
        var lines = text.trim().split("\n")
        for (var i = 0; i < lines.length; i++) {
            var split = lines[i].indexOf("=")
            if (split > 0) values[lines[i].slice(0, split)] = lines[i].slice(split + 1)
        }
        return values
    }

    function formatUptime(seconds) {
        var days = Math.floor(seconds / 86400)
        var hours = Math.floor((seconds % 86400) / 3600)
        var minutes = Math.floor((seconds % 3600) / 60)
        if (days > 0) return days + "d " + hours + "h"
        if (hours > 0) return hours + "h " + minutes + "m"
        return minutes + "m"
    }

    Process {
        id: proc
        command: [Quickshell.env("HOME") + "/.local/bin/device-stats", "sample"]
        stdout: StdioCollector {
            onStreamFinished: {
                var values = root.parseValues(this.text)
                var cpuParts = (values.cpu || "").split(" ")
                var idle = parseInt(cpuParts[0]) || 0
                var total = parseInt(cpuParts[1]) || 0
                if (root.prevTotal > 0 && total > root.prevTotal) {
                    var totalDiff = total - root.prevTotal
                    var idleDiff = idle - root.prevIdle
                    root.cpu = Math.max(0, Math.min(100, Math.round((totalDiff - idleDiff) * 100 / totalDiff)))
                }
                root.prevIdle = idle
                root.prevTotal = total

                var memory = (values.memory || "").split(" ")
                var used = parseInt(memory[0]) || 0
                var totalMemory = parseInt(memory[1]) || 0
                root.ram = totalMemory > 0 ? Math.round(used * 100 / totalMemory) : 0
                root.ramUsedGiB = used / 1048576
                root.ramTotalGiB = totalMemory / 1048576
            }
        }
    }

    Process {
        id: detailsProc
        command: [Quickshell.env("HOME") + "/.local/bin/device-stats", "details"]
        stdout: StdioCollector {
            onStreamFinished: {
                var values = root.parseValues(this.text)
                root.host = values.host || ""
                root.cpuModel = values.model || ""
                root.kernel = values.kernel || ""
                root.loadAverage = values.load || ""
                root.temperature = values.temperature || ""
                root.uptimeSeconds = parseInt(values.uptime) || 0
                var disk = (values.disk || "").split(" ")
                root.diskUsedGiB = (parseInt(disk[0]) || 0) / 1048576
                root.diskTotalGiB = (parseInt(disk[1]) || 0) / 1048576
                root.diskPercent = parseInt(disk[2]) || 0
            }
        }
    }

    Timer { interval: 3000; running: true; repeat: true; onTriggered: proc.running = true }
    Timer { interval: 30000; running: popup.visible; repeat: true; onTriggered: detailsProc.running = true }
    Component.onCompleted: proc.running = true

    Rectangle {
        anchors.fill: parent
        color: mouseArea.containsMouse ? Theme.surfaceHover : "transparent"
        radius: 8
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                popup.visible = !popup.visible
                if (popup.visible) detailsProc.running = true
            }
        }
        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 6
            Text { text: "󰻠"; color: Theme.secondary; font.family: Theme.fontFamily; font.pixelSize: 13 }
            Text { visible: !root.compact; text: root.cpu + "%"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 13 }
            Text { visible: !root.compact; text: "󰍛"; color: Theme.secondary; font.family: Theme.fontFamily; font.pixelSize: 13 }
            Text { visible: !root.compact; text: root.ram + "%"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 13 }
        }
    }

    PopupWindow {
        id: popup
        visible: false
        grabFocus: false
        anchor.window: root.barWindow
        anchor.rect.x: {
            if (!root.barWindow) return 0
            var globalX = root.mapToGlobal(root.width / 2, 0).x
            return Math.max(8, Math.min(globalX - 150, root.barWindow.width - 316))
        }
        anchor.rect.y: root.barWindow ? root.barWindow.implicitHeight : 50
        implicitWidth: 308
        implicitHeight: 250
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: Theme.surface
            radius: 12
            border.color: Qt.rgba(0.306, 0.788, 0.690, 0.15)
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            Text { text: root.host || "This device"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 15; font.bold: true }
            Text {
                Layout.fillWidth: true
                text: root.cpuModel || "Processor unavailable"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: 10
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.fillWidth: true
                Text { text: "CPU"; color: Theme.secondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                Item { Layout.fillWidth: true }
                Text { text: root.cpu + "%" + (root.temperature !== "" ? "  ·  " + root.temperature + "°C" : ""); color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11 }
            }
            Rectangle {
                Layout.fillWidth: true
                height: 5
                radius: 3
                color: Theme.surfaceHover
                Rectangle { width: parent.width * root.cpu / 100; height: parent.height; radius: parent.radius; color: root.cpu >= 90 ? Theme.warning : Theme.secondary }
            }

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Memory"; color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 11 }
                Item { Layout.fillWidth: true }
                Text { text: root.ramUsedGiB.toFixed(1) + " / " + root.ramTotalGiB.toFixed(1) + " GiB"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11 }
            }
            Rectangle {
                Layout.fillWidth: true
                height: 5
                radius: 3
                color: Theme.surfaceHover
                Rectangle { width: parent.width * root.ram / 100; height: parent.height; radius: parent.radius; color: root.ram >= 90 ? Theme.warning : Theme.accent }
            }

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Root storage"; color: Theme.yellow; font.family: Theme.fontFamily; font.pixelSize: 11 }
                Item { Layout.fillWidth: true }
                Text { text: root.diskUsedGiB.toFixed(1) + " / " + root.diskTotalGiB.toFixed(1) + " GiB"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11 }
            }
            Rectangle {
                Layout.fillWidth: true
                height: 5
                radius: 3
                color: Theme.surfaceHover
                Rectangle { width: parent.width * root.diskPercent / 100; height: parent.height; radius: parent.radius; color: root.diskPercent >= 90 ? Theme.warning : Theme.yellow }
            }

            Text { text: "Load  " + (root.loadAverage || "unavailable"); color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 11 }
            Text { text: "Uptime  " + root.formatUptime(root.uptimeSeconds); color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 11 }
            Text { text: "Kernel  " + (root.kernel || "unavailable"); color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 11 }
        }
    }
}
