//@ pragma UseQApplication
import Quickshell

Scope {
    NotificationPopup {
        id: notifications
    }

    Dimmer {
        id: dimmer
    }

    Bar {
        notifUnread: notifications.unread
        notifHistory: notifications.history
        notifActivateFn: (entry) => notifications.activateHistoryEntry(entry)
        onNotifCleared: notifications.markRead()
        onNotifHistoryCleared: notifications.clearHistory()
        dimAmount: dimmer.dimAmount
        onDimChanged: (val) => dimmer.dimAmount = val
    }
}
