import Quickshell
import QtQuick
import QtQuick.Layouts
import "../Theme.js" as Theme

Item {
    implicitWidth: 32
    implicitHeight: 28

    property int unread: 0
    property var history: []
    property string mode: "normal"
    property var activateFn
    property var setModeFn
    property var barWindow
    signal cleared()
    signal historyCleared()

    function toggleMode() {
        if (setModeFn) setModeFn(mode === "dnd" ? "normal" : "dnd")
    }

    Rectangle {
        anchors.fill: parent
        color: ma.containsMouse ? Theme.surfaceHover : "transparent"
        radius: 8

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    toggleMode()
                } else {
                    cleared()
                    panel.visible = !panel.visible
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: mode === "dnd" ? "󰂛" : "󰂚"
            color: mode === "dnd" ? Theme.textMuted : (unread > 0 ? Theme.pink : Theme.textMuted)
            font.family: Theme.fontFamily
            font.pixelSize: 15
        }

        Rectangle {
            visible: unread > 0
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 3
            width: 8
            height: 8
            radius: 4
            color: Theme.pink
        }
    }

    PopupWindow {
        id: panel
        visible: false
        grabFocus: false
        anchor.window: barWindow
        anchor.rect.x: barWindow ? Math.max(8, barWindow.width - 360 - 8) : 0
        anchor.rect.y: barWindow ? barWindow.implicitHeight : 50
        implicitWidth: 360
        implicitHeight: Math.min(headerH + (history.length === 0 ? 30 : notifCol.implicitHeight), 480)
        color: "transparent"

        readonly property int headerH: 72

        Rectangle {
            anchors.fill: parent
            color: Theme.surface
            radius: 12
            border.color: Qt.rgba(0.306, 0.788, 0.690, 0.15)
            border.width: 1

            Column {
                id: header
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                height: 38
                spacing: 6

                Item {
                    width: parent.width
                    height: 18

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Notifications"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Clear all"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        MouseArea { anchors.fill: parent; onClicked: { historyCleared(); cleared() } }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 16
                    color: mode === "dnd" ? Qt.rgba(0.925, 0.373, 0.537, 0.12) : Qt.rgba(0.306, 0.788, 0.690, 0.10)
                    radius: 6

                    Text {
                        anchors.centerIn: parent
                        text: mode === "dnd" ? "DND: toasts muted" : "Normal: toasts shown"
                        color: mode === "dnd" ? Theme.pink : Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: toggleMode()
                    }
                }
            }

            Flickable {
                anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom }
                anchors.topMargin: 8
                anchors.margins: 12
                contentHeight: notifCol.implicitHeight
                clip: true

                Column {
                    id: notifCol
                    width: parent.width
                    spacing: 0

                    Text {
                        visible: history.length === 0
                        text: "No notifications"
                        color: Theme.border
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                    }

                    Repeater {
                        model: history.slice().reverse()
                        delegate: Item {
                            required property int index
                            required property var modelData
                            width: parent.width
                            implicitHeight: notifBody.implicitHeight + 12

                            Rectangle {
                                width: parent.width
                                height: 1
                                color: Qt.rgba(0.306, 0.788, 0.690, 0.1)
                                visible: index > 0
                            }

                            Column {
                                id: notifBody
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.topMargin: 6
                                spacing: 0

                                Text {
                                    text: modelData.app
                                    color: Theme.secondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                Text {
                                    text: modelData.summary
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    width: parent.width
                                    elide: Text.ElideRight
                                    visible: modelData.summary !== ""
                                }

                                Text {
                                    text: modelData.body
                                    color: Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    width: parent.width
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    visible: modelData.body !== ""
                                }
                            }

                            MouseArea {
                                anchors.fill: notifBody
                                acceptedButtons: Qt.LeftButton
                                onClicked: {
                                    if (activateFn) activateFn(modelData)
                                    panel.visible = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
