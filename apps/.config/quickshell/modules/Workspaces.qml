import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    implicitWidth: row.implicitWidth + 8
    implicitHeight: 28

    property var workspaces: []

    Process {
        id: proc
        command: ["niri", "msg", "--json", "workspaces"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var ws = JSON.parse(this.text)
                    ws.sort((a, b) => a.idx - b.idx)
                    workspaces = ws
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 800
        running: true
        repeat: true
        onTriggered: proc.running = true
    }

    Component.onCompleted: proc.running = true

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 3

        Repeater {
            model: workspaces
            delegate: Text {
                required property var modelData
                text: modelData.is_focused ? "●" : modelData.active_window_id ? "○" : "·"
                color: modelData.is_focused ? "#c792ea" : modelData.active_window_id ? "#4ec9b0" : "#7f849c"
                font.family: "Maple Mono NF"
                font.pixelSize: modelData.is_focused ? 13 : 11
            }
        }
    }
}
