import app from "ags/gtk4/app"
import style from "./style.scss"
import Bar from "./widget/Bar"
import NotificationCenter from "./widget/NotificationCenter"
import NotificationPopup from "./widget/NotificationPopup"
import ClockCenter from "./widget/ClockCenter"

app.start({
  css: style,
  main() {
    const monitors = app.get_monitors()
    monitors.map(Bar)

    const popupMonitor = monitors[0]
    if (!popupMonitor) return

    NotificationCenter(popupMonitor)
    NotificationPopup(popupMonitor)
    ClockCenter(popupMonitor)
  },
})
