import { useEffect, useState } from "react"
import { supabase } from "../supabaseClient"
import type { BoardSession } from "../types"

/** Looks up a board session id from a teacher-shared Tahta code. Works without auth (anon). */
export async function redeemBoardCode(code: string) {
  const { data, error } = await supabase.rpc("redeem_board_code", { p_code: code.trim() })
  return { boardSessionId: data ?? null, error }
}

/** Fetches the board session that belongs to a class (one-to-one, auto-created with the class). */
export function useBoardSessionForClass(classId: string | null) {
  const [boardSession, setBoardSession] = useState<BoardSession | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)

  useEffect(() => {
    let mounted = true

    if (!classId) {
      setBoardSession(null)
      setLoading(false)
      return
    }

    setLoading(true)
    supabase
      .from("board_sessions")
      .select("*")
      .eq("class_id", classId)
      .single()
      .then(({ data, error: err }) => {
        if (!mounted) return
        if (err) {
          setError(err)
        } else {
          setBoardSession(data)
          setError(null)
        }
        setLoading(false)
      })

    return () => {
      mounted = false
    }
  }, [classId])

  return { boardSession, loading, error }
}
