import { supabase } from "./supabaseClient"

export async function giveBehaviorPoint(params: {
  classId: string
  studentId: string
  givenBy: string
  points: number
  reason?: string | null
}) {
  const { error } = await supabase.from("behavior_points").insert({
    class_id: params.classId,
    student_id: params.studentId,
    given_by: params.givenBy,
    points: params.points,
    reason: params.reason ?? null,
  })
  return { error }
}
