import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    implicitWidth: row.implicitWidth + 10
    implicitHeight: 28

    property var barWindow
    property bool up: false
    property string ip: ""
    property int peers: 0

    Process {
        id: pollProc
        command: ["tailscale", "status", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var j = JSON.parse(this.text)
                    up = j.BackendState === "Running"
                    ip = j.TailscaleIPs && j.TailscaleIPs[0] ? j.TailscaleIPs[0] : ""
                    peers = Object.keys(j.Peer || {}).length
                } catch (e) {}
            }
        }
    }

    Timer { interval: 5000; running: true; repeat: true; onTriggered: pollProc.running = true }
    Component.onCompleted: pollProc.running = true

    Process {
        id: toggleProc
        command: up
            ? ["tailscale", "down"]
            : ["bash", "-lc", "tailscale up && /home/end/.local/bin/mullvad-tailscale-fix || true"]
        onExited: pollProc.running = true
    }

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
                if (mouse.button === Qt.RightButton) popup.visible = !popup.visible
                else toggleProc.running = true
            }
        }

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 4
            Image {
                source: Quickshell.iconPath("tailscale", "network-vpn")
                width: 12
                height: 12
                sourceSize.width: 12
                sourceSize.height: 12
                fillMode: Image.PreserveAspectFit
                opacity: up ? 1.0 : 0.55
                smooth: true
            }
            Text { text: up ? "on" : "off"; color: up ? "#c792ea" : "#7f849c"; font.family: "Maple Mono NF"; font.pixelSize: 13 }
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
        implicitHeight: 95
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
            spacing: 6
            Text { text: up ? "Running" : "Stopped"; color: up ? "#c792ea" : "#7f849c"; font.family: "Maple Mono NF"; font.pixelSize: 12 }
            Text { text: ip || "No IP"; color: "#cdd6f4"; font.family: "Maple Mono NF"; font.pixelSize: 11 }
            Text { text: "Peers: " + peers; color: "#7f849c"; font.family: "Maple Mono NF"; font.pixelSize: 11 }
        }
    }
}
