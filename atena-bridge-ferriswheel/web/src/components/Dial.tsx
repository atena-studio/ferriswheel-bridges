// The turning wheel dial (smooth, client-interpolated — nui.md §3). The server publishes the
// angle at a moderate cadence; rendering it raw makes the gondolas step. We keep a LOCAL float
// angle, advance it every animation frame by the wheel's deg/s while spinning, and continuously
// ease it toward the latest server angle (shortest path) to correct drift. The gondola at the
// loading platform is computed locally from the same smooth angle, so the highlight tracks the
// motion exactly. SVG updated imperatively via refs — the 60Hz loop never re-renders React.
import { useEffect, useRef } from 'react'
import clsx from 'clsx'
import { type PanelState } from '../types'

const SVGNS = 'http://www.w3.org/2000/svg'
const R = 44, CX = 60, CY = 60

const angShort = (a: number, b: number) => (((b - a) % 360) + 540) % 360 - 180 // signed delta [-180,180]

export function platformCarOf(angle: number, carCount: number, platformDeg: number): number {
  let best = 1, bestD = 1e9
  for (let i = 0; i < carCount; i++) {
    const rim = (i * 360) / carCount + angle
    const d = Math.abs((((rim - platformDeg) % 360) + 540) % 360 - 180)
    if (d < bestD) { bestD = d; best = i + 1 }
  }
  return best
}

type Props = { s: PanelState | null; onPlatformCar?: (car: number) => void }

export function Dial({ s, onPlatformCar }: Props) {
  const spokesRef = useRef<SVGGElement>(null)
  const carsRef = useRef<SVGGElement>(null)
  const markRef = useRef<SVGCircleElement>(null)
  const angle = useRef(0)
  const cbRef = useRef(onPlatformCar)
  cbRef.current = onPlatformCar

  // live params read by the rAF loop (no re-render, no effect re-run)
  const p = useRef({ target: 0, spinning: false, dps: 9, carCount: 16, platformDeg: -21.5, boardable: false })
  if (s) {
    p.current.target = s.angle ?? 0
    p.current.spinning = !!s.spinning
    p.current.dps = s.degPerSec ?? p.current.dps
    p.current.carCount = s.carCount ?? p.current.carCount
    p.current.platformDeg = s.platformDeg ?? p.current.platformDeg
    p.current.boardable = !!s.boardable
  }

  useEffect(() => {
    let raf = 0
    let last = 0
    let lastPC = 0
    const tick = (now: number) => {
      const dt = last ? (now - last) / 1000 : 0
      last = now
      const { target, spinning, dps, carCount, platformDeg, boardable } = p.current
      if (spinning) angle.current = (angle.current + dps * dt) % 360
      // ease toward the server angle (correct drift / snap when stopped)
      angle.current = (angle.current + angShort(angle.current, target) * Math.min(1, dt * 6) + 360) % 360

      const spokes = spokesRef.current, cars = carsRef.current
      if (spokes && cars) {
        // sync element count
        while (spokes.children.length < carCount) {
          const sp = document.createElementNS(SVGNS, 'line')
          sp.setAttribute('class', 'spoke'); sp.setAttribute('x1', String(CX)); sp.setAttribute('y1', String(CY))
          spokes.appendChild(sp)
          const c = document.createElementNS(SVGNS, 'circle')
          c.setAttribute('class', 'car'); c.setAttribute('r', '4')
          cars.appendChild(c)
        }
        while (spokes.children.length > carCount) { spokes.removeChild(spokes.lastChild!); cars.removeChild(cars.lastChild!) }

        const pc = platformCarOf(angle.current, carCount, platformDeg)
        for (let i = 0; i < carCount; i++) {
          const th = ((angle.current + (i * 360) / carCount) * Math.PI) / 180
          const x = CX + R * Math.sin(th), y = CY - R * Math.cos(th)
          const sp = spokes.children[i] as SVGLineElement
          sp.setAttribute('x2', String(x)); sp.setAttribute('y2', String(y))
          const c = cars.children[i] as SVGCircleElement
          c.setAttribute('cx', String(x)); c.setAttribute('cy', String(y))
          c.classList.toggle('platform', i === pc - 1 && boardable)
        }
        // static platform marker (does NOT rotate)
        const mk = markRef.current
        if (mk) {
          const pth = (platformDeg * Math.PI) / 180
          mk.setAttribute('cx', String(CX + (R + 7) * Math.sin(pth)))
          mk.setAttribute('cy', String(CY - (R + 7) * Math.cos(pth)))
        }
        if (pc !== lastPC) { lastPC = pc; cbRef.current?.(pc) }
      }
      raf = requestAnimationFrame(tick)
    }
    raf = requestAnimationFrame(tick)
    return () => cancelAnimationFrame(raf)
  }, [])

  return (
    <div className={clsx('dial', s?.held && 'held')} id="dial">
      <svg viewBox="0 0 120 120" preserveAspectRatio="xMidYMid meet">
        <circle className="rim" cx={CX} cy={CY} r={52} />
        <circle className="glowrim" cx={CX} cy={CY} r={52} />
        <g ref={spokesRef} id="spokes" />
        <g ref={carsRef} id="cars" />
        <circle ref={markRef} id="platform-mark" r={3} fill="#ffe24a" opacity={0.9} />
        <circle className="hub" cx={CX} cy={CY} r={4} />
      </svg>
    </div>
  )
}
