import { useState, useEffect, useRef, useCallback } from 'react'
import { useAuthStore } from '../store/auth-store'

export type WsStatus = 'connecting' | 'connected' | 'disconnected' | 'reconnecting'

export interface WsMessage {
  type: string
  payload?: unknown
}

export function useWebSocket(room: string) {
  const wsRef = useRef<WebSocket | null>(null)
  const [status, setStatus] = useState<WsStatus>('connecting')
  const [lastMessage, setLastMessage] = useState<WsMessage | null>(null)
  const retriesRef = useRef(0)
  const token = useAuthStore((s) => s.accessToken)

  const connect = useCallback(() => {
    if (!token) return
    const protocol = window.location.protocol === 'https:' ? 'wss' : 'ws'
    const ws = new WebSocket(`${protocol}://${window.location.host}/ws/${room}?token=${token}`)

    ws.onopen = () => {
      setStatus('connected')
      retriesRef.current = 0
    }
    ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data) as WsMessage
        setLastMessage(data)
      } catch { /* ignore non-JSON */ }
    }
    ws.onclose = () => {
      setStatus('reconnecting')
      const delay = Math.min(1000 * 2 ** retriesRef.current, 30000)
      retriesRef.current += 1
      setTimeout(connect, delay)
    }
    ws.onerror = () => {
      ws.close()
    }
    wsRef.current = ws
  }, [room, token])

  useEffect(() => {
    setStatus('connecting')
    connect()
    return () => {
      wsRef.current?.close()
      wsRef.current = null
    }
  }, [connect])

  const send = useCallback((data: unknown) => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify(data))
    }
  }, [])

  return { send, status, lastMessage }
}
