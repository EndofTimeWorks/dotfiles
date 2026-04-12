import { Gtk } from "ags/gtk4"
import { createState } from "ags"
import { interval } from "ags/time"
import { execAsync } from "ags/process"

export default function SysStats() {
  const [cpu, setCpu] = createState("0")
  const [ram, setRam] = createState("0")

  function pollCpu() {
    execAsync(["bash", "-c", "grep -m1 '^cpu ' /proc/stat | awk '{u=$2+$4; t=$2+$3+$4+$5; if(t>0) print int(u/t*100); else print 0}'"]).then(s => setCpu(s.trim())).catch(() => {})
  }

  function pollRam() {
    execAsync(["bash", "-c", "free | awk '/^Mem:/{printf \"%d\", $3/$2*100}'"]).then(s => setRam(s.trim())).catch(() => {})
  }

  pollCpu()
  pollRam()
  interval(2000, pollCpu)
  interval(5000, pollRam)

  return (
    <box class="module sysstat-module" valign={Gtk.Align.CENTER} spacing={8}>
      <box spacing={4}>
        <label class="module-icon stat-icon" label="󰻠" />
        <label class="stat-label" label={cpu(c => `${c}%`)} />
      </box>
      <box spacing={4}>
        <label class="module-icon stat-icon" label="󰍛" />
        <label class="stat-label" label={ram(r => `${r}%`)} />
      </box>
    </box>
  )
}
