import { Gtk } from "ags/gtk4"
import { execAsync } from "ags/process"
import { createState } from "ags"
import { interval } from "ags/time"

interface MprisInfo {
  title: string
  artist: string
  playing: boolean
  player: string
}

const empty: MprisInfo = { title: "", artist: "", playing: false, player: "" }

export default function Media() {
  const [media, setMedia] = createState<MprisInfo>(empty)

  function poll() {
    execAsync("playerctl metadata --format '{{title}}|||{{artist}}|||{{status}}|||{{playerName}}'")
      .then(out => {
        const [title, artist, status, player] = out.trim().split("|||")
        setMedia({ title: title || "", artist: artist || "", playing: status === "Playing", player: player || "" })
      })
      .catch(() => setMedia(empty))
  }

  poll()
  interval(2000, poll)

  return (
    <box
      class="module media-module"
      valign={Gtk.Align.CENTER}
      visible={media(m => m.title !== "")}
    >
      <label
        class="media-title"
        ellipsize={3}
        maxWidthChars={24}
        label={media(m => m.title ? `${m.title}${m.artist ? " — " + m.artist : ""}` : "")}
      />
      <button class="media-btn" onClicked={() => execAsync("playerctl previous").catch(() => {})}>
        <label label="󰒮" />
      </button>
      <button class="media-btn" onClicked={() => execAsync(
        media().playing ? "playerctl pause" : "playerctl play"
      ).catch(() => {})}>
        <label label={media(m => m.playing ? "󰏤" : "󰐊")} />
      </button>
      <button class="media-btn" onClicked={() => execAsync("playerctl next").catch(() => {})}>
        <label label="󰒭" />
      </button>
    </box>
  )
}
