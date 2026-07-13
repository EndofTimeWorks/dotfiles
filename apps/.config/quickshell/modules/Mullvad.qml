import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    implicitWidth: row.implicitWidth + 10
    implicitHeight: 28

    property var barWindow
    property bool connected: false
    property string location: ""
    property string ip: ""

    readonly property var favorites: [
        { label: "Phoenix", cmd: ["mullvad", "relay", "set", "location", "us", "phx"] },
        { label: "Los Angeles", cmd: ["mullvad", "relay", "set", "location", "us", "lax"] },
        { label: "Switzerland", cmd: ["mullvad", "relay", "set", "location", "ch"] }
    ]

    Process {
        id: pollProc
        command: ["mullvad", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                var out = this.text || ""
                connected = out.toLowerCase().startsWith("connected")

                var loc = out.match(/location:\s+(.+?)\./)
                location = loc && loc[1] ? String(loc[1]).trim() : ""

                var ipMatch = out.match(/IPv4:\s+([\d.]+)/)
                ip = ipMatch && ipMatch[1] ? ipMatch[1] : ""
            }
        }
        onExited: (code) => {
            if (code !== 0) {
                connected = false
                location = ""
                ip = ""
            }
        }
    }

    Timer { interval: 5000; running: true; repeat: true; onTriggered: pollProc.running = true }
    Component.onCompleted: pollProc.running = true

    Process {
        id: toggleProc
        command: connected
            ? ["mullvad", "disconnect"]
            : ["bash", "-lc", "mullvad lan set allow && mullvad connect"]
        onExited: pollProc.running = true
    }

    Process {
        id: favoriteProc
        command: ["true"]
        onExited: (code) => {
            if (code === 0) reconnectProc.running = true
            else pollProc.running = true
        }
    }

    Process {
        id: reconnectProc
        command: ["mullvad", "reconnect"]
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
                source: Quickshell.iconPath("mullvad-vpn", "network-vpn")
                width: 11
                height: 11
                sourceSize.width: 11
                sourceSize.height: 11
                fillMode: Image.PreserveAspectFit
                opacity: connected ? 1.0 : 0.55
                smooth: true
            }
            Text { text: connected ? "on" : "off"; color: connected ? "#4ec9b0" : "#7f849c"; font.family: "Maple Mono NF"; font.pixelSize: 13 }
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
            return Math.max(8, Math.min(gx - 8 - 120, barWindow.width - 240 - 8))
        }
        anchor.rect.y: barWindow ? barWindow.implicitHeight : 50
        implicitWidth: 240
        implicitHeight: 190
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
            spacing: 8

            Text { text: connected ? "Connected" : "Disconnected"; color: connected ? "#4ec9b0" : "#7f849c"; font.family: "Maple Mono NF"; font.pixelSize: 12 }
            Text { text: location || "—"; color: "#cdd6f4"; font.family: "Maple Mono NF"; font.pixelSize: 11 }
            Text { text: ip || "—"; color: "#7f849c"; font.family: "Maple Mono NF"; font.pixelSize: 11 }

            Repeater {
                model: favorites
                delegate: Rectangle {
                    required property var modelData
                    width: parent.width
                    height: 24
                    radius: 6
                    color: favMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04)

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        color: "#cdd6f4"
                        font.family: "Maple Mono NF"
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: favMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            favoriteProc.command = modelData.cmd
                            favoriteProc.running = true
                        }
                    }
                }
            }
        }
    }
}
