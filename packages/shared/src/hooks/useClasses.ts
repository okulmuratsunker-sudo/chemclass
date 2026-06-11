import { useCallback, useEffect, useState } from "react"
import { supabase } from "../supabaseClient"
import type { ClassRow, Profile } from "../types"

export type ClassRosterEntry = {
  student_id: string
  joined_at: string
  profile: Profile | null
}

/** Classes a teacher owns. */
export function useTeacherClasses(teacherId: string | null) {
  const [classes, setClasses] = useState<ClassRow[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)

  const refetch = useCallback(async () => {
    if (!teacherId) {
      setClasses([])
      setLoading(false)
      return
    }
    setLoading(true)
    const { data, error: err } = await supabase
      .from("classes")
      .select("*")
      .eq("teacher_id", teacherId)
      .order("created_at", { ascending: true })
    if (err) {
      setError(err)
    } else {
      setClasses(data ?? [])
      setError(null)
    }
    setLoading(false)
  }, [teacherId])

  useEffect(() => {
    refetch()
  }, [refetch])

  return { classes, loading, error, refetch }
}

/** Classes a student has joined. */
export function useStudentClasses(studentId: string | null) {
  const [classes, setClasses] = useState<ClassRow[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)

  const refetch = useCallback(async () => {
    if (!studentId) {
      setClasses([])
      setLoading(false)
      return
    }
    setLoading(true)
    const { data, error: err } = await supabase
      .from("class_students")
      .select("classes(*)")
      .eq("student_id", studentId)
    if (err) {
      setError(err)
    } else {
      setClasses((data ?? []).map((row) => row.classes).filter((c): c is ClassRow => c !== null))
      setError(null)
    }
    setLoading(false)
  }, [studentId])

  useEffect(() => {
    refetch()
  }, [refetch])

  return { classes, loading, error, refetch }
}

/** Single class by id (used for headers/detail screens). */
export function useClass(classId: string | null) {
  const [classRow, setClassRow] = useState<ClassRow | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)

  const refetch = useCallback(async () => {
    if (!classId) {
      setClassRow(null)
      setLoading(false)
      return
    }
    setLoading(true)
    const { data, error: err } = await supabase.from("classes").select("*").eq("id", classId).single()
    if (err) {
      setError(err)
    } else {
      setClassRow(data)
      setError(null)
    }
    setLoading(false)
  }, [classId])

  useEffect(() => {
    refetch()
  }, [refetch])

  return { classRow, loading, error, refetch }
}

/** Roster (students + their profiles) for a class. */
export function useClassRoster(classId: string | null) {
  const [roster, setRoster] = useState<ClassRosterEntry[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)

  const refetch = useCallback(async () => {
    if (!classId) {
      setRoster([])
      setLoading(false)
      return
    }
    setLoading(true)
    const { data, error: err } = await supabase
      .from("class_students")
      .select("student_id, joined_at, profiles(*)")
      .eq("class_id", classId)
      .order("joined_at", { ascending: true })
    if (err) {
      setError(err)
    } else {
      setRoster((data ?? []).map((row) => ({ student_id: row.student_id, joined_at: row.joined_at, profile: row.profiles })))
      setError(null)
    }
    setLoading(false)
  }, [classId])

  useEffect(() => {
    refetch()
  }, [refetch])

  return { roster, loading, error, refetch }
}

/** Creates a new class for the current teacher. The DB trigger auto-provisions its Tahta board. */
export async function createClass(teacherId: string, name: string) {
  const { data, error } = await supabase
    .from("classes")
    .insert({ teacher_id: teacherId, name })
    .select("*")
    .single()
  return { data, error }
}

/** Joins the current student to a class using the teacher-shared join code. */
export async function joinClassByCode(code: string) {
  const { data, error } = await supabase.rpc("join_class_by_code", { p_code: code.trim() })
  return { data: data?.[0] ?? null, error }
}
