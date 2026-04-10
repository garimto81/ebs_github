import { useState, useEffect, useCallback } from 'react'
import type { ApiResponse, PaginationMeta } from '../types/api'

export function useApiList<T>(
  fetchFn: (params: Record<string, string | number>) => Promise<ApiResponse<T[]>>,
  params: Record<string, string | number> = {},
  deps: unknown[] = [],
) {
  const [data, setData] = useState<T[]>([])
  const [meta, setMeta] = useState<PaginationMeta | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // eslint-disable-next-line react-hooks/exhaustive-deps
  const reload = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const res = await fetchFn(params)
      if (res.data) {
        setData(res.data)
        setMeta(res.meta ?? null)
      } else if (res.error) {
        setError(res.error.message)
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Unknown error')
    }
    setLoading(false)
  }, deps)

  useEffect(() => {
    reload()
  }, [reload])

  return { data, meta, loading, error, reload }
}

export function useApiGet<T>(
  fetchFn: () => Promise<ApiResponse<T>>,
  deps: unknown[] = [],
) {
  const [data, setData] = useState<T | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // eslint-disable-next-line react-hooks/exhaustive-deps
  const reload = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const res = await fetchFn()
      if (res.data) {
        setData(res.data)
      } else if (res.error) {
        setError(res.error.message)
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Unknown error')
    }
    setLoading(false)
  }, deps)

  useEffect(() => {
    reload()
  }, [reload])

  return { data, loading, error, reload }
}
