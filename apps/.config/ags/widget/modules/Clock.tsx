import { createState } from "ags"
import { interval } from "ags/time"
import { execAsync } from "ags/process"
import { Gtk } from "ags/gtk4"
import app from "ags/gtk4/app"

export default function Clock() {
  const [time, setTime] = createState("")
  const [date, setDate] = createState("")

  function pollTime() { execAsync(["date", "+%H:%M:%S"]).then(s => setTime(s.trim())).catch(() => {}) }
  function pollDate() { execAsync(["date", "+%a %b %d"]).then(s => setDate(s.trim())).catch(() => {}) }

  pollTime(); pollDate()
  interval(1000, pollTime)
  interval(60000, pollDate)

  return (
    <button class="module clock-module" halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}
      hexpand={false} onClicked={() => app.toggle_window("clock-center")}>
      <box spacing={6}>
        <label class="time" label={time} />
        <label class="date" label={date} />
      </box>
    </button>
  )
}
