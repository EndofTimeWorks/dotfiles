import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts

Item {
    implicitWidth: row.implicitWidth
    implicitHeight: 28
    property var barWindow

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: SystemTray.items
            delegate: Item {
                id: trayItem
                required property SystemTrayItem modelData
                implicitWidth: 28
                implicitHeight: 28

                Rectangle {
                    anchors.fill: parent
                    color: ma.containsMouse ? "#141628" : "transparent"
                    radius: 6

                    Image {
                        id: icon
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        source: modelData.icon || Quickshell.iconPath(modelData.id || modelData.title || "", "application-x-executable")
                        smooth: true
                        visible: status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        text: (modelData.title ?? "?").charAt(0).toUpperCase()
                        color: "#7f849c"
                        font.family: "Maple Mono NF"
                        font.pixelSize: 11
                        visible: icon.status !== Image.Ready
                    }

                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.RightButton) {
                                if (!barWindow || !modelData.hasMenu) return
                                var point = barWindow.mapFromItem(trayItem, mouse.x, mouse.y)
                                modelData.display(barWindow, point.x, point.y)
                            } else if (modelData.onlyMenu) {
                                if (!barWindow || !modelData.hasMenu) return
                                var menuPoint = barWindow.mapFromItem(trayItem, Math.floor(width / 2), height)
                                modelData.display(barWindow, menuPoint.x, menuPoint.y)
                            } else {
                                modelData.activate()
                            }
                        }
                    }
                }
            }
        }
    }
}
