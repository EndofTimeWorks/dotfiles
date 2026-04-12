import { Gtk } from "ags/gtk4"
import { execAsync } from "ags/process"
import { createState } from "ags"
import { interval } from "ags/time"

export default function Volume() {
  const [spk, setSpk] = createState({ vol: 0, muted: false })
  const [mic, setMic] = createState({ vol: 0, muted: false })

  function pollSpk() {
    execAsync(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"])
      .then(out => {
        const match = out.match(/Volume: ([\d.]+)/)
        setSpk({ vol: match ? Math.round(parseFloat(match[1]) * 100) : 0, muted: out.includes("[MUTED]") })
      }).catch(() => {})
  }

  function pollMic() {
    execAsync(["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"])
      .then(out => {
        const match = out.match(/Volume: ([\d.]+)/)
        setMic({ vol: match ? Math.round(parseFloat(match[1]) * 100) : 0, muted: out.includes("[MUTED]") })
      }).catch(() => {})
  }

  pollSpk(); pollMic()
  interval(1000, pollSpk)
  interval(1000, pollMic)

  const spkIcon = spk(({ vol, muted }) => {
    if (muted) return "󰝟"
    if (vol === 0) return "󰕿"
    if (vol < 50) return "󰖀"
    return "󰕾"
  })

  const popover = new Gtk.Popover()
  popover.set_has_arrow(false)

  const content = (
    <box orientation={Gtk.Orientation.VERTICAL} spacing={8} widthRequest={200}>
      <box spacing={8}>
        <label class="vol-icon module-icon" label="󰕾" />
        <label label="Speaker" hexpand xalign={0} />
        <label label={spk(v => `${v.vol}%`)} class="vol-pct" />
      </box>
      <slider
        min={0} max={150} value={spk(v => v.vol)}
        widthRequest={180}
        onNotifyValue={self => execAsync(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", `${self.value / 100}`]).catch(() => {})}
      />
      <box spacing={8}>
        <label class={mic(m => `module-icon ${m.muted ? "vol-muted" : "mic-icon"}`)} label={mic(m => m.muted ? "󰍭" : "󰍬")} />
        <label label="Mic" hexpand xalign={0} />
        <label label={mic(v => `${v.vol}%`)} class="vol-pct" />
      </box>
      <slider
        min={0} max={100} value={mic(v => v.vol)}
        widthRequest={180}
        onNotifyValue={self => execAsync(["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", `${self.value / 100}`]).catch(() => {})}
      />
      <button class="open-mixer-btn" onClicked={() => execAsync("qpwgraph").catch(() => {})}>
        <box spacing={6} halign={Gtk.Align.CENTER}>
          <label label="󰎈" class="module-icon" />
          <label label="Open mixer" />
        </box>
      </button>
    </box>
  ) as unknown as Gtk.Widget

  popover.set_child(content)

  const btn = (
    <button class="module volume-module" valign={Gtk.Align.CENTER} hexpand={false}
      onClicked={() => popover.popup()}>
      <box spacing={4}>
        <label class={spk(v => `module-icon ${v.muted ? "vol-muted" : "vol-icon"}`)} label={spkIcon} />
        <label label={spk(v => `${v.vol}%`)} />
      </box>
    </button>
  ) as unknown as Gtk.Button

  popover.set_parent(btn)
  return btn
}
