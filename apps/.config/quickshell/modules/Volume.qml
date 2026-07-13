import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    implicitWidth: row.implicitWidth + 10
    implicitHeight: 28

    property var barWindow

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    property var sink: Pipewire.defaultAudioSink
    property var source: Pipewire.defaultAudioSource
    property int vol: sink?.audio ? Math.round(sink.audio.volume * 100) : 0
    property bool muted: sink?.audio?.muted ?? false

    function volIcon() {
        if (muted || vol === 0) return "󰝟"
        if (vol < 34) return "󰕿"
        if (vol < 67) return "󰖀"
        return "󰕾"
    }

    Rectangle {
        anchors.fill: parent
        color: ma.containsMouse ? "#141628" : "transparent"
        radius: 8

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.MiddleButton) {
                    if (sink?.audio) sink.audio.muted = !sink.audio.muted
                } else {
                    popup.visible = !popup.visible
                }
            }
        }

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 4
            Text { text: volIcon(); color: muted ? "#7f849c" : "#4ec9b0"; font.family: "Maple Mono NF"; font.pixelSize: 14 }
            Text { text: vol + "%"; color: "#cdd6f4"; font.family: "Maple Mono NF"; font.pixelSize: 13 }
        }
    }

    PopupWindow {
        id: popup
        visible: false
        grabFocus: false
        anchor.window: barWindow
        anchor.rect.x: {
            if (!barWindow) return 0
            var gx = parent.mapToGlobal(parent.width / 2, 0).x
            return Math.max(8, Math.min(gx - 8 - 110, barWindow.width - 220 - 8))
        }
        anchor.rect.y: barWindow ? barWindow.implicitHeight : 50
        implicitWidth: 220
        implicitHeight: 200
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "#0f1120"
            radius: 10
            border.color: Qt.rgba(0.306, 0.788, 0.690, 0.15)
            border.width: 1
        }

        Column {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            spacing: 10

            Row {
                width: parent.width
                spacing: 8
                Text { text: "󰕾"; color: "#4ec9b0"; font.family: "Maple Mono NF"; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "Speaker"; color: "#cdd6f4"; font.family: "Maple Mono NF"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                Text { text: vol + "%"; color: "#7f849c"; font.family: "Maple Mono NF"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
            }

            Slider {
                width: parent.width
                from: 0
                to: 1.5
                value: sink?.audio?.volume ?? 0
                onMoved: { if (sink?.audio) sink.audio.volume = value }
            }

            Row {
                width: parent.width
                spacing: 8
                property int micVol: source?.audio ? Math.round(source.audio.volume * 100) : 0
                property bool micMuted: source?.audio?.muted ?? false
                Text { text: parent.micMuted ? "󰍭" : "󰍬"; color: parent.micMuted ? "#7f849c" : "#c792ea"; font.family: "Maple Mono NF"; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "Mic"; color: "#cdd6f4"; font.family: "Maple Mono NF"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                Text { text: parent.micVol + "%"; color: "#7f849c"; font.family: "Maple Mono NF"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
            }

            Slider {
                width: parent.width
                from: 0
                to: 1
                value: source?.audio?.volume ?? 0
                onMoved: { if (source?.audio) source.audio.volume = value }
            }
        }
    }
}
