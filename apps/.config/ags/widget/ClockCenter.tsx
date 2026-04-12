import { Astal, Gtk, Gdk } from "ags/gtk4"
import app from "ags/gtk4/app"
import { execAsync } from "ags/process"
import { createState, createComputed, For } from "ags"
import { interval } from "ags/time"

const TIMEZONES = [
  "America/Phoenix", "America/New_York", "America/Chicago",
  "America/Denver", "America/Los_Angeles", "America/Anchorage",
  "Pacific/Honolulu", "Europe/London", "Europe/Paris",
  "Europe/Berlin", "Europe/Rome", "Europe/Moscow",
  "Asia/Dubai", "Asia/Kolkata", "Asia/Bangkok",
  "Asia/Shanghai", "Asia/Tokyo", "Asia/Seoul",
  "Australia/Sydney", "Pacific/Auckland",
]

export default function ClockCenter(gdkmonitor: Gdk.Monitor) {
  const { TOP } = Astal.WindowAnchor

  const [time, setTime] = createState("")
  const [date, setDate] = createState("")
  const [tz, setTz] = createState("")

  function pollTime() { execAsync(["date", "+%H:%M:%S"]).then(s => setTime(s.trim())).catch(() => {}) }
  function pollDate() { execAsync(["date", "+%A, %B %d"]).then(s => setDate(s.trim())).catch(() => {}) }
  function pollTz() { execAsync(["date", "+%Z"]).then(s => setTz(s.trim())).catch(() => {}) }

  pollTime(); pollDate(); pollTz()
  interval(1000, pollTime)
  interval(60000, pollDate)
  interval(10000, pollTz)

  const [search, setSearch] = createState("")
  const filtered = createComputed(() => {
    const q = search().toLowerCase()
    return TIMEZONES.filter(t => t.toLowerCase().includes(q))
  })

  const win = (
    <window
      visible={false}
      name="clock-center"
      class="notification-center"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.NORMAL}
      anchor={TOP}
      marginTop={42}
      keymode={Astal.Keymode.ON_DEMAND}
      application={app}
      onNotifyIsActive={({ isActive }: { isActive: boolean }) => {
        if (!isActive) app.toggle_window("clock-center")
      }}
    >
      <box orientation={Gtk.Orientation.VERTICAL} spacing={10} class="clock-center-inner" widthRequest={260}>
        <Gtk.EventControllerKey
          onKeyPressed={(_self: unknown, keyval: number) => {
            if (keyval === Gdk.KEY_Escape) app.toggle_window("clock-center")
          }}
        />
        <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
          <label label={time} class="time" xalign={0} />
          <label label={date} class="clock-tz-label" xalign={0} />
          <label label={tz} class="clock-section-title" xalign={0} />
        </box>
        <Gtk.Calendar showDayNames showHeading />
        <label label="Switch timezone" xalign={0} class="clock-section-title" />
        <entry
          placeholderText="Search..."
          onNotifyText={({ text }: { text: string }) => setSearch(text)}
        />
        <scrolledwindow maxContentHeight={160} vexpand>
          <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
            <For each={filtered} id={zone => zone}>
              {zone => (
                <button class="tz-btn" onClicked={() => {
                  execAsync(["timedatectl", "set-timezone", zone]).catch(() => {})
                  app.toggle_window("clock-center")
                }}>
                  <label label={zone} xalign={0} />
                </button>
              )}
            </For>
          </box>
        </scrolledwindow>
      </box>
    </window>
  ) as unknown as Astal.Window

  return win
}
