import { Gtk } from "ags/gtk4"
import { execAsync } from "ags/process"
import { createState } from "ags"
import { interval } from "ags/time"

interface BatState {
  pct: number
  charging: boolean
  timeLeft: string
}

function parseBat(out: string): BatState {
  const lines = out.split("\n")
  let pct = 100, charging = false, timeLeft = ""
  for (const line of lines) {
    const l = line.trim()
    if (l.startsWith("percentage:")) pct = parseInt(l.split(":")[1]) || 100
    if (l.startsWith("state:")) charging = l.includes("charging") && !l.includes("discharging")
    if (l.startsWith("time to empty:") || l.startsWith("time to full:"))
      timeLeft = `~${l.split(":").slice(1).join(":").trim()}`
  }
  return { pct, charging, timeLeft }
}

export default function Battery() {
  const [bat, setBat] = createState<BatState>({ pct: 100, charging: false, timeLeft: "" })

  function poll() {
    execAsync(["upower", "-i", "/org/freedesktop/UPower/devices/battery_BAT1"])
      .then(out => setBat(parseBat(out)))
      .catch(() => {})
  }

  poll()
  interval(5000, poll)

  const popover = new Gtk.Popover()
  popover.set_has_arrow(false)

  const content = (
    <box orientation={Gtk.Orientation.VERTICAL} spacing={8} widthRequest={160}>
      <label label={bat(b => `${b.pct}%`)} xalign={0} class="vpn-status-label" />
      <label
        label={bat(b => b.charging
          ? b.timeLeft ? `${b.timeLeft} until full` : "Charging"
          : b.timeLeft ? `${b.timeLeft} remaining` : "Discharging"
        )}
        xalign={0}
        class="vpn-detail"
      />
    </box>
  ) as unknown as Gtk.Widget

  popover.set_child(content)

  const btn = (
    <button class="module battery-module" valign={Gtk.Align.CENTER}
      onClicked={() => popover.popup()}>
      <box spacing={4}>
        <label
          class={bat(b => `module-icon ${b.charging ? "bat-charging" : b.pct < 20 ? "bat-low" : "bat-icon"}`)}
          label={bat(({ pct, charging }) => {
            if (charging) return "󰂄"
            if (pct > 80) return "󰁹"
            if (pct > 60) return "󰂁"
            if (pct > 40) return "󰁾"
            if (pct > 20) return "󰁼"
            return "󰁺"
          })}
        />
        <label class="bat-label" label={bat(b => `${b.pct}%`)} />
      </box>
    </button>
  ) as unknown as Gtk.Button

  popover.set_parent(btn)
  return btn
}
