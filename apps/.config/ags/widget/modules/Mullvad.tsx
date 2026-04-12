import { Gtk } from "ags/gtk4"
import { execAsync } from "ags/process"
import { interval } from "ags/time"
import { createState } from "ags"

const FAVORITES = [
  { label: "Phoenix", cmd: "mullvad relay set location us phx" },
  { label: "Los Angeles", cmd: "mullvad relay set location us lax" },
  { label: "Switzerland", cmd: "mullvad relay set location ch" },
]

export default function Mullvad() {
  const [status, setStatus] = createState({ connected: false, location: "", ip: "" })

  function poll() {
    execAsync("mullvad status").then(out => {
      const connected = out.toLowerCase().startsWith("connected")
      const locMatch = out.match(/location:\s+(.+?)\./)
      const ipMatch = out.match(/IPv4:\s+([\d.]+)/)
      setStatus({ connected, location: locMatch?.[1]?.trim() ?? "", ip: ipMatch?.[1] ?? "" })
    }).catch(() => {})
  }

  poll()
  interval(5000, poll)

  const popover = new Gtk.Popover()
  popover.set_has_arrow(false)

  const favBtns = FAVORITES.map(({ label, cmd }) => (
    <button class="open-mixer-btn" onClicked={() =>
      execAsync(cmd).then(() => execAsync("mullvad reconnect")).then(() => poll()).catch(() => poll())
    }>
      <label label={label} />
    </button>
  ))

  const content = (
    <box orientation={Gtk.Orientation.VERTICAL} spacing={8} widthRequest={200}>
      <label label={status(s => s.connected ? "󰦝  Connected" : "󰛡  Disconnected")} xalign={0} class="vpn-status-label" />
      <label label={status(s => s.location || "—")} xalign={0} class="vpn-detail" />
      <label label={status(s => s.ip || "—")} xalign={0} class="vpn-detail" />
      <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
        {favBtns}
      </box>
      <button class="open-mixer-btn" onClicked={() => execAsync("mullvad-vpn")}>
        <label label="Open Mullvad" />
      </button>
    </box>
  ) as unknown as Gtk.Widget

  popover.set_child(content)

  const icon = new Gtk.Image({ iconName: "mullvad-vpn", pixelSize: 16 })

  const btn = (
    <button class={status(s => `module mullvad-module${s.connected ? " on" : " off"}`)}
      valign={Gtk.Align.CENTER}
      onClicked={() => execAsync(
        status().connected
          ? "mullvad disconnect"
          : "bash -c 'mullvad lan set allow && mullvad connect'"
      ).then(() => poll()).catch(() => poll())}>
    </button>
  ) as unknown as Gtk.Button

  btn.set_child(icon)

  const gesture = new Gtk.GestureClick()
  gesture.button = 3
  gesture.connect("pressed", () => popover.popup())
  btn.add_controller(gesture)
  popover.set_parent(btn)

  return btn
}
