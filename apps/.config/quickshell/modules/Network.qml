import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    implicitWidth: row.implicitWidth + 10
    implicitHeight: 28

    property string netIcon: "󰤭"
    property string netLabel: "offline"
    property string netColor: "#7f849c"
    property bool showIp: false

    Process {
        id: proc
        command: ["bash", "-c", [
            "rfkill list wifi | grep -q 'blocked: yes' && echo rfkill && exit;",
            "eth=$(nmcli -t -f device,type,state dev 2>/dev/null | grep ':ethernet:connected' | head -1);",
            "wifi=$(nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | grep '^yes' | head -1);",
            "ip=$(ip -4 route get 1.1.1.1 2>/dev/null | grep -oP '(?<=src )[\\d.]+');",
            "echo \"$eth|$wifi|$ip\""
        ].join(" ")]
        stdout: StdioCollector {
            onStreamFinished: {
                var out = this.text.trim()
                if (out === "rfkill") {
                    netIcon = "󰖪"
                    netLabel = "rfkill"
                    netColor = "#f97b58"
                    return
                }
                var parts = out.split("|")
                var eth = parts[0] || ""
                var wifi = parts[1] || ""
                var ip = parts[2] || ""

                if (eth) {
                    netIcon = "󰈀"
                    netLabel = showIp ? (ip || "no ip") : "wired"
                    netColor = "#4ec9b0"
                } else if (wifi) {
                    var wp = wifi.split(":")
                    var ssid = wp[1] || "connected"
                    var sig = parseInt(wp[2]) || 0
                    netIcon = sig > 75 ? "󰤨" : sig > 50 ? "󰤥" : sig > 25 ? "󰤢" : "󰤟"
                    netLabel = showIp ? (ip || "no ip") : ssid
                    netColor = "#4ec9b0"
                } else {
                    netIcon = "󰤭"
                    netLabel = "offline"
                    netColor = "#7f849c"
                }
            }
        }
    }

    Timer { interval: 5000; running: true; repeat: true; onTriggered: proc.running = true }
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
                showIp = !showIp
                proc.running = true
            }
        }
        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 4
            Text { text: netIcon; color: netColor; font.family: "Maple Mono NF"; font.pixelSize: 14 }
            Text { text: netLabel; color: "#cdd6f4"; font.family: "Maple Mono NF"; font.pixelSize: 13 }
        }
    }
}
