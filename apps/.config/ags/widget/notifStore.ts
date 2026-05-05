import { createState } from "ags"
import { execAsync } from "ags/process"
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

function launchDesktopEntry(desktopEntry: string) {
  const id = desktopEntry.endsWith(".desktop")
    ? desktopEntry.slice(0, -8)
    : desktopEntry

  if (!id) return
  execAsync(["gtk-launch", id]).catch(() => {})
}

function hasDefaultAction(rawActions: unknown): boolean {
  if (!Array.isArray(rawActions)) return false
  return rawActions.some(a => typeof a === "string" && a.toLowerCase() === "default")
}

function desktopEntryFromNotif(notif: N): string {
  const value = ((notif as unknown as { get_desktop_entry?: () => string }).get_desktop_entry?.()
    ?? (notif as unknown as { desktop_entry?: string }).desktop_entry
    ?? "")
  return String(value).trim()
}

function appNameFromNotif(notif: N): string {
  const value = ((notif as unknown as { get_app_name?: () => string }).get_app_name?.()
    ?? (notif as unknown as { app_name?: string }).app_name
    ?? "")
  return String(value).trim()
}

const APP_NAME_FALLBACKS: Record<string, string> = {
  discord: "discord",
  signal: "signal-desktop",
  slack: "slack",
  thunderbird: "org.mozilla.Thunderbird",
  "zen browser": "zen",
  zen: "zen",
  obsidian: "obsidian",
  helium: "helium",
}

export function activateNotif(notif: N) {
  const actions = ((notif as unknown as { get_actions?: () => unknown }).get_actions?.()
    ?? (notif as unknown as { actions?: unknown }).actions)

  if (hasDefaultAction(actions)) {
    try {
      notif.invoke("default")
      return
    } catch {}
  }

  const desktopEntry = desktopEntryFromNotif(notif)
  if (desktopEntry) {
    launchDesktopEntry(desktopEntry)
    return
  }

  const appName = appNameFromNotif(notif).toLowerCase()
  const mapped = APP_NAME_FALLBACKS[appName]
  if (mapped) launchDesktopEntry(mapped)
}
