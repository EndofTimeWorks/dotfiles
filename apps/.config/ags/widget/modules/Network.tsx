import { Gtk } from "ags/gtk4"
import { execAsync } from "ags/process"
import { createState } from "ags"
import { interval } from "ags/time"

type NetState = { type: "none" | "wifi" | "wired" | "rfkill"; ssid: string; strength: number; ip: string }

export default function Network() {
  const [net, setNet] = createState<NetState>({ type: "none", ssid: "", strength: 0, ip: "" })
  const [showIp, setShowIp] = createState(false)

  function poll() {
    execAsync(["bash", "-c", "rfkill list wifi | grep -q 'Hard blocked: yes\\|Soft blocked: yes' && echo rfkill; nmcli -t -f device,type,state dev 2>/dev/null | grep ':ethernet:connected' | head -1; echo '---'; nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | grep '^yes' | head -1; echo '---'; ip -4 route get 1.1.1.1 2>/dev/null | grep -oP '(?<=src )[\\d.]+'"])
      .then(out => {
        if (out.startsWith("rfkill")) { setNet({ type: "rfkill", ssid: "", strength: 0, ip: "" }); return }
        const [eth, wifi, ip] = out.split("---").map((s: string) => s.trim())
        if (eth) { setNet({ type: "wired", ssid: "", strength: 0, ip: ip || "" }); return }
        const parts = wifi?.split(":") ?? []
        if (parts.length >= 3 && parts[0] === "yes")
          setNet({ type: "wifi", ssid: parts[1], strength: parseInt(parts[2]) || 0, ip: ip || "" })
        else
          setNet({ type: "none", ssid: "", strength: 0, ip: "" })
      }).catch(() => {})
  }

  poll()
  interval(5000, poll)

  const icon = net(n => {
    if (n.type === "rfkill") return "󰖪"
    if (n.type === "wired") return "󰈀"
    if (n.type === "none") return "󰤭"
    if (n.strength > 75) return "󰤨"
    if (n.strength > 50) return "󰤥"
    if (n.strength > 25) return "󰤢"
    return "󰤟"
  })

  const labelText = net(n => {
    if (n.type === "rfkill") return "rfkill"
    if (showIp()) return n.ip || "no ip"
    if (n.type === "wired") return "wired"
    if (n.type === "wifi") return n.ssid || "connected"
    return "offline"
  })

  return (
    <button class="module network-module" valign={Gtk.Align.CENTER} onClicked={() => setShowIp(v => !v)}>
      <box spacing={4}>
        <label class={net(n => `module-icon ${n.type !== "none" && n.type !== "rfkill" ? "net-icon" : "net-disconnected"}`)} label={icon} />
        <label label={labelText} />
        <label
          class="net-strength"
          label={net(n => `${n.strength}%`)}
          visible={net(n => n.type === "wifi" && !showIp())}
        />
      </box>
    </button>
  )
}
