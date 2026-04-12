import { Astal, Gtk, Gdk } from "ags/gtk4"
import app from "ags/gtk4/app"

import Workspaces from "./modules/Workspaces"
import WindowTitle from "./modules/WindowTitle"
import Clock from "./modules/Clock"
import Media from "./modules/Media"
import SysStats from "./modules/SysStats"
import Weather from "./modules/Weather"
import Network from "./modules/Network"
import Battery from "./modules/Battery"
import Brightness from "./modules/Brightness"
import Volume from "./modules/Volume"
import NotifBell from "./modules/NotifBell"
import Tray from "./modules/Tray"
import Mullvad from "./modules/Mullvad"
import Tailscale from "./modules/Tailscale"

export default function Bar(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible
      name="bar"
      class="bar"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      keymode={Astal.Keymode.NONE}
      anchor={TOP | LEFT | RIGHT}
      application={app}
    >
      <box halign={Gtk.Align.CENTER} widthRequest={1080}>
        <centerbox class="bar-centerbox" hexpand>
          {/* Left */}
          <box $type="start" spacing={4} halign={Gtk.Align.START} valign={Gtk.Align.CENTER}>
            <Workspaces />
            <WindowTitle />
          </box>

          {/* Center */}
          <box $type="center" spacing={4} halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}>
            <Clock />
            <Media />
          </box>

          {/* Right */}
          <box $type="end" spacing={4} halign={Gtk.Align.END} valign={Gtk.Align.CENTER}>
            <SysStats />
            <Weather />
            <Mullvad />
            <Tailscale />
            <Network />
            <Battery />
            <Brightness />
            <Volume />
            <Tray />
            <NotifBell />
          </box>
        </centerbox>
      </box>
    </window>
  )
}
