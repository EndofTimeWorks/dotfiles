import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../Theme.js" as Theme

Item {
    implicitWidth: row.implicitWidth + 10
    implicitHeight: 28

    property var barWindow
    property int pct: 100
    property bool charging: false
    property string timeLeft: ""
    property int estimateMinutes: -1
    property int stableEstimateMinutes: -1
    property int stableEstimateCount: 0
    property int alertStage: 0
    property string devicePath: ""

    function alertText() {
        var left = displayTimeLeft()
        if (left !== "")
            return pct + "% remaining • " + left
        return pct + "% remaining"
    }

    function parseEstimateMinutes(text) {
        if (!text)
            return -1

        var m = text.match(/([0-9]+(?:\.[0-9]+)?)\s*(hour|hours|minute|minutes)/)
        if (!m)
            return -1

        var value = parseFloat(m[1])
        var unit = m[2]
        if (isNaN(value))
            return -1

        if (unit.indexOf("hour") === 0)
            return Math.round(value * 60)

        return Math.round(value)
    }

    function updateStableEstimate(rawText) {
        var nextMinutes = parseEstimateMinutes(rawText)

        if (charging || nextMinutes < 0) {
            estimateMinutes = -1
            stableEstimateMinutes = -1
            stableEstimateCount = 0
            return
        }

        if (estimateMinutes < 0) {
            estimateMinutes = nextMinutes
            stableEstimateMinutes = -1
            stableEstimateCount = 0
            return
        }

        var diff = Math.abs(nextMinutes - estimateMinutes)
        var allowedDrift = Math.max(8, Math.round(estimateMinutes * 0.2))

        if (diff <= allowedDrift) {
            stableEstimateCount += 1
            if (stableEstimateCount >= 1)
                stableEstimateMinutes = nextMinutes
        } else {
            stableEstimateCount = 0
            stableEstimateMinutes = -1
        }

        estimateMinutes = nextMinutes
    }

    function displayTimeLeft() {
        if (stableEstimateMinutes < 0)
            return ""

        if (stableEstimateMinutes >= 60) {
            var hours = Math.floor(stableEstimateMinutes / 60)
            var minutes = stableEstimateMinutes % 60
            return hours + "h" + (minutes > 0 ? " " + minutes + "m" : "") + " left"
        }

        return stableEstimateMinutes + " min left"
    }

    function maybeAlert() {
        if (charging) {
            alertStage = 0
            return
        }

        if (pct <= 5) {
            if (alertStage < 2) {
                criticalAlert.running = true
                alertStage = 2
            }
            return
        }

        if (pct <= 20) {
            if (alertStage < 1) {
                lowAlert.running = true
                alertStage = 1
            }
            return
        }

        if (pct > 25)
            alertStage = 0
    }

    function batIcon() {
        if (charging) return "󰂄"
        if (pct > 80) return "󰁹"
        if (pct > 60) return "󰂁"
        if (pct > 40) return "󰁾"
        if (pct > 20) return "󰁼"
        return "󰁺"
    }

    function batColor() {
        if (charging) return Theme.accent
        if (pct <= 20) return Theme.warning
        return Theme.text
    }

    function refreshBattery() {
        if (devicePath !== "" && !proc.running)
            proc.running = true
    }

    Process {
        id: discoverProc
        command: ["upower", "-e"]
        stdout: StdioCollector {
            onStreamFinished: {
                var devices = this.text.trim().split("\n")
                var displayDevice = ""
                for (var i = 0; i < devices.length; i++) {
                    if (devices[i].indexOf("/battery_") !== -1) {
                        devicePath = devices[i]
                        break
                    }
                    if (devices[i].endsWith("/DisplayDevice"))
                        displayDevice = devices[i]
                }
                if (devicePath === "") devicePath = displayDevice
                if (devicePath !== "") {
                    proc.command = ["upower", "-i", devicePath]
                    refreshBattery()
                }
            }
        }
    }

    Process {
        id: proc
        onExited: code => {
            if (code !== 0) {
                devicePath = ""
                discoverProc.running = true
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n")
                var nextPct = pct
                var nextCharging = false
                var nextTimeLeft = ""
                for (var i = 0; i < lines.length; i++) {
                    var t = lines[i].trim()
                    if (t.startsWith("percentage:")) {
                        var parsedPct = parseInt(t.split(":")[1])
                        if (!isNaN(parsedPct)) nextPct = parsedPct
                    }
                    if (t.startsWith("state:")) {
                        var state = t.split(":").slice(1).join(":").trim()
                        nextCharging = state === "charging" || state === "fully-charged" || state === "pending-charge"
                    }
                    if (t.startsWith("time to")) nextTimeLeft = t.split(":").slice(1).join(":").trim()
                }
                pct = nextPct
                charging = nextCharging
                timeLeft = nextTimeLeft
                updateStableEstimate(timeLeft)
                maybeAlert()
            }
        }
    }

    Timer { interval: 5000; running: true; repeat: true; onTriggered: refreshBattery() }
    Timer {
        interval: 30000
        running: devicePath === ""
        repeat: true
        onTriggered: discoverProc.running = true
    }
    Component.onCompleted: discoverProc.running = true

    Process {
        id: lowAlert
        command: [
            "notify-send",
            "-u", "normal",
            "-a", "Battery",
            "Battery low",
            alertText()
        ]
    }

    Process {
        id: criticalAlert
        command: [
            "notify-send",
            "-u", "critical",
            "-a", "Battery",
            "Battery critical",
            alertText() + ". Plug in now."
        ]
    }

    Rectangle {
        anchors.fill: parent
        color: ma.containsMouse ? Theme.surfaceHover : "transparent"
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
            Text { text: batIcon(); color: batColor(); font.family: Theme.fontFamily; font.pixelSize: 14 }
            Text { text: pct + "%"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 13 }
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
            return Math.max(8, Math.min(gx - 8 - 90, barWindow.width - 180 - 8))
        }
        anchor.rect.y: barWindow ? barWindow.implicitHeight : 50
        implicitWidth: 180
        implicitHeight: 80
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: Theme.surface
            radius: 10
            border.color: Qt.rgba(0.306, 0.788, 0.690, 0.15)
            border.width: 1
        }

        Column {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            spacing: 6
            Text { text: pct + "%"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 14 }
            Text {
                text: charging
                    ? (timeLeft !== "" ? timeLeft + " until full" : "Charging")
                    : (displayTimeLeft() || "Discharging")
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
        }
    }

}
