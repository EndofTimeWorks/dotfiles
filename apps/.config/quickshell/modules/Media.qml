import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    implicitWidth: visible ? 170 : 0
    implicitHeight: 28
    visible: mediaText !== ""
    clip: true

    property string mediaText: ""

    Process {
        id: proc
        command: ["playerctl", "metadata", "--format", "{{artist}} — {{title}}"]
        stdout: StdioCollector {
            onStreamFinished: mediaText = this.text.trim()
        }
        onExited: (code, status) => { if (code !== 0) mediaText = "" }
    }

    Timer { interval: 3000; running: true; repeat: true; onTriggered: proc.running = true }
    Component.onCompleted: proc.running = true

    Rectangle {
        anchors.fill: parent
        color: ma.containsMouse ? "#141628" : "transparent"
        radius: 8

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton) skipProc.running = true
                else playPauseProc.running = true
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 6

            Text {
                text: "󰎈"
                color: "#4ec9b0"
                font.family: "Maple Mono NF"
                font.pixelSize: 14
            }

            Text {
                Layout.fillWidth: true
                text: mediaText
                color: "#cdd6f4"
                font.family: "Maple Mono NF"
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }
    }

    Process { id: playPauseProc; command: ["playerctl", "play-pause"] }
    Process { id: skipProc; command: ["playerctl", "next"] }
}
