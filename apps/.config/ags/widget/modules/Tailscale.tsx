import { Gtk } from "ags/gtk4"
import { execAsync } from "ags/process"
import { interval } from "ags/time"
import { createState } from "ags"

export default function Tailscale() {
  const [status, setStatus] = createState({ up: false, ip: "", peers: 0 })

  function poll() {
    execAsync("tailscale status --json").then(out => {
      try {
        const j = JSON.parse(out)
        setStatus({
          up: j.BackendState === "Running",
          ip: j.TailscaleIPs?.[0] ?? "",
          peers: Object.keys(j.Peer ?? {}).length,
        })
      } catch {}
    }).catch(() => {})
  }

  poll()
  interval(5000, poll)

  const popover = new Gtk.Popover()
  popover.set_has_arrow(false)

  const content = (
    <box orientation={Gtk.Orientation.VERTICAL} spacing={8} widthRequest={200}>
      <label label={status(s => s.up ? "󰩠  Running" : "󰩠  Stopped")} xalign={0} class="vpn-status-label" />
      <label label={status(s => s.ip ? `IP: ${s.ip}` : "No IP")} xalign={0} class="vpn-detail" />
      <label label={status(s => `Peers: ${s.peers}`)} xalign={0} class="vpn-detail" />
    </box>
  ) as unknown as Gtk.Widget

  popover.set_child(content)

  const icon = new Gtk.Image({ iconName: "tailscale", pixelSize: 16 })

  const btn = (
    <button class={status(s => `module tailscale-module${s.up ? " on" : " off"}`)}
      valign={Gtk.Align.CENTER}
      onClicked={() => execAsync(
        status().up
          ? "tailscale down"
          : `bash -lc "tailscale up && /home/end/.local/bin/mullvad-tailscale-fix || true"`
      ).then(poll)}>
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
