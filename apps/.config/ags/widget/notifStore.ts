import { createState } from "ags"
import Notifd from "gi://AstalNotifd"

type N = ReturnType<typeof Notifd.get_default>["notifications"][0]

export type NotifEntry = {
  id: number
  app_name: string
  summary: string
  body: string
  notif: N
}

export const [history, setHistory] = createState<NotifEntry[]>([])

const PRIVATE_APPS = ["signal", "Signal"]

export function addNotif(notif: N) {
  const private_ = PRIVATE_APPS.some(a => (notif.app_name || "").toLowerCase().includes(a.toLowerCase()))
  setHistory(h => {
    if (h.some(e => e.id === notif.id)) return h
    return [...h, {
      id: notif.id,
      app_name: notif.app_name || "",
      summary: notif.summary || "",
      body: private_ ? "" : notif.body || "",
      notif,
    }]
  })
}

export function removeNotif(id: number) {
  setHistory(h => h.filter(e => e.id !== id))
}

export function clearAll() {
  const notifd = Notifd.get_default()
  for (const n of notifd.get_notifications()) {
    try { n.dismiss() } catch {}
  }
  setHistory([])
}
