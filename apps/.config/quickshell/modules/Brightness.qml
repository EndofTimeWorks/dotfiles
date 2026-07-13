import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    implicitWidth: row.implicitWidth + 10
    implicitHeight: 28

    property var barWindow
    property int brightness: 50
    property real dim: 0.0
    property var setDimFn

    function refreshStatus() {
        if (!brightnessSlider.pressed && !dimSlider.pressed && !setProc.running && !setDimProc.running)
            proc.running = true
    }

    Process {
        id: proc
        command: ["bash", "-lc", "~/.local/bin/display-brightness status"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n")
                var nextBrightness = brightness
                var nextDim = dim
                for (var i = 0; i < lines.length; i++) {
                    var l = lines[i]
                    if (l.startsWith("brightness=")) nextBrightness = parseInt(l.slice(11)) || 0
                    if (l.startsWith("dim=")) nextDim = parseFloat(l.slice(4)) || 0
                }
                brightness = nextBrightness
                dim = nextDim
            }
        }
    }

    Timer { interval: 2000; running: true; repeat: true; onTriggered: refreshStatus() }
    Component.onCompleted: proc.running = true

    Process {
        id: setProc
        command: ["bash", "-lc", "~/.local/bin/display-brightness set-brightness " + brightness]
        onExited: refreshStatus()
    }

    Process {
        id: setDimProc
        command: ["bash", "-lc", "~/.local/bin/display-brightness set-dim " + dim.toFixed(2)]
        onExited: refreshStatus()
    }

    Timer {
        id: brightnessWriteTimer
        interval: 50
        repeat: false
        onTriggered: {
            if (setProc.running) restart()
            else setProc.running = true
        }
    }

    Timer {
        id: dimWriteTimer
        interval: 50
        repeat: false
        onTriggered: {
            if (setDimProc.running) restart()
            else setDimProc.running = true
        }
    }

    Rectangle {
        anchors.fill: parent
        color: ma.containsMouse ? "#141628" : "transparent"
        radius: 8

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            onClicked: popup.visible = !popup.visible
        }

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 4
            Text { text: "󰃟"; color: "#fac863"; font.family: "Maple Mono NF"; font.pixelSize: 14 }
            Text { text: brightness + "%"; color: "#cdd6f4"; font.family: "Maple Mono NF"; font.pixelSize: 13 }
        }
    }

    PopupWindow {
        id: popup
        visible: false
        grabFocus: false
        anchor.window: barWindow
        anchor.rect.x: {
            if (!barWindow) return 0
            var gx = parent.mapToGlobal(parent.width / 2, 0).x
            return Math.max(8, Math.min(gx - 8 - 110, barWindow.width - 220 - 8))
        }
        anchor.rect.y: barWindow ? barWindow.implicitHeight : 50
        implicitWidth: 220
        implicitHeight: 175
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "#0f1120"
            radius: 10
            border.color: Qt.rgba(0.306, 0.788, 0.690, 0.15)
            border.width: 1
        }

        Column {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            spacing: 10

            Row {
                spacing: 6
                Text { text: "󰃟"; color: "#fac863"; font.family: "Maple Mono NF"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "Backlight " + brightness + "%"; color: "#cdd6f4"; font.family: "Maple Mono NF"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
            }

            Slider {
                id: brightnessSlider
                width: parent.width
                from: 1
                to: 100
                value: brightness
                onMoved: {
                    brightness = Math.round(value)
                    brightnessWriteTimer.restart()
                }
            }

            Row {
                spacing: 6
                Text { text: "󰌁"; color: "#7f849c"; font.family: "Maple Mono NF"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "Dim " + Math.round(dim * 100) + "%"; color: "#cdd6f4"; font.family: "Maple Mono NF"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
            }

            Slider {
                id: dimSlider
                width: parent.width
                from: 0
                to: 1
                value: dim
                onMoved: {
                    dim = value
                    dimWriteTimer.restart()
                    if (setDimFn) setDimFn(value)
                }
            }
        }
    }
}
