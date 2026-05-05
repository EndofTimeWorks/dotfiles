import { Astal, Gtk, Gdk } from "ags/gtk4"
import app from "ags/gtk4/app"
import { For } from "ags"
import { history, removeNotif, clearAll, activateNotif, type NotifEntry } from "./notifStore"

function NotifCard({ entry }: { entry: NotifEntry }) {
  const rightClick = new Gtk.GestureClick()
  rightClick.button = 3
  rightClick.connect("pressed", () => {
    removeNotif(entry.id)
    try { entry.notif.dismiss() } catch {}
  })

  // Left click only fires when clicking the card background (not child widgets)
  const leftClick = new Gtk.GestureClick()
  leftClick.button = 1
  leftClick.propagation_phase = Gtk.PropagationPhase.TARGET
  leftClick.connect("pressed", () => {
    activateNotif(entry.notif)
    app.toggle_window("notification-center")
  })

  const box = (
    <box class="notif-card" orientation={Gtk.Orientation.VERTICAL} spacing={6}>
      <box spacing={8}>
        <label class="notif-app" label={entry.app_name || "notification"} xalign={0} hexpand />
        <button class="notif-close" onClicked={() => {
          removeNotif(entry.id)
          try { entry.notif.dismiss() } catch {}
        }}>
          <label label="✕" />
        </button>
      </box>
      {entry.summary
        ? <label class="notif-summary" label={entry.summary} xalign={0} wrap maxWidthChars={36} />
        : <></>
      }
      {entry.body
        ? <label class="notif-body" label={entry.body} xalign={0} wrap maxWidthChars={36} />
        : <></>
      }
    </box>
  ) as unknown as Gtk.Box

  box.add_controller(leftClick)
  box.add_controller(rightClick)
  return box
}

export default function NotificationCenter(gdkmonitor: Gdk.Monitor) {
  const { RIGHT, TOP, BOTTOM } = Astal.WindowAnchor

  return (
    <window
      visible={false}
      name="notification-center"
      class="notification-center"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.NORMAL}
      anchor={RIGHT | TOP | BOTTOM}
      keymode={Astal.Keymode.ON_DEMAND}
      application={app}
    >
      <box orientation={Gtk.Orientation.VERTICAL} spacing={8} class="notif-center-inner">
        <Gtk.EventControllerKey
          onKeyPressed={({ widget }, keyval: number) => {
            if (keyval === Gdk.KEY_Escape) app.toggle_window("notification-center")
          }}
        />
        <box class="notif-center-header">
          <label class="notif-center-title" label="Notifications" hexpand xalign={0} />
          <button class="notif-clear-all" onClicked={() => clearAll()}>
            <label label="Clear all" />
          </button>
        </box>
        <label
          class="notif-empty"
          label="Nothing here"
          valign={Gtk.Align.CENTER}
          vexpand
          visible={history(h => h.length === 0)}
        />
        <scrolledwindow
          vexpand
          visible={history(h => h.length > 0)}
          vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
          hscrollbarPolicy={Gtk.PolicyType.NEVER}
        >
          <box orientation={Gtk.Orientation.VERTICAL} spacing={6}>
            <For each={history(h => [...h].reverse())} id={e => e.id}>
              {e => <NotifCard entry={e} />}
            </For>
          </box>
        </scrolledwindow>
      </box>
    </window>
  )
}
