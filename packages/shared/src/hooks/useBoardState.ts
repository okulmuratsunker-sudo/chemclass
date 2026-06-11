import { useCallback, useEffect, useState } from "react"
import { supabase } from "../supabaseClient"
import type { Json } from "../database.types"
import type { BoardState } from "../types"

export function useBoardState(boardSessionId: string | null) {
  const [state, setState] = useState<BoardState | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)

  const fetchState = useCallback(async () => {
    if (!boardSessionId) {
      setState(null)
      setLoading(false)
      return
    }
    setLoading(true)
    const { data, error: err } = await supabase
      .from("board_state")
      .select("*")
      .eq("board_session_id", boardSessionId)
      .single()
    if (err) {
      setError(err)
    } else {
      setState(data)
      setError(null)
    }
    setLoading(false)
  }, [boardSessionId])

  useEffect(() => {
    fetchState()
  }, [fetchState])

  useEffect(() => {
    if (!boardSessionId) return

    const channel = supabase
      .channel(`realtime:board_state:${boardSessionId}`)
      .on(
        "postgres_changes",
        {
          event: "*",
          schema: "public",
          table: "board_state",
          filter: `board_session_id=eq.${boardSessionId}`,
        },
        (payload) => {
          if (payload.eventType === "DELETE") {
            setState(null)
          } else {
            setState(payload.new as BoardState)
          }
        },
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [boardSessionId])

  const updateState = useCallback(
    async (stateType: string, payload: Json) => {
      if (!boardSessionId) return { error: new Error("No board session") }
      const { error: err } = await supabase
        .from("board_state")
        .update({ state_type: stateType, payload, updated_at: new Date().toISOString() })
        .eq("board_session_id", boardSessionId)
      return { error: err }
    },
    [boardSessionId],
  )

  return { state, loading, error, updateState, refetch: fetchState }
}
