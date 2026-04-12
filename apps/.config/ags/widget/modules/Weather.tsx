import { Gtk } from "ags/gtk4"
import GLib from "gi://GLib"
import { execAsync } from "ags/process"
import { interval } from "ags/time"
import { createState, createEffect } from "ags"

const UNIT_FILE = `${GLib.get_home_dir()}/.config/ags/.weather-unit`
const LOCATION = "Phoenix"

function readUnit(): "m" | "u" {
  try {
    const [ok, contents] = GLib.file_get_contents(UNIT_FILE)
    return ok && new TextDecoder().decode(contents).trim() === "u" ? "u" : "m"
  } catch { return "m" }
}

export default function Weather() {
  const [unit, setUnit] = createState<"m" | "u">(readUnit())
  const [text, setText] = createState("")

  function fetch() {
    execAsync(`curl -sf 'wttr.in/${LOCATION}?format=%c%t&${unit()}'`)
      .then(s => setText(s.trim().replace(/\s+/g, " ").replace(/\+(\d)/g, "$1")))
      .catch(() => {})
  }

  createEffect(() => {
    unit() // subscribe — re-fetch when unit changes
    fetch()
  })

  interval(1800000, fetch)

  return (
    <box class="module weather-module" valign={Gtk.Align.CENTER} spacing={4} visible={text(t => t !== "")}>
      <label class="weather-text" label={text} />
      <button
        class="unit-toggle"
        onClicked={() => {
          const next: "m" | "u" = unit() === "m" ? "u" : "m"
          setUnit(next)
          execAsync(`bash -c "echo ${next} > ${UNIT_FILE}"`)
        }}
      >
        <label label={unit(u => u === "m" ? "°C" : "°F")} />
      </button>
    </box>
  )
}
