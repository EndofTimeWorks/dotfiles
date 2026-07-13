import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    implicitWidth: row.implicitWidth + 16
    implicitHeight: 32

    property var barWindow
    property string timeStr: Qt.formatTime(new Date(), "hh:mm:ss")
    property string dateStr: Qt.formatDate(new Date(), "ddd MMM d")

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            timeStr = Qt.formatTime(new Date(), "hh:mm:ss")
            dateStr = Qt.formatDate(new Date(), "ddd MMM d")
        }
    }

    Rectangle {
        anchors.fill: parent
        color: ma.containsMouse ? "#141628" : "transparent"
        radius: 8

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            onClicked: panel.visible = !panel.visible
        }

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 8
            Text { text: timeStr; color: "#cdd6f4"; font.family: "Maple Mono NF"; font.pixelSize: 14; font.weight: Font.Medium }
            Text { text: dateStr; color: "#7f849c"; font.family: "Maple Mono NF"; font.pixelSize: 12 }
        }
    }

    PopupWindow {
        id: panel
        visible: false
        grabFocus: true
        anchor.window: barWindow
        anchor.rect.x: {
            if (!barWindow) return 0
            return Math.max(8, Math.floor((barWindow.width - width) / 2))
        }
        anchor.rect.y: barWindow ? barWindow.implicitHeight : 50
        implicitWidth: 280
        implicitHeight: 370
        color: "transparent"

        property string tzLabel: ""
        property string detectedTz: ""
        property string detectedLocation: ""
        property string searchText: ""
        property var zones: [
            "America/Phoenix", "America/New_York", "America/Chicago", "America/Denver", "America/Los_Angeles", "America/Anchorage",
            "Pacific/Honolulu", "Europe/London", "Europe/Paris", "Europe/Berlin", "Europe/Rome", "Europe/Moscow",
            "Asia/Dubai", "Asia/Kolkata", "Asia/Bangkok", "Asia/Shanghai", "Asia/Tokyo", "Asia/Seoul",
            "Australia/Sydney", "Pacific/Auckland"
        ]
        property var filteredZones: {
            var q = String(searchText || "").toLowerCase()
            if (q === "") return zones
            return zones.filter(z => z.toLowerCase().indexOf(q) !== -1)
        }

        Process {
            id: tzProc
            command: ["bash", "-lc", "printf '%s (%s)\\n' \"$(date +%Z)\" \"$(timedatectl show -p Timezone --value 2>/dev/null || true)\""]
            stdout: StdioCollector { onStreamFinished: panel.tzLabel = this.text.trim() }
        }

        Process {
            id: locationProc
            command: ["bash", "-lc", "~/.local/bin/location-info status"]
            stdout: StdioCollector {
                onStreamFinished: {
                    var lines = this.text.trim().split("\n")
                    for (var i = 0; i < lines.length; i++) {
                        var l = lines[i]
                        if (l.startsWith("timezone=")) panel.detectedTz = l.slice(9)
                        if (l.startsWith("label=")) panel.detectedLocation = l.slice(6)
                    }
                }
            }
        }

        Process {
            id: setTzProc
            command: ["true"]
            onExited: {
                tzProc.running = true
                locationProc.running = true
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#0f1120"
            radius: 10
            border.color: Qt.rgba(0.306, 0.788, 0.690, 0.15)
            border.width: 1
        }

        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Text { text: timeStr; color: "#cdd6f4"; font.family: "Maple Mono NF"; font.pixelSize: 18; font.bold: true }
            Text { text: Qt.formatDate(new Date(), "dddd, MMMM d"); color: "#7f849c"; font.family: "Maple Mono NF"; font.pixelSize: 12 }
            Text { text: "System: " + panel.tzLabel; color: "#7f849c"; font.family: "Maple Mono NF"; font.pixelSize: 11 }
            Text {
                text: panel.detectedTz !== ""
                    ? "Detected: " + (panel.detectedLocation !== "" ? panel.detectedLocation + " • " : "") + panel.detectedTz
                    : "Detected: unavailable"
                color: "#4ec9b0"
                font.family: "Maple Mono NF"
                font.pixelSize: 11
                elide: Text.ElideRight
                width: parent.width
            }

            Rectangle {
                width: parent.width
                height: 24
                radius: 6
                color: detectedTzMa.containsMouse ? Qt.rgba(0.306, 0.788, 0.690, 0.16) : Qt.rgba(0.306, 0.788, 0.690, 0.08)

                Text {
                    anchors.centerIn: parent
                    text: panel.detectedTz !== "" ? "Use detected timezone" : "Refresh detected location"
                    color: "#cdd6f4"
                    font.family: "Maple Mono NF"
                    font.pixelSize: 11
                }

                MouseArea {
                    id: detectedTzMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (panel.detectedTz !== "") {
                            setTzProc.command = ["pkexec", "timedatectl", "set-timezone", panel.detectedTz]
                            setTzProc.running = true
                        } else {
                            locationProc.command = ["bash", "-lc", "~/.local/bin/location-info refresh"]
                            locationProc.running = true
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 56
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.04)

                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    Text {
                        text: Qt.formatDate(new Date(), "MMMM yyyy")
                        color: "#cdd6f4"
                        font.family: "Maple Mono NF"
                        font.pixelSize: 12
                        font.bold: true
                    }
                    Text {
                        text: Qt.formatDate(new Date(), "dddd, d")
                        color: "#7f849c"
                        font.family: "Maple Mono NF"
                        font.pixelSize: 11
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 28
                radius: 6
                color: Qt.rgba(1, 1, 1, 0.05)
                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    color: "#cdd6f4"
                    font.family: "Maple Mono NF"
                    font.pixelSize: 11
                    clip: true
                    selectByMouse: true
                    text: panel.searchText
                    onTextChanged: panel.searchText = text
                }
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: searchInput.text === "" ? "Search timezone..." : ""
                    color: "#4a5280"
                    font.family: "Maple Mono NF"
                    font.pixelSize: 11
                }
            }

            Flickable {
                width: parent.width
                height: 58
                contentHeight: tzCol.implicitHeight
                clip: true

                Column {
                    id: tzCol
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: panel.filteredZones
                        delegate: Rectangle {
                            required property var modelData
                            width: parent.width
                            height: 24
                            radius: 6
                            color: tzMa.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                text: modelData
                                color: "#cdd6f4"
                                font.family: "Maple Mono NF"
                                font.pixelSize: 11
                            }

                            MouseArea {
                                id: tzMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    setTzProc.command = ["pkexec", "timedatectl", "set-timezone", String(modelData)]
                                    setTzProc.running = true
                                    panel.visible = false
                                }
                            }
                        }
                    }
                }
            }
        }

        Component.onCompleted: {
            tzProc.running = true
            locationProc.running = true
        }
        onVisibleChanged: {
            if (visible) {
                tzProc.running = true
                locationProc.running = true
                Qt.callLater(function() {
                    searchInput.forceActiveFocus()
                    searchInput.cursorPosition = searchInput.text.length
                })
            } else {
                panel.searchText = ""
            }
        }
    }
}
