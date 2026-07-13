import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

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
    property string alertTitle: ""
    property string alertBody: ""
    property string alertColor: "#fac863"

    function alertText() {
        var left = displayTimeLeft()
        if (left !== "")
            return pct + "% remaining • " + left
        if (timeLeft !== "")
            return pct + "% remaining • " + timeLeft + " left"
        return pct + "% remaining"
    }

    function showBatteryWarning(stage) {
        if (stage === 2) {
            alertTitle = "Battery critical"
            alertBody = alertText() + ". Plug in now."
            alertColor = "#ec5f89"
        } else {
            alertTitle = "Battery low"
            alertBody = alertText()
            alertColor = "#fac863"
        }

        warningPopup.visible = true
        warningTimer.interval = stage === 2 ? 30000 : 18000
        warningTimer.restart()
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
            warningPopup.visible = false
            return
        }

        if (pct <= 5) {
            if (alertStage < 2) {
                criticalAlert.running = true
                showBatteryWarning(2)
                alertStage = 2
            }
            return
        }

        if (pct <= 20) {
            if (alertStage < 1) {
                lowAlert.running = true
                showBatteryWarning(1)
                alertStage = 1
            }
            return
        }

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
        if (charging) return "#4ec9b0"
        if (pct < 20) return "#f97b58"
        return "#cdd6f4"
    }

    Process {
        id: proc
        command: ["upower", "-i", "/org/freedesktop/UPower/devices/battery_BAT1"]
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
                    if (t.startsWith("state:")) nextCharging = t.indexOf("charging") !== -1 && t.indexOf("discharging") === -1
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

    Timer { interval: 5000; running: true; repeat: true; onTriggered: proc.running = true }
    Component.onCompleted: proc.running = true

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

    Timer {
        id: warningTimer
        interval: 18000
        running: false
        repeat: false
        onTriggered: warningPopup.visible = false
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
            Text { text: batIcon(); color: batColor(); font.family: "Maple Mono NF"; font.pixelSize: 14 }
            Text { text: pct + "%"; color: "#cdd6f4"; font.family: "Maple Mono NF"; font.pixelSize: 13 }
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
            color: "#0f1120"
            radius: 10
            border.color: Qt.rgba(0.306, 0.788, 0.690, 0.15)
            border.width: 1
        }

        Column {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            spacing: 6
            Text { text: pct + "%"; color: "#cdd6f4"; font.family: "Maple Mono NF"; font.pixelSize: 14 }
            Text {
                text: charging
                    ? (timeLeft !== "" ? timeLeft + " until full" : "Charging")
                    : (displayTimeLeft() || "Discharging")
                color: "#7f849c"
                font.family: "Maple Mono NF"
                font.pixelSize: 12
            }
        }
    }

    PopupWindow {
        id: warningPopup
        visible: false
        grabFocus: false
        anchor.window: barWindow
        anchor.rect.x: barWindow ? Math.max(8, Math.floor((barWindow.width - 380) / 2)) : 0
        anchor.rect.y: barWindow ? barWindow.implicitHeight + 8 : 58
        implicitWidth: 380
        implicitHeight: 112
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "#0f1120"
            radius: 16
            border.color: alertColor
            border.width: 2

            MouseArea {
                anchors.fill: parent
                onClicked: warningPopup.visible = false
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Text {
                    text: pct <= 5 ? "󰂃" : "󰁺"
                    color: alertColor
                    font.family: "Maple Mono NF"
                    font.pixelSize: 32
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4

                    Text {
                        text: alertTitle
                        color: "#cdd6f4"
                        font.family: "Maple Mono NF"
                        font.pixelSize: 16
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Text {
                        text: alertBody
                        color: "#a6accd"
                        font.family: "Maple Mono NF"
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "click to dismiss"
                        color: "#5f668a"
                        font.family: "Maple Mono NF"
                        font.pixelSize: 10
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}
