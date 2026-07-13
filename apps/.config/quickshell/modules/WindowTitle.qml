import Quickshell.Io
import QtQuick

Item {
    implicitWidth: visible ? 190 : 0
    implicitHeight: 32
    visible: title !== ""
    clip: true

    property string title: ""

    Process {
        id: proc
        command: ["niri", "msg", "--json", "focused-window"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var w = JSON.parse(this.text)
                    title = w ? (w.title || w.app_id || "") : ""
                } catch (e) {
                    title = ""
                }
            }
        }
    }

    Timer { interval: 1000; running: true; repeat: true; onTriggered: proc.running = true }
    Component.onCompleted: proc.running = true

    Text {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        text: title
        color: "#7f849c"
        font.family: "Maple Mono NF"
        font.pixelSize: 13
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }
}
