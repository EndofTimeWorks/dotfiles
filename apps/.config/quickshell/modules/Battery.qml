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
    property bool powerSampleTimedOut: false
    readonly property var battery: findBattery()
    readonly property int pct: battery && battery.ready ? Math.round(battery.percentage * 100) : 0
    readonly property bool charging: battery && (
        battery.state === UPowerDeviceState.Charging
        || battery.state === UPowerDeviceState.FullyCharged
        || battery.state === UPowerDeviceState.PendingCharge
    )
    readonly property real secondsLeft: battery
        ? (charging ? battery.timeToFull : battery.timeToEmpty)
        : 0

    function findBattery() {
        var devices = UPower.devices.values
        for (var i = 0; i < devices.length; i++) {
            if (devices[i].isLaptopBattery) return devices[i]
        }
        return UPower.displayDevice
    }

    function alertText() {
        var duration = durationText()
        if (duration !== "")
            return pct + "% remaining · " + duration
        return pct + "% remaining"
    }

    function durationText() {
        if (secondsLeft <= 0 || (!charging && pct <= 10)) return ""
        var totalMinutes = Math.round(secondsLeft / 60)
        if (totalMinutes >= 60) {
            var hours = Math.floor(totalMinutes / 60)
            var minutes = totalMinutes % 60
            return hours + "h" + (minutes > 0 ? " " + minutes + "m" : "")
        }
        return totalMinutes + " min"
    }

    function statusText() {
        if (!battery || !battery.ready) return "Battery unavailable"
        if (battery.state === UPowerDeviceState.FullyCharged) return "Fully charged"
        if (battery.state === UPowerDeviceState.PendingCharge) return "Plugged in, waiting to charge"
        if (battery.state === UPowerDeviceState.Charging)
            return durationText() !== "" ? durationText() + " until full" : "Charging"
        if (battery.state === UPowerDeviceState.Discharging)
            return durationText() !== "" ? durationText() + " remaining" : "Discharging"
        if (battery.state === UPowerDeviceState.PendingDischarge) return "On battery, waiting to discharge"
        return charging ? "Plugged in" : "On battery"
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

    Timer {
        id: powerSampleTimer
        interval: 5000
        running: popup.visible && battery && battery.ready
            && battery.changeRate <= 0 && !powerSampleTimedOut
        onTriggered: powerSampleTimedOut = true
    }

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
        grabFocus: true
        onVisibleChanged: {
            if (visible)
                powerSampleTimedOut = false
        }
        anchor.window: barWindow
        anchor.rect.x: {
            if (!barWindow) return 0
            var gx = parent.mapToGlobal(parent.width / 2, 0).x
            return Math.max(8, Math.min(gx - popup.width / 2, barWindow.width - popup.width - 8))
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
                text: statusText()
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
                    : (powerSampleTimedOut ? "Power rate unavailable" : "Measuring power usage...")
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }
    }

}
