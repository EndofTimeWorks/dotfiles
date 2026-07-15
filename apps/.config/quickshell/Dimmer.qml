import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

Scope {
    id: root
    property real dimAmount: 0.0
    readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")

    function loadDim(text) {
        var value = parseFloat(String(text || "").trim())
        dimAmount = isNaN(value) ? 0 : Math.max(0, Math.min(1, value))
    }

    FileView {
        id: dimFile
        path: root.stateHome + "/display/dim"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.loadDim(text())
    }

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
