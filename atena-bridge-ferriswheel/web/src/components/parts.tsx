// Shared physical-deck parts: indicator Led, throw Lever, mode Toggle, CRT Monitor shell.
// SAME design language as rollercoaster_bridge/web/src/components/parts.tsx (keep in sync).
import clsx from 'clsx'

export function Led({ id, color, on, label }: { id?: string; color: 'red' | 'grn' | 'amber'; on: boolean; label: string }) {
  return (
    <div id={id} className={clsx('led', color, on && 'on')}>
      <i />
      {label}
    </div>
  )
}

export function Lever({
  role, down, lit, blink, pulled, disabled, plate, onPull,
}: {
  role?: 'go' | 'stop'
  down?: boolean
  lit?: boolean
  blink?: boolean
  pulled?: boolean
  disabled?: boolean
  plate: React.ReactNode
  onPull: () => void
}) {
  return (
    <div className="lever-unit">
      <div
        className={clsx('lever', role, down && 'down', lit && 'lit', blink && 'blink', pulled && 'pulled', disabled && 'disabled')}
        onClick={() => { if (!disabled) onPull() }}
      >
        <span className="track" />
        <span className="knob" />
      </div>
      <div className="plate">{plate}</div>
    </div>
  )
}

export function ModeToggle({
  auto, busy, note, onFlip,
}: { auto: boolean; busy: boolean; note: string; onFlip: () => void }) {
  return (
    <div className="switch-unit">
      <div className={clsx('toggle', auto && 'auto', busy && 'busy')} onClick={() => { if (!busy) onFlip() }}>
        <span className="bat" />
      </div>
      <div className="plate">
        <span className="pos-man">MAN</span> · <span className="pos-auto">AUTO</span>
      </div>
      <div className="swhint">{note}</div>
    </div>
  )
}

/** CRT monitor shell: gloss bezel + glass softbox + phosphor screen (+ scanlines). */
export function Monitor({ kind, children }: { kind: 'map' | 'status'; children: React.ReactNode }) {
  return (
    <div className={clsx('monitor', kind === 'map' ? 'mon-map' : 'mon-status')}>
      <span className="bezel" aria-hidden="true" />
      <span className="glass" aria-hidden="true" />
      <div className="screen">
        <span className="scan" aria-hidden="true" />
        {children}
      </div>
    </div>
  )
}
