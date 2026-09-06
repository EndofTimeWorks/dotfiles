import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import "../Theme.js" as Theme

Item {
    id: root

    implicitWidth: row.implicitWidth + 10
    implicitHeight: 28

    property bool showIp: false
    property bool compact: false
    readonly property var devices: Networking.devices.values
    readonly property var activeDevice: findActiveDevice()
    readonly property var activeNetwork: findActiveNetwork()
    readonly property bool wifiBlocked: !Networking.wifiHardwareEnabled
    readonly property int signalStrength: activeNetwork ? Math.round(activeNetwork.signalStrength) : 0
    readonly property string netIcon: {
        if (wifiBlocked && !activeDevice) return "󰖪"
        if (!activeDevice) return "󰤭"
        if (activeDevice.type === DeviceType.Wired) return "󰈀"
        if (signalStrength > 75) return "󰤨"
        if (signalStrength > 50) return "󰤥"
        if (signalStrength > 25) return "󰤢"
        return "󰤟"
    }
    readonly property string netLabel: {
        if (wifiBlocked && !activeDevice) return "rfkill"
        if (!activeDevice) return "offline"
        if (showIp) return activeDevice.address || "no ip"
        if (activeDevice.type === DeviceType.Wired) return "wired"
        return activeNetwork ? (activeNetwork.name || "connected") : "connected"
    }
    readonly property string netColor: activeDevice ? Theme.accent : (wifiBlocked ? Theme.warning : Theme.textMuted)

    function findActiveDevice() {
        for (var i = 0; i < devices.length; i++) {
            if (devices[i].connected) return devices[i]
        }
        return null
    }

    function findActiveNetwork() {
        if (!activeDevice || activeDevice.type !== DeviceType.Wifi) return null
        var networks = activeDevice.networks.values
        for (var i = 0; i < networks.length; i++) {
            if (networks[i].connected) return networks[i]
        }
        return null
    }

    Rectangle {
        anchors.fill: parent
        color: ma.containsMouse ? Theme.surfaceHover : "transparent"
        radius: 8
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            onClicked: showIp = !showIp
        }
        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 4
            Text { text: root.netIcon; color: root.netColor; font.family: Theme.fontFamily; font.pixelSize: 14 }
            Text { visible: !root.compact; text: root.netLabel; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 13 }
        }
    }
}
