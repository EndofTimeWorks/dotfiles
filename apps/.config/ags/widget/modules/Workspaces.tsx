import { createState } from "ags"
import { interval } from "ags/time"
import { execAsync } from "ags/process"
import { Gtk } from "ags/gtk4"
import { For } from "ags"

interface NiriWorkspace {
  id: number
  idx: number
  name: string | null
  output: string
  is_active: boolean
  is_focused: boolean
  active_window_id: number | null
}

export default function Workspaces() {
  const [workspaces, setWorkspaces] = createState<NiriWorkspace[]>([])

  function poll() {
    execAsync(["niri", "msg", "--json", "workspaces"])
      .then(out => {
        try {
          const ws = JSON.parse(out).sort((a: NiriWorkspace, b: NiriWorkspace) => a.idx - b.idx)
          setWorkspaces(ws)
        } catch {}
      })
      .catch(() => {})
  }

  poll()
  interval(1000, poll)

  return (
    <box class="workspaces" halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER} spacing={2}>
      <For each={workspaces} id={ws => ws.id}>
        {ws => (
          <label
            class={`ws-dot ${ws.is_focused ? "focused" : ws.is_active ? "active" : ""}`}
            label={ws.is_focused ? "●" : ws.active_window_id ? "○" : "·"}
          />
        )}
      </For>
    </box>
  )
}
