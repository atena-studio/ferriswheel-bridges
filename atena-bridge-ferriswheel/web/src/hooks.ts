import { useEffect, useRef } from 'react'
import { onNui } from './nui'

// Subscribe a component to a NUI message action without re-binding on every render
// (handler kept in a ref, so the latest closure runs but the subscription is stable).
export function useNuiEvent<T = Record<string, unknown>>(action: string, handler: (payload: T) => void) {
  const ref = useRef(handler)
  ref.current = handler
  useEffect(() => onNui(action, (p) => ref.current(p as T)), [action])
}
