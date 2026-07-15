import QtQuick
import "../Theme.js" as Theme

Item {
    implicitWidth: visible ? 190 : 0
    implicitHeight: 32
    visible: focusedWindow !== null
    clip: true

    property var state
    readonly property var focusedWindow: state ? state.focusedWindow : null

    Text {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        text: focusedWindow ? (focusedWindow.title || focusedWindow.app_id || "") : ""
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: 13
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }
}
