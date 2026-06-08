// State contract pushed by client/panel.lua ('state' at a moderate cadence while open).
export type PanelState = {
  mode: 'manual' | 'auto'
  operatorPresent?: boolean
  running?: boolean
  spinning?: boolean
  held?: boolean
  boardable?: boolean
  platformCar?: number
  angle?: number
  degPerSec?: number
  carCount?: number
  platformDeg?: number
}

export const REASONS: Record<string, string> = {
  too_far: 'Allontanato dal quadro',
  npc_busy: "L'operatore NPC è al comando",
  held: "Rilascia prima l'emergenza",
  running: 'Ferma la ruota prima di avanzare',
  no_perm: 'Permesso negato',
}
