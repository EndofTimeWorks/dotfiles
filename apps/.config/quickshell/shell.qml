//@ pragma UseQApplication
import Quickshell
import "modules"

Scope {
    NiriState {
        id: niriState
    }

    NotificationPopup {
        id: notifications
        niriState: niriState
    }

    Dimmer {
        id: dimmer
    }

    Bar {
        niriState: niriState
        notifUnread: notifications.unread
        notifHistory: notifications.history
        notifMode: notifications.mode
        notifActivateFn: (entry) => notifications.activateHistoryEntry(entry)
        notifSetModeFn: (mode) => notifications.setMode(mode)
        onNotifCleared: notifications.markRead()
        onNotifHistoryCleared: notifications.clearHistory()
        dimAmount: dimmer.dimAmount
        onDimChanged: (val) => dimmer.dimAmount = val
    }
}
