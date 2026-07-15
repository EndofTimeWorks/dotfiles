import Quickshell.Io
import QtQuick

Item {
    id: root

    property var workspaces: []
    property var windows: []
    property var focusedWindowId: null
    readonly property var focusedWindow: {
        if (focusedWindowId !== null) {
            for (var i = 0; i < windows.length; i++) {
                if (windows[i].id === focusedWindowId)
                    return windows[i]
            }
        }

        for (var i = 0; i < windows.length; i++) {
            if (windows[i].is_focused)
                return windows[i]
        }
        return null
    }

    function replaceWorkspace(id, update) {
        var next = workspaces.slice()
        for (var i = 0; i < next.length; i++) {
            if (next[i].id === id) {
                next[i] = Object.assign({}, next[i], update)
                workspaces = next
                return
            }
        }
    }

    function activateWorkspace(data) {
        var target = null
        for (var i = 0; i < workspaces.length; i++) {
            if (workspaces[i].id === data.id) {
                target = workspaces[i]
                break
            }
        }
        if (!target) return

        var next = []
        for (var j = 0; j < workspaces.length; j++) {
            var workspace = workspaces[j]
            var update = {}
            if (workspace.output === target.output)
                update.is_active = workspace.id === data.id
            if (data.focused)
                update.is_focused = workspace.id === data.id
            next.push(Object.assign({}, workspace, update))
        }
        workspaces = next
    }

    function upsertWindow(window) {
        var next = windows.slice()
        for (var i = 0; i < next.length; i++) {
            if (next[i].id === window.id) {
                next[i] = window
                windows = next
                if (window.is_focused) focusedWindowId = window.id
                return
            }
        }
        next.push(window)
        windows = next
        if (window.is_focused) focusedWindowId = window.id
    }

    function removeWindow(id) {
        windows = windows.filter(window => window.id !== id)
        if (focusedWindowId === id) focusedWindowId = null
    }

    function handleEvent(line) {
        if (!line) return

        try {
            var event = JSON.parse(line)
            if (event.WorkspacesChanged) {
                var nextWorkspaces = event.WorkspacesChanged.workspaces || []
                nextWorkspaces.sort((a, b) => a.idx - b.idx)
                workspaces = nextWorkspaces
            } else if (event.WorkspaceActivated) {
                activateWorkspace(event.WorkspaceActivated)
            } else if (event.WorkspaceActiveWindowChanged) {
                var active = event.WorkspaceActiveWindowChanged
                replaceWorkspace(active.workspace_id, { active_window_id: active.active_window_id })
            } else if (event.WindowsChanged) {
                windows = event.WindowsChanged.windows || []
                focusedWindowId = null
                for (var i = 0; i < windows.length; i++) {
                    if (windows[i].is_focused) {
                        focusedWindowId = windows[i].id
                        break
                    }
                }
            } else if (event.WindowOpenedOrChanged) {
                upsertWindow(event.WindowOpenedOrChanged.window)
            } else if (event.WindowClosed) {
                removeWindow(event.WindowClosed.id)
            } else if (event.WindowFocusChanged) {
                focusedWindowId = event.WindowFocusChanged.id
            }
        } catch (error) {
            console.warn("Could not parse Niri event:", error)
        }
    }

    Process {
        id: eventStream
        running: true
        command: ["niri", "msg", "--json", "event-stream"]
        stdout: SplitParser {
            onRead: line => root.handleEvent(line)
        }
        onExited: restartTimer.restart()
    }

    Timer {
        id: restartTimer
        interval: 2000
        onTriggered: eventStream.running = true
    }
}
