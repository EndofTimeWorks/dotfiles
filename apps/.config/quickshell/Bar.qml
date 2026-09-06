import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "modules"
import "Theme.js" as Theme

Scope {
    id: root

    property var niriState
    property int notifUnread: 0
    property var notifHistory: []
    property string notifMode: "normal"
    property real dimAmount: 0.0
    property var notifActivateFn
    property var notifSetModeFn
    signal notifCleared()
    signal notifHistoryCleared()
    signal dimChanged(real val)

    Variants {
        model: Quickshell.screens
        delegate: Component {
            PanelWindow {
                id: barWin
                required property var modelData
                readonly property bool compact: width < 1450
                readonly property bool narrow: width < 1100
                screen: modelData
                color: "transparent"
                anchors { top: true; left: true; right: true }
                implicitHeight: 50
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

                Item {
                    anchors.fill: parent

                    Rectangle {
                        id: pill
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 6
                        width: parent.width - 16
                        height: 40
                        color: Theme.surface
                        radius: 12
                        border.color: Qt.rgba(0.306, 0.788, 0.690, 0.15)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            spacing: 4

                            Item {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                implicitHeight: parent.height
                                clip: true

                                RowLayout {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4
                                    Workspaces { state: root.niriState }
                                    WindowTitle {
                                        state: root.niriState
                                        enabled: !barWin.narrow
                                    }
                                }
                            }

                            RowLayout {
                                id: centerSection
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 4
                                Clock { barWindow: barWin }
                                Media {
                                    barWindow: barWin
                                    compact: barWin.compact
                                }
                            }

                            RowLayout {
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 3
                                SysStats {
                                    barWindow: barWin
                                    compact: barWin.narrow
                                }
                                Weather { enabled: !barWin.compact }
                                Mullvad { barWindow: barWin; compact: barWin.narrow }
                                Tailscale { barWindow: barWin; compact: barWin.narrow }
                                Network { compact: barWin.narrow }
                                Battery { barWindow: barWin }
                                Brightness {
                                    dim: dimAmount
                                    setDimFn: (val) => dimChanged(val)
                                    barWindow: barWin
                                }
                                Volume { barWindow: barWin }
                                Tray { barWindow: barWin }
                                NotifBell {
                                    unread: notifUnread
                                    history: notifHistory
                                    mode: notifMode
                                    activateFn: notifActivateFn
                                    setModeFn: notifSetModeFn
                                    barWindow: barWin
                                    onCleared: notifCleared()
                                    onHistoryCleared: notifHistoryCleared()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
