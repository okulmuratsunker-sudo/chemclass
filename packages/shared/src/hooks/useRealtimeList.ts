import { useCallback, useEffect, useState } from "react"
import { supabase } from "../supabaseClient"
import type { Database } from "../database.types"

/** Tables included in the `supabase_realtime` publication that are id-keyed lists. */
export type RealtimeListTable =
  | "behavior_points"
  | "messages"
  | "homework"
  | "announcements"
  | "grades"
  | "schedule_entries"

type Row<T extends RealtimeListTable> = Database["public"]["Tables"][T]["Row"]

export type UseRealtimeListOptions<T extends RealtimeListTable> = {
  table: T
  match?: Partial<Row<T>>
  orderBy?: { column: keyof Row<T> & string; ascending?: boolean }
  enabled?: boolean
}

function sortRows<T extends RealtimeListTable>(
  rows: Row<T>[],
  orderBy?: { column: keyof Row<T> & string; ascending?: boolean },
): Row<T>[] {
  if (!orderBy) return rows
  const { column, ascending = true } = orderBy
  return [...rows].sort((a, b) => {
    const aVal = a[column]
    const bVal = b[column]
    if (aVal === bVal) return 0
    if (aVal === null || aVal === undefined) return ascending ? -1 : 1
    if (bVal === null || bVal === undefined) return ascending ? 1 : -1
    if (aVal < bVal) return ascending ? -1 : 1
    return ascending ? 1 : -1
  })
}

export function useRealtimeList<T extends RealtimeListTable>({
  table,
  match,
  orderBy,
  enabled = true,
}: UseRealtimeListOptions<T>) {
  const [data, setData] = useState<Row<T>[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)

  const matchKey = JSON.stringify(match ?? {})

  const fetchData = useCallback(async () => {
    if (!enabled) {
      setData([])
      setLoading(false)
      return
    }
    setLoading(true)
    // The query builder type becomes unworkable when `table` is a generic union of table
    // names, so we build the query dynamically and cast the final result instead.
    let query = supabase.from(table).select("*") as any
    for (const [key, value] of Object.entries(match ?? {})) {
      query = query.eq(key, value)
    }
    if (orderBy) {
      query = query.order(orderBy.column as string, { ascending: orderBy.ascending ?? true })
    }
    const { data: rows, error: err } = await query
    if (err) {
      setError(err)
    } else {
      setData((rows ?? []) as Row<T>[])
      setError(null)
    }
    setLoading(false)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [table, matchKey, orderBy?.column, orderBy?.ascending, enabled])

  useEffect(() => {
    fetchData()
  }, [fetchData])

  useEffect(() => {
    if (!enabled) return

    const matchEntries = Object.entries(match ?? {})
    const filter = matchEntries.length === 1 ? `${matchEntries[0][0]}=eq.${matchEntries[0][1]}` : undefined

    const matchesFilter = (row: Record<string, unknown>) =>
      matchEntries.every(([key, value]) => row[key] === value)

    const channel = supabase
      .channel(`realtime:${table}:${matchKey}`)
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table, filter },
        (payload) => {
          const newRow = payload.new as (Row<T> & { id: string }) | undefined
          const oldRow = payload.old as { id?: string } | undefined

          setData((current) => {
            if (payload.eventType === "INSERT" && newRow) {
              if (!matchesFilter(newRow as unknown as Record<string, unknown>)) return current
              if (current.some((row) => (row as { id: string }).id === newRow.id)) return current
              return sortRows([...current, newRow], orderBy)
            }
            if (payload.eventType === "UPDATE" && newRow) {
              if (!matchesFilter(newRow as unknown as Record<string, unknown>)) {
                return current.filter((row) => (row as { id: string }).id !== oldRow?.id)
              }
              return sortRows(
                current.map((row) => ((row as { id: string }).id === newRow.id ? newRow : row)),
                orderBy,
              )
            }
            if (payload.eventType === "DELETE" && oldRow) {
              return current.filter((row) => (row as { id: string }).id !== oldRow.id)
            }
            return current
          })
        },
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [table, matchKey, enabled])

  return { data, loading, error, refetch: fetchData }
}
