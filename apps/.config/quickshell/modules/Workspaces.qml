import QtQuick
import QtQuick.Layouts
import "../Theme.js" as Theme

Item {
    implicitWidth: row.implicitWidth + 8
    implicitHeight: 28

    property var state

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 3

        Repeater {
            model: state ? state.workspaces : []
            delegate: Text {
                required property var modelData
                text: modelData.is_focused ? "●" : modelData.active_window_id ? "○" : "·"
                color: modelData.is_focused ? Theme.secondary : modelData.active_window_id ? Theme.accent : Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: modelData.is_focused ? 13 : 11
            }
        }
    }
}
