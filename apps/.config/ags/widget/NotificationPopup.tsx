import { Astal, Gtk, Gdk } from "ags/gtk4"
import app from "ags/gtk4/app"
import Notifd from "gi://AstalNotifd"
import Pango from "gi://Pango"
import { createBinding, For } from "ags"
import { timeout } from "ags/time"
import { addNotif, activateNotif } from "./notifStore"

type N = ReturnType<typeof Notifd.get_default>["notifications"][0]

function Toast({ notif }: { notif: N }) {
  const left = new Gtk.GestureClick()
  left.button = 1
  left.connect("pressed", () => {
    activateNotif(notif)
  })

  const gesture = new Gtk.GestureClick()
  gesture.button = 3
  gesture.connect("pressed", () => { try { notif.dismiss() } catch {} })

  const box = (
    <box class="notif-toast" orientation={Gtk.Orientation.VERTICAL} spacing={6}>
      <box spacing={8}>
        <label class="notif-app" label={notif.app_name || "notification"} xalign={0} hexpand />
        <button class="notif-close" onClicked={() => { try { notif.dismiss() } catch {} }}>
          <label label="✕" />
        </button>
      </box>
      {notif.summary
        ? <label class="notif-summary" label={notif.summary} xalign={0} wrap maxWidthChars={38} />
        : <></>
      }
      {notif.body
        ? <label class="notif-body" label={notif.body} xalign={0} wrap maxWidthChars={38} lines={4} ellipsize={Pango.EllipsizeMode.END} />
        : <></>
      }
    </box>
  ) as unknown as Gtk.Box

  box.add_controller(left)
  box.add_controller(gesture)
  return box
}

export default function NotificationPopup(gdkmonitor: Gdk.Monitor) {
  const notifd = Notifd.get_default()
  const notifs = createBinding(notifd, "notifications")
  const { TOP, RIGHT } = Astal.WindowAnchor

  notifd.connect("notified", (_self: typeof notifd, id: number) => {
    const notif = notifd.get_notification(id)
    if (!notif) return
    addNotif(notif)
    const ms = notif.expire_timeout > 0 ? notif.expire_timeout : 10000
    timeout(ms, () => { try { notif.dismiss() } catch {} })
  })

  return (
    <window
      name="notification-popup"
      class="notification-popup"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.NORMAL}
      anchor={TOP | RIGHT}
      visible={notifs(n => n.length > 0)}
      application={app}
    >
      <box orientation={Gtk.Orientation.VERTICAL} spacing={6} class="notif-popup-inner">
        <For each={notifs(ns => [...ns].slice(-3).reverse())} id={n => n.id}>
          {n => <Toast notif={n} />}
        </For>
      </box>
    </window>
  )
}
