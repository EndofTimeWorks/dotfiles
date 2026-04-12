import { Gtk } from "ags/gtk4"
import app from "ags/gtk4/app"
import { history } from "../notifStore"

export default function NotifBell() {
  return (
    <button
      class={history(h => `module notif-bell${h.length > 0 ? " has-notifs" : ""}`)}
      valign={Gtk.Align.CENTER}
      onClicked={() => app.toggle_window("notification-center")}
    >
      <box spacing={4}>
        <label
          class="module-icon bell-icon"
          label={history(h => h.length > 0 ? "󰂚" : "󰂜")}
        />
        <label
          class="bell-count"
          label={history(h => `${h.length}`)}
          visible={history(h => h.length > 0)}
        />
      </box>
    </button>
  )
}
