import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../Theme.js" as Theme

Item {
    id: root

    implicitWidth: visible ? row.implicitWidth + 10 : 0
    implicitHeight: 28
    visible: enabled

    property var barWindow
    property string weatherText: ""
    property string unit: "m"
    property string locationLabel: ""
    property string locationSource: ""
    property bool loading: true
    property bool refreshFailed: false
    property var updatedAt: null
    readonly property string helperPath: Quickshell.env("HOME") + "/.local/bin/location-info"
    readonly property string displayText: weatherText !== ""
        ? weatherText
        : (loading ? "Weather..." : "Weather unavailable")

    function refreshWeather() {
        if (proc.running) return
        loading = true
        pendingWeather = ""
        proc.command = [helperPath, "weather", unit]
        proc.running = true
    }

    function saveUnit(nextUnit) {
        if (nextUnit === unit || unitProc.running) return
        unit = nextUnit
        unitProc.command = [helperPath, "weather-unit", nextUnit]
        unitProc.running = true
    }

    function refreshLabel() {
        if (loading) return "Refreshing..."
        if (refreshFailed)
            return weatherText !== "" ? "Update failed · showing previous reading" : "Weather unavailable"
        return updatedAt ? "Updated " + Qt.formatTime(updatedAt, "h:mm AP") : "Not updated yet"
    }

    property string pendingWeather: ""

    Process {
        id: proc
        command: [root.helperPath, "weather", root.unit]
        stdout: StdioCollector {
            onStreamFinished: root.pendingWeather = this.text.trim()
        }
        onExited: code => {
            root.loading = false
            if (code === 0 && root.pendingWeather !== "") {
                root.weatherText = root.pendingWeather.replace(/\s+/g, "").replace(/\+(\d)/g, "$1")
                root.updatedAt = new Date()
                root.refreshFailed = false
            } else {
                root.refreshFailed = true
            }
        }
    }

    Process {
        id: unitProc
        command: [root.helperPath, "weather-unit"]
        stdout: StdioCollector { id: unitOutput }
        onExited: code => {
            if (code === 0) {
                var savedUnit = unitOutput.text.trim()
                if (savedUnit === "m" || savedUnit === "u")
                    root.unit = savedUnit
            }
            locationProc.running = true
        }
    }

    Process {
        id: locationProc
        command: [root.helperPath, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].startsWith("label="))
                        root.locationLabel = lines[i].slice(6)
                    if (lines[i].startsWith("source="))
                        root.locationSource = lines[i].slice(7)
                }
            }
        }
        onExited: root.refreshWeather()
    }

    Timer { interval: 1800000; running: true; repeat: true; onTriggered: root.refreshWeather() }
    Component.onCompleted: {
        unitProc.running = true
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
            Text { text: root.displayText; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 13 }
        }
    }

    PopupWindow {
        id: popup
        visible: false
        grabFocus: true
        anchor.window: root.barWindow
        anchor.rect.x: {
            if (!root.barWindow) return 0
            var gx = root.mapToGlobal(root.width / 2, 0).x
            return Math.max(8, Math.min(gx - width / 2, root.barWindow.width - width - 8))
        }
        anchor.rect.y: root.barWindow ? root.barWindow.implicitHeight : 50
        implicitWidth: 280
        implicitHeight: content.implicitHeight + 24
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: Theme.surface
            radius: 10
            border.color: Qt.rgba(0.306, 0.788, 0.690, 0.15)
            border.width: 1
        }

        Column {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            spacing: 8

            RowLayout {
                width: parent.width
                Text {
                    Layout.fillWidth: true
                    text: root.displayText
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                    font.bold: true
                }
                Text {
                    text: "Refresh"
                    color: refreshMa.containsMouse ? Theme.accent : Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    MouseArea {
                        id: refreshMa
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        enabled: !root.loading
                        onClicked: root.refreshWeather()
                    }
                }
            }

            Text {
                width: parent.width
                text: root.locationLabel !== "" ? root.locationLabel : "Location unavailable"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: root.refreshLabel()
                color: root.refreshFailed ? Theme.warning : Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: 10
                elide: Text.ElideRight
            }

            RowLayout {
                width: parent.width
                spacing: 6

                Repeater {
                    model: [{ label: "Celsius", value: "m" }, { label: "Fahrenheit", value: "u" }]
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        height: 28
                        radius: 7
                        color: root.unit === modelData.value
                            ? Qt.rgba(0.306, 0.788, 0.690, 0.16)
                            : (unitMa.containsMouse ? Theme.surfaceHover : Qt.rgba(1, 1, 1, 0.04))

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: root.unit === modelData.value ? Theme.accent : Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }

                        MouseArea {
                            id: unitMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.saveUnit(String(modelData.value))
                        }
                    }
                }
            }

            Text {
                width: parent.width
                text: "Coordinates sent to wttr.in"
                    + (root.locationSource !== "" ? " · " + root.locationSource : "")
                color: Theme.divider
                font.family: Theme.fontFamily
                font.pixelSize: 9
                elide: Text.ElideRight
            }
        }
    }
}
