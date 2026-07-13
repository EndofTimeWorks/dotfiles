import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    implicitWidth: visible ? row.implicitWidth + 10 : 0
    implicitHeight: 28
    visible: weatherText !== ""

    property string weatherText: ""
    property string unit: "m"

    Process {
        id: proc
        command: ["bash", "-lc", "~/.local/bin/location-info weather " + unit]
        stdout: StdioCollector {
            onStreamFinished: {
                weatherText = this.text.trim().replace(/\s+/g, "").replace(/\+(\d)/g, "$1")
            }
        }
    }

    Timer { interval: 1800000; running: true; repeat: true; onTriggered: proc.running = true }
    Component.onCompleted: proc.running = true

    Rectangle {
        anchors.fill: parent
        color: ma.containsMouse ? "#141628" : "transparent"
        radius: 8
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                unit = unit === "m" ? "u" : "m"
                proc.running = true
            }
        }
        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 4
            Text { text: weatherText; color: "#cdd6f4"; font.family: "Maple Mono NF"; font.pixelSize: 13 }
        }
    }
}
