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

    Process {
        id: proc
        command: ["/home/end/.local/bin/display-brightness", "status"]
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

    Timer { interval: 2000; running: true; repeat: true; onTriggered: proc.running = true }
    Component.onCompleted: proc.running = true

    Process {
        id: setProc
        command: ["/home/end/.local/bin/display-brightness", "set-brightness", brightness + ""]
    }

    Process {
        id: setDimProc
        command: ["/home/end/.local/bin/display-brightness", "set-dim", dim.toFixed(2)]
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
        grabFocus: true
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
                width: parent.width
                from: 1
                to: 100
                value: brightness
                onMoved: {
                    brightness = Math.round(value)
                    setProc.running = true
                    proc.running = true
                }
            }

            Row {
                spacing: 6
                Text { text: "󰌁"; color: "#7f849c"; font.family: "Maple Mono NF"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "Dim " + Math.round(dim * 100) + "%"; color: "#cdd6f4"; font.family: "Maple Mono NF"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
            }

            Slider {
                width: parent.width
                from: 0
                to: 1
                value: dim
                onMoved: {
                    dim = value
                    setDimProc.running = true
                    if (setDimFn) setDimFn(value)
                    proc.running = true
                }
            }
        }
    }
}
