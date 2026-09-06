import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import "Theme.js" as Theme

Scope {
    id: root

    property var niriState
    property var history: []
    property int unread: 0
    property string mode: "normal"
    property var focusQueue: []
    property var toastEntries: []

    function runDesktopEntry(desktopEntry) {
        var id = String(desktopEntry || "")
        if (id.endsWith(".desktop")) id = id.slice(0, -8)
        if (id === "") return
        launchProc.command = ["gtk-launch", id]
        launchProc.running = true
    }

    function normalized(str) {
        return String(str || "").toLowerCase().trim()
    }

    function dedupe(list) {
        var out = []
        var seen = {}
        for (var i = 0; i < list.length; i++) {
            var value = normalized(list[i])
            if (value === "" || seen[value]) continue
            seen[value] = true
            out.push(value)
        }
        return out
    }

    function fallbackDesktopId(appName) {
        var key = normalized(appName)
        if (key === "discord") return "discord"
        if (key === "vesktop") return "vesktop"
        if (key === "signal") return "signal"
        if (key === "slack") return "slack"
        if (key === "spotify") return "spotify"
        if (key === "thunderbird") return "org.mozilla.Thunderbird"
        if (key === "zen browser") return "zen"
        if (key === "zen") return "zen"
        if (key === "obsidian") return "obsidian"
        if (key === "helium") return "helium"
        return ""
    }

    function isDefaultAction(action) {
        if (!action) return false
        var id = normalized(action.identifier)
        return id === "" || id === "default"
    }

    function appIdCandidates(appName, desktopEntry) {
        var key = normalized(appName)
        var ids = []
        var desktopId = normalized(desktopEntry || "")

        if (desktopId.endsWith(".desktop")) desktopId = desktopId.slice(0, -8)
        if (desktopId !== "") {
            ids.push(desktopId)
            ids.push(desktopId.replace(/-/g, " "))
            ids.push(desktopId.replace(/\./g, " "))
        }

        if (key !== "") {
            ids.push(key)
            ids.push(key.replace(/\s+/g, "-"))
            ids.push(key.replace(/\s+/g, ""))
        }

        if (key === "discord" || key === "vesktop") ids = ids.concat(["discord", "vesktop", "com.discordapp.discord"])
        if (key === "signal") ids = ids.concat(["signal", "signal-desktop"])
        if (key === "slack") ids = ids.concat(["slack", "app.slack"])
        if (key === "spotify") ids = ids.concat(["spotify"])
        if (key === "thunderbird") ids = ids.concat(["thunderbird", "org.mozilla.thunderbird"])
        if (key === "zen browser" || key === "zen") ids = ids.concat(["zen", "zen-browser"])
        if (key === "obsidian") ids = ids.concat(["obsidian", "md.obsidian"])
        if (key === "helium") ids = ids.concat(["helium", "helium-browser"])

        return dedupe(ids)
    }

    function findWindow(ids) {
        if (!niriState) return null

        var windows = niriState.windows || []
        for (var i = 0; i < windows.length; i++) {
            var appId = normalized(windows[i].app_id)
            for (var j = 0; j < ids.length; j++) {
                var candidate = normalized(ids[j])
                if (appId === candidate || appId.endsWith("." + candidate))
                    return windows[i]
            }
        }
        return null
    }

    function startNextFocus() {
        if (focusProc.running || focusQueue.length === 0) return
        var windowId = focusQueue[0]
        focusQueue = focusQueue.slice(1)
        focusProc.command = ["niri", "msg", "action", "focus-window", "--id", String(windowId)]
        focusProc.running = true
    }

    function focusKnownWindow(appName, desktopEntry, allowLaunchFallback) {
        var ids = appIdCandidates(appName, desktopEntry)
        var window = findWindow(ids)
        if (window) {
            focusQueue = focusQueue.concat([window.id])
            startNextFocus()
            return true
        }

        if (!allowLaunchFallback) return false
        var launchId = String(desktopEntry || fallbackDesktopId(appName) || "")
        if (launchId === "") return false
        runDesktopEntry(launchId)
        return true
    }

    function activateNotification(notif) {
        if (!notif) return

        var acts = notif.actions || []
        for (var i = 0; i < acts.length; i++) {
            var a = acts[i]
            if (isDefaultAction(a)) {
                var invoked = false
                try {
                    a.invoke()
                    invoked = true
                } catch (error) {
                    console.warn("Could not invoke notification action:", error)
                }

                if (invoked) {
                    focusKnownWindow(notif.appName, notif.desktopEntry, false)
                    return
                }
            }
        }

        if (focusKnownWindow(notif.appName, notif.desktopEntry, true)) {
            return
        }

        var mapped = fallbackDesktopId(notif.appName)
        if (mapped !== "") runDesktopEntry(mapped)
    }

    function activateHistoryEntry(entry) {
        if (!entry) return

        if (entry.notif) {
            try {
                if (entry.notif.tracked) {
                    activateNotification(entry.notif)
                    return
                }
            } catch (error) {
                console.warn("Could not inspect historical notification:", error)
            }
        }

        if (entry.desktopEntry && entry.desktopEntry !== "") {
            if (focusKnownWindow(entry.app, entry.desktopEntry, true)) return
            runDesktopEntry(entry.desktopEntry)
            return
        }

        var mapped = fallbackDesktopId(entry.app)
        if (mapped !== "") runDesktopEntry(mapped)
    }

    function historyEntryById(id) {
        for (var i = history.length - 1; i >= 0; i--) {
            if (history[i].id === id) return history[i]
        }
        return null
    }

    function toastEntryById(id, time) {
        for (var i = toastEntries.length - 1; i >= 0; i--) {
            if (toastEntries[i].id === id && toastEntries[i].time === time)
                return toastEntries[i]
        }
        return null
    }

    function upsertToastEntry(entry) {
        var next = toastEntries.slice()
        for (var i = 0; i < next.length; i++) {
            if (next[i].id === entry.id) {
                next[i] = entry
                toastEntries = next
                return
            }
        }
        next.push(entry)
        toastEntries = next
    }

    function takeToastEntry(id, time) {
        var found = null
        var next = []
        for (var i = 0; i < toastEntries.length; i++) {
            var entry = toastEntries[i]
            if (entry.id === id && entry.time === time)
                found = entry
            else
                next.push(entry)
        }
        toastEntries = next
        return found
    }

    function closeNotification(entry, expired) {
        if (!entry || !entry.notif) return
        try {
            if (!entry.notif.tracked) return
            if (expired) entry.notif.expire()
            else entry.notif.dismiss()
        } catch (error) {
            console.warn("Could not close notification:", error)
        }
    }

    function markRead() {
        unread = 0
    }

    function clearHistory() {
        var entries = history.concat(toastEntries)
        history = []
        toastEntries = []
        toastModel.clear()
        unread = 0
        for (var i = 0; i < entries.length; i++)
            closeNotification(entries[i], false)
    }

    function setMode(nextMode) {
        mode = nextMode === "dnd" ? "dnd" : "normal"
        saveModeProc.command = [
            "bash",
            "-lc",
            "mkdir -p ~/.local/state/quickshell && printf '%s\n' " + mode + " > ~/.local/state/quickshell/notification-mode",
        ]
        saveModeProc.running = true
    }

    Process { id: launchProc }
    Process { id: saveModeProc }
    Process {
        id: loadModeProc
        command: ["bash", "-lc", "cat ~/.local/state/quickshell/notification-mode 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: root.mode = this.text.trim() === "dnd" ? "dnd" : "normal"
        }
    }
    Process {
        id: focusProc
        onExited: Qt.callLater(root.startNextFocus)
    }

    Component.onCompleted: loadModeProc.running = true

    NotificationServer {
        id: server
        actionsSupported: true

        onNotification: (notif) => {
            notif.tracked = true

            var private_ = normalized(notif.appName).indexOf("signal") !== -1
            var entry = {
                id: notif.id,
                app: notif.appName || "notification",
                summary: notif.summary || "",
                body: private_ ? "" : (notif.body || ""),
                desktopEntry: notif.desktopEntry || "",
                notif: notif,
                transient: notif.transient,
                time: Date.now()
            }

            if (!entry.transient) {
                var arr = root.history.slice()
                var replaced = false
                for (var i = 0; i < arr.length; i++) {
                    if (arr[i].id === entry.id) {
                        arr[i] = entry
                        replaced = true
                        break
                    }
                }
                if (!replaced) arr.push(entry)
                if (arr.length > 100)
                    closeNotification(arr.shift(), true)
                root.history = arr
                if (!replaced) root.unread++
            }

            if (root.mode !== "dnd" || notif.urgency === NotificationUrgency.Critical) {
                root.upsertToastEntry(entry)
                var toast = {
                    id: entry.id,
                    time: entry.time,
                    app: entry.app,
                    summary: entry.summary,
                    body: entry.body,
                    desktopEntry: entry.desktopEntry,
                }
                var toastReplaced = false
                for (var j = 0; j < toastModel.count; j++) {
                    if (toastModel.get(j).id === entry.id) {
                        toastModel.set(j, toast)
                        toastReplaced = true
                        break
                    }
                }
                if (!toastReplaced) toastModel.append(toast)

                var ms = notif.expireTimeout > 0 ? notif.expireTimeout * 1000 : 8000
                expireTimer.createObject(root, { notifId: notif.id, notifTime: entry.time, delay: ms })
            } else if (entry.transient) {
                root.closeNotification(entry, true)
            }
        }
    }

    Component {
        id: expireTimer
        Timer {
            property int notifId
            property double notifTime
            property int delay: 8000
            interval: delay
            running: true
            repeat: false
            onTriggered: {
                var entry = root.takeToastEntry(notifId, notifTime)
                for (var i = 0; i < toastModel.count; i++) {
                    if (toastModel.get(i).id === notifId && toastModel.get(i).time === notifTime) {
                        toastModel.remove(i)
                        break
                    }
                }
                if (entry && entry.transient)
                    root.closeNotification(entry, true)
                destroy()
            }
        }
    }

    ListModel { id: toastModel }

    PanelWindow {
        screen: {
            if (!root.niriState || !root.niriState.focusedWindow)
                return Quickshell.screens[0]

            var workspaceId = root.niriState.focusedWindow.workspace_id
            var output = ""
            var workspaces = root.niriState.workspaces || []
            for (var i = 0; i < workspaces.length; i++) {
                if (workspaces[i].id === workspaceId) {
                    output = workspaces[i].output || ""
                    break
                }
            }
            for (var j = 0; j < Quickshell.screens.length; j++) {
                if (Quickshell.screens[j].name === output)
                    return Quickshell.screens[j]
            }
            return Quickshell.screens[0]
        }
        color: "transparent"
        anchors { top: true; right: true }
        implicitWidth: 360
        implicitHeight: toastCol.implicitHeight + 16
        visible: toastModel.count > 0
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Column {
            id: toastCol
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 8
            width: 344
            spacing: 6

            Repeater {
                model: toastModel
                delegate: Rectangle {
                    required property var model
                    width: 344
                    height: toastContent.implicitHeight + 20
                    color: Theme.surface
                    radius: 14
                    border.color: Qt.rgba(0.306, 0.788, 0.690, 0.15)
                    border.width: 1

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: (mouse) => {
                            var entry = root.toastEntryById(model.id, model.time)
                            if (!entry) entry = root.historyEntryById(model.id)
                            if (mouse.button === Qt.LeftButton) {
                                root.activateHistoryEntry(entry || model)
                            }
                            root.takeToastEntry(model.id, model.time)
                            if (entry && entry.transient)
                                root.closeNotification(entry, false)
                            for (var i = 0; i < toastModel.count; i++) {
                                if (toastModel.get(i).id === model.id) {
                                    toastModel.remove(i)
                                    break
                                }
                            }
                        }
                    }

                    Column {
                        id: toastContent
                        anchors { left: parent.left; right: parent.right; top: parent.top }
                        anchors.margins: 12
                        spacing: 4

                        Text {
                            text: model.app
                            color: Theme.secondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Text {
                            text: model.summary
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.bold: true
                            width: parent.width
                            elide: Text.ElideRight
                            visible: model.summary !== ""
                        }
                        Text {
                            text: model.body
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            width: parent.width
                            wrapMode: Text.WordWrap
                            maximumLineCount: 4
                            elide: Text.ElideRight
                            visible: model.body !== ""
                        }
                    }
                }
            }
        }
    }
}
