import { useCallback } from "react"
import { supabase } from "../supabaseClient"
import { useAuth } from "../auth/AuthProvider"
import { useRealtimeList } from "./useRealtimeList"

export const DAYS_OF_WEEK = [
  { value: 1, label: "Pazartesi" },
  { value: 2, label: "Salı" },
  { value: 3, label: "Çarşamba" },
  { value: 4, label: "Perşembe" },
  { value: 5, label: "Cuma" },
  { value: 6, label: "Cumartesi" },
  { value: 7, label: "Pazar" },
] as const

export const PERIODS = [1, 2, 3, 4, 5, 6, 7, 8] as const

/** Converts JS Date#getDay() (0=Sunday) to the ISO day_of_week used by schedule_entries (1=Monday..7=Sunday). */
export function isoDayOfWeek(date: Date) {
  const day = date.getDay()
  return day === 0 ? 7 : day
}

export function useSchedule() {
  const { profile } = useAuth()

  const { data, loading, error } = useRealtimeList({
    table: "schedule_entries",
    match: { user_id: profile?.id },
    orderBy: { column: "period_number", ascending: true },
    enabled: !!profile,
  })

  const setEntry = useCallback(
    async (dayOfWeek: number, periodNumber: number, subjectName: string) => {
      if (!profile) return { error: new Error("Not signed in") }
      const trimmed = subjectName.trim()
      if (!trimmed) {
        const { error: err } = await supabase
          .from("schedule_entries")
          .delete()
          .eq("user_id", profile.id)
          .eq("day_of_week", dayOfWeek)
          .eq("period_number", periodNumber)
        return { error: err }
      }
      const { error: err } = await supabase.from("schedule_entries").upsert(
        {
          user_id: profile.id,
          day_of_week: dayOfWeek,
          period_number: periodNumber,
          subject_name: trimmed,
        },
        { onConflict: "user_id,day_of_week,period_number" },
      )
      return { error: err }
    },
    [profile],
  )

  return { entries: data, loading, error, setEntry }
}
