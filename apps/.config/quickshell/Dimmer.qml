import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

Scope {
    property real dimAmount: 0.0

    Process {
        id: dimProc
        command: ["bash", "-lc", "~/.local/bin/display-brightness dim-status"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var l = lines[i]
                    if (l.startsWith("dim=")) {
                        dimAmount = parseFloat(l.slice(4)) || 0
                    }
                }
            }
        }
    }

    Timer {
        interval: 250
        running: true
        repeat: true
        onTriggered: dimProc.running = true
    }

    Component.onCompleted: dimProc.running = true

    Variants {
        model: Quickshell.screens
        delegate: Component {
            PanelWindow {
                required property var modelData
                screen: modelData
                color: "transparent"
                surfaceFormat.opaque: false
                aboveWindows: true
                mask: Region {
                    width: 0
                    height: 0
                }
                anchors { top: true; bottom: true; left: true; right: true }
                implicitWidth: screen.width
                implicitHeight: screen.height
                visible: true
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                Rectangle {
                    anchors.fill: parent
                    color: "black"
                    opacity: dimAmount
                }
            }
        }
    }
}
