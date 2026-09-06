import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Theme.js" as Theme

Item {
    id: root

    implicitWidth: visible ? (compact ? 32 : 190) : 0
    implicitHeight: 28
    visible: player !== null

    property var barWindow
    property bool compact: false
    property int selectedIndex: -1
    property real displayedPosition: 0
    readonly property var players: Mpris.players.values
    readonly property var player: selectPlayer()
    readonly property string title: player ? (player.trackTitle || player.identity || "Media") : ""
    readonly property string artist: player ? (player.trackArtist || player.trackAlbum || "") : ""

    function selectPlayer() {
        if (selectedIndex >= 0 && selectedIndex < players.length)
            return players[selectedIndex]
        for (var i = 0; i < players.length; i++) {
            if (players[i].isPlaying) return players[i]
        }
        for (var j = 0; j < players.length; j++) {
            if (players[j].trackTitle !== "") return players[j]
        }
        return players.length > 0 ? players[0] : null
    }

    function cyclePlayer(step) {
        if (players.length < 2) return
        var current = players.indexOf(player)
        selectedIndex = (current + step + players.length) % players.length
        syncPosition()
    }

    function syncPosition() {
        displayedPosition = player && player.positionSupported ? player.position : 0
    }

    function formatTime(seconds) {
        if (!isFinite(seconds) || seconds < 0) return "--:--"
        var whole = Math.floor(seconds)
        var mins = Math.floor(whole / 60)
        var secs = whole % 60
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    onPlayerChanged: syncPosition()

    Timer {
        interval: 1000
        running: popup.visible && root.player !== null
        repeat: true
        onTriggered: root.syncPosition()
    }

    Rectangle {
        anchors.fill: parent
        color: mouseArea.containsMouse ? Theme.surfaceHover : "transparent"
        radius: 8

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            onClicked: mouse => {
                if (!root.player) return
                if (mouse.button === Qt.MiddleButton && root.player.canTogglePlaying)
                    root.player.togglePlaying()
                else if (mouse.button === Qt.RightButton && root.player.canGoNext)
                    root.player.next()
                else
                    popup.visible = !popup.visible
            }
            onWheel: wheel => root.cyclePlayer(wheel.angleDelta.y > 0 ? -1 : 1)
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 6

            Text {
                text: root.player && root.player.isPlaying ? "󰐊" : "󰏤"
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: 14
            }

            Text {
                Layout.fillWidth: true
                visible: !root.compact
                text: root.artist !== "" ? root.artist + " · " + root.title : root.title
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }
    }

    PopupWindow {
        id: popup
        visible: false
        grabFocus: true
        anchor.window: root.barWindow
        anchor.rect.x: {
            if (!root.barWindow) return 0
            return Math.max(8, Math.floor((root.barWindow.width - width) / 2))
        }
        anchor.rect.y: root.barWindow ? root.barWindow.implicitHeight : 50
        implicitWidth: 360
        implicitHeight: 196
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: Theme.surface
            radius: 12
            border.color: Qt.rgba(0.306, 0.788, 0.690, 0.15)
            border.width: 1
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 14

            Rectangle {
                id: artFrame
                Layout.preferredWidth: 118
                Layout.preferredHeight: 118
                radius: 10
                color: Theme.surfaceHover
                clip: true

                Image {
                    id: art
                    anchors.fill: parent
                    source: root.player ? root.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰎈"
                    color: Theme.border
                    font.family: Theme.fontFamily
                    font.pixelSize: 34
                    visible: art.status !== Image.Ready
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 5

                Text {
                    Layout.fillWidth: true
                    text: root.title
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.bold: true
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: root.artist || (root.player ? root.player.identity : "")
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }

                Slider {
                    Layout.fillWidth: true
                    enabled: root.player && root.player.canSeek && root.player.lengthSupported
                    from: 0
                    to: root.player && root.player.lengthSupported ? Math.max(1, root.player.length) : 1
                    value: root.displayedPosition
                    onMoved: {
                        if (root.player && root.player.canSeek) {
                            root.player.position = value
                            root.displayedPosition = value
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: root.formatTime(root.displayedPosition); color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: 10 }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: root.formatTime(root.player && root.player.lengthSupported ? root.player.length : -1)
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "󰒮"
                        color: root.player && root.player.canGoPrevious ? Theme.text : Theme.border
                        font.family: Theme.fontFamily
                        font.pixelSize: 19
                        MouseArea { anchors.fill: parent; enabled: root.player && root.player.canGoPrevious; onClicked: root.player.previous() }
                    }
                    Text {
                        text: root.player && root.player.isPlaying ? "󰏤" : "󰐊"
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: 24
                        MouseArea { anchors.fill: parent; enabled: root.player && root.player.canTogglePlaying; onClicked: root.player.togglePlaying() }
                    }
                    Text {
                        text: "󰒭"
                        color: root.player && root.player.canGoNext ? Theme.text : Theme.border
                        font.family: Theme.fontFamily
                        font.pixelSize: 19
                        MouseArea { anchors.fill: parent; enabled: root.player && root.player.canGoNext; onClicked: root.player.next() }
                    }
                    Item { Layout.fillWidth: true }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: (root.player ? root.player.identity : "Media")
                            + (root.players.length > 1 ? " · " + root.players.length + " players" : "")
                        color: Theme.secondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        MouseArea {
                            anchors.fill: parent
                            enabled: root.player && root.player.canRaise
                            onClicked: root.player.raise()
                        }
                    }
                    Text {
                        visible: root.players.length > 1
                        text: "󰒭"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        MouseArea { anchors.fill: parent; onClicked: root.cyclePlayer(1) }
                    }
                }
            }
        }
    }
}
