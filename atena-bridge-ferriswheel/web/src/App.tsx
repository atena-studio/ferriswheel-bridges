// Ferris wheel operator control DESK (React port of the vanilla nui/app.js — same NUI contract).
// Physical controls (throw levers + a mode toggle) act on the wheel; the screen DISPLAYS the live
// turning wheel + status + message log. Lua side (client/panel.lua) unchanged: pushes
// { action: 'open'|'close'|'state'|'toast' }, receives the same callback names.
import { useEffect, useRef, useState } from 'react'
import clsx from 'clsx'
import { Led, Lever, ModeToggle, Monitor } from './components/parts'
import { Dial, platformCarOf } from './components/Dial'
import { type PanelState, REASONS } from './types'
import { post } from './nui'
import { useNuiEvent } from './hooks'

type LogLine = { ts: string; text: string; kind: 'ok' | 'warn' | 'bad' }

export default function App() {
  const [open, setOpen] = useState(false)
  const [prewarm, setPrewarm] = useState(true)
  const [s, setS] = useState<PanelState | null>(null)
  const [log, setLog] = useState<LogLine[]>([])
  const [platformCar, setPlatformCar] = useState(0)
  const [pulled, setPulled] = useState(false)
  const sRef = useRef<PanelState | null>(null)
  sRef.current = s

  const logLine = (text: string, kind: LogLine['kind']) => {
    const d = new Date()
    const ts = [d.getHours(), d.getMinutes(), d.getSeconds()].map((n) => String(n).padStart(2, '0')).join(':')
    setLog((cur) => [...cur, { ts, text, kind }].slice(-5))
  }

  useNuiEvent('open', () => { setOpen(true); logLine('Quadro online', 'ok') })
  useNuiEvent('close', () => setOpen(false))
  useNuiEvent<PanelState>('state', (d) => setS(d))
  useNuiEvent<{ reason?: string }>('toast', (d) => logLine(REASONS[d.reason ?? ''] ?? d.reason ?? '', 'bad'))

  useEffect(() => {
    if (!open) return
    const k = (e: KeyboardEvent) => {
      if (e.key === 'Escape') { setOpen(false); post('close', {}) }
    }
    window.addEventListener('keyup', k)
    return () => window.removeEventListener('keyup', k)
  }, [open])

  // Prewarm (nui.md §4): rasterize the cabinet textures once at load so the first open is instant.
  useEffect(() => {
    let r2 = 0
    const r1 = requestAnimationFrame(() => { r2 = requestAnimationFrame(() => setPrewarm(false)) })
    return () => { cancelAnimationFrame(r1); cancelAnimationFrame(r2) }
  }, [])

  const auto = s?.mode === 'auto'
  const present = !!s?.operatorPresent
  const npcRunning = auto && present // NPC has the desk -> manual controls locked
  const canStep = !!s && !s.held && !npcRunning
  const stateLabel = !s ? '—' : s.held ? 'HOLD' : s.spinning ? 'IN CORSA' : 'FERMA'
  // platform car from the SAME smooth angle the dial renders (fallback before the first dial tick)
  const carShown = s?.boardable
    ? `#${platformCar || platformCarOf(s.angle ?? 0, s.carCount ?? 16, s.platformDeg ?? -21.5)}`
    : '—'

  const pullStep = () => {
    setPulled(true)
    window.setTimeout(() => setPulled(false), 220)
    post('step', {})
  }

  const visible = open || prewarm
  const ghost = prewarm && !open ? ({ opacity: 0, pointerEvents: 'none' } as const) : undefined
  return (
    <>
      <div id="scene">
        <div id="panel" className={clsx(!visible && 'hidden')} style={ghost}>
          <div className="cabinet">
            <span className="tex tex-case" aria-hidden="true" />
            <span className="softbox" aria-hidden="true" />

            <div className="brandbar">
              <span className="brand">DEL PERRO · FERRIS WHEEL CONTROL</span>
              <span className="serial">UNIT 01 / REV A</span>
              <i className="screw tl" /><i className="screw tr" />
            </div>

            {/* ===== ONE CRT MONITOR: wheel dial + status + message log ===== */}
            <div className="monitors">
              <Monitor kind="status">
                <div className="mon-title">RUOTA PANORAMICA</div>
                <Dial s={s} onPlatformCar={setPlatformCar} />
                <div className="readout">
                  <div className="ro"><span>STATO</span><b>{stateLabel}</b></div>
                  <div className="ro"><span>ANGOLO</span><b>{Math.round(s?.angle ?? 0)}°</b></div>
                  <div className="ro"><span>CABINA</span><b>{carShown}</b></div>
                </div>
                <div className="loglabel">MESSAGGI</div>
                <div className="status-log">
                  {log.map((l, i) => (
                    <div key={i} className={clsx('line', l.kind)}>
                      <span className="t">{l.ts}</span>{l.text}
                    </div>
                  ))}
                </div>
              </Monitor>
            </div>

            {/* ===== PHYSICAL CONTROL DECK ===== */}
            <div className="deck">
              <span className="tex tex-deck" aria-hidden="true" />
              <div className="leds">
                <Led color="red" on={!!s?.spinning && !s?.held} label="CORSA" />
                <Led color="grn" on={!!s && !s.spinning && !s.held} label="FERMA" />
                <Led color="amber" on={!!s?.boardable && !!s?.platformCar} label="BOARD" />
                <Led color="red" on={!!s?.held} label="HOLD" />
              </div>
              <div className="controls">
                <Lever
                  down={!!s?.running} lit={!!s?.spinning}
                  disabled={npcRunning || !!s?.held}
                  plate="RUN/STOP"
                  onPull={() => post('run', { run: !s?.running })}
                />
                <Lever
                  role="go"
                  blink={canStep && !s?.spinning} pulled={pulled}
                  disabled={!canStep}
                  plate="STEP"
                  onPull={pullStep}
                />
                <Lever
                  role="stop"
                  down={!!s?.held} blink={!!s?.held}
                  disabled={npcRunning}
                  plate={s?.held ? 'RIPRENDI' : 'EMERGENZA'}
                  onPull={() => post('estop', {})}
                />
                <ModeToggle
                  auto={!!auto}
                  busy={!!auto && !present}
                  note={!auto ? 'manuale' : present ? 'auto' : 'in arrivo…'}
                  onFlip={() => post(auto ? 'dismissOperator' : 'callOperator', {})}
                />
              </div>
            </div>

            <div className="foot">
              <span className={npcRunning ? 'mode-auto' : 'mode-manual'} id="mode-badge">
                {auto ? (present ? 'AUTO' : 'AUTO · assente') : 'MANUALE'}
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* post-processing ONLY while the desk is up (a mounted vignette would tint the screen
          with the panel closed); prewarmed transparent so its texture is cached too. */}
      {visible ? (
        <div id="post" aria-hidden="true" style={ghost}>
          <span className="grain" />
          <span className="vignette" />
        </div>
      ) : null}
    </>
  )
}
