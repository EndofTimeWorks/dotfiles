import { createState } from "ags"
import { interval } from "ags/time"
import { execAsync } from "ags/process"
import { Gtk } from "ags/gtk4"

interface NiriWindow {
  title: string | null
  app_id: string | null
}

export default function WindowTitle() {
  const [win, setWin] = createState<NiriWindow>({ title: null, app_id: null })

  function poll() {
    execAsync(["niri", "msg", "--json", "focused-window"])
      .then(out => { try { setWin(JSON.parse(out)) } catch {} })
      .catch(() => setWin({ title: null, app_id: null }))
  }

  poll()
  interval(1000, poll)

  return (
    <label
      class="window-title"
      halign={Gtk.Align.START}
      ellipsize={3}
      maxWidthChars={40}
      label={win(w => w.title ?? w.app_id ?? "")}
    />
  )
}
