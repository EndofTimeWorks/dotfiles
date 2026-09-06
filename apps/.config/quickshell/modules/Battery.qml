import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import "../Theme.js" as Theme

Item {
    implicitWidth: row.implicitWidth + 10
    implicitHeight: 28

    property var barWindow
    property int alertStage: 0
    readonly property var battery: UPower.displayDevice
    readonly property int pct: battery && battery.ready ? Math.round(battery.percentage) : 0
    readonly property bool charging: battery && (
        battery.state === UPowerDeviceState.Charging
        || battery.state === UPowerDeviceState.FullyCharged
        || battery.state === UPowerDeviceState.PendingCharge
    )
    readonly property real secondsLeft: battery
        ? (charging ? battery.timeToFull : battery.timeToEmpty)
        : 0

    function alertText() {
        var left = displayTimeLeft()
        if (left !== "")
            return pct + "% remaining • " + left
        return pct + "% remaining"
    }

    function displayTimeLeft() {
        if (secondsLeft <= 0 || (!charging && pct <= 10)) return ""
        var totalMinutes = Math.round(secondsLeft / 60)
        if (totalMinutes >= 60) {
            var hours = Math.floor(totalMinutes / 60)
            var minutes = totalMinutes % 60
            return hours + "h" + (minutes > 0 ? " " + minutes + "m" : "") + " left"
        }
        return totalMinutes + " min left"
    }

    function maybeAlert() {
        if (!battery || !battery.ready) return
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

    onPctChanged: maybeAlert()
    onChargingChanged: maybeAlert()

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
        implicitWidth: 230
        implicitHeight: 126
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
            Text { text: pct + "%"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 16; font.bold: true }
            Text {
                text: charging
                    ? (displayTimeLeft() || "Charging")
                    : (displayTimeLeft() || "Discharging")
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
            Text {
                text: battery && battery.healthSupported
                    ? "Battery health  " + Math.round(battery.healthPercentage) + "%"
                    : "Battery health unavailable"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
            Text {
                text: battery && battery.changeRate > 0
                    ? (charging ? "Charging at " : "Using ") + battery.changeRate.toFixed(1) + " W"
                    : "Power rate unavailable"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }
    }

}
