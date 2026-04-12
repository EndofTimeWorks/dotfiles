import { Gtk } from "ags/gtk4"
import { execAsync } from "ags/process"
import { createState } from "ags"
import { interval } from "ags/time"

export default function Brightness() {
  const [brightness, setBrightness] = createState({ cur: 0, max: 100 })

  function poll() {
    execAsync(["brightnessctl", "info"])
      .then(out => {
        const cur = parseInt(out.match(/Current brightness: (\d+)/)?.[1] ?? "0")
        const max = parseInt(out.match(/Max brightness: (\d+)/)?.[1] ?? "100")
        setBrightness({ cur, max })
      }).catch(() => {})
  }

  poll()
  interval(2000, poll)

  const pct = brightness(b => Math.round((b.cur / b.max) * 100))
  const icon = pct(p => p > 66 ? "󰃠" : p > 33 ? "󰃟" : "󰃞")

  const popover = new Gtk.Popover()
  popover.set_has_arrow(false)

  const content = (
    <box orientation={Gtk.Orientation.VERTICAL} spacing={8} widthRequest={200}>
      <label label="Brightness" halign={Gtk.Align.START} />
      <slider
        min={0} max={100} value={pct}
        widthRequest={180}
        onNotifyValue={self => execAsync(["brightnessctl", "set", `${Math.round(self.value)}%`]).catch(() => {})}
      />
    </box>
  ) as unknown as Gtk.Widget

  popover.set_child(content)

  const btn = (
    <button class="module brightness-module" valign={Gtk.Align.CENTER} hexpand={false}
      onClicked={() => popover.popup()}>
      <box spacing={4}>
        <label class="module-icon bright-icon" label={icon} />
        <label label={pct(p => `${p}%`)} />
      </box>
    </button>
  ) as unknown as Gtk.Button

  popover.set_parent(btn)
  return btn
}
