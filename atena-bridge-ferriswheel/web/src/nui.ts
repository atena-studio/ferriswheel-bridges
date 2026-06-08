// NUI transport bridge (same pattern as atena's web app). Lua -> SendNUIMessage({ action, ... })
// -> window 'message'; browser -> post(cb, data) -> RegisterNUICallback on the Lua side.

type Handler = (payload: Record<string, unknown>) => void
const handlers = new Map<string, Set<Handler>>()

window.addEventListener('message', (e: MessageEvent) => {
  const data = e.data as { action?: string } | undefined
  if (!data || !data.action) return
  const set = handlers.get(data.action)
  if (set) set.forEach((h) => h(data as Record<string, unknown>))
})

/** Subscribe to a message `action`; returns an unsubscribe fn. */
export function onNui(action: string, handler: Handler): () => void {
  let set = handlers.get(action)
  if (!set) {
    set = new Set()
    handlers.set(action, set)
  }
  set.add(handler)
  return () => {
    set!.delete(handler)
  }
}

// Resource name injected by CEF; falls back for a plain browser (dev).
const RES: string =
  typeof (window as unknown as { GetParentResourceName?: () => string }).GetParentResourceName === 'function'
    ? (window as unknown as { GetParentResourceName: () => string }).GetParentResourceName()
    : 'ferriswheel_bridge'

/** POST back to a registered NUI callback (intent return path). Swallows failures (dev browser). */
export function post(name: string, data?: unknown) {
  return fetch(`https://${RES}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data ?? {}),
  }).catch(() => {})
}
