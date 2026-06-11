import React, { createContext, useContext, useEffect, useState } from "react"
import type { AuthError, Session, User } from "@supabase/supabase-js"
import { supabase } from "../supabaseClient"
import type { Profile, Role } from "../types"

type SignUpParams = {
  email: string
  password: string
  fullName: string
  role: Role
}

type SignInParams = {
  email: string
  password: string
}

type AuthContextValue = {
  session: Session | null
  user: User | null
  profile: Profile | null
  loading: boolean
  signUp: (params: SignUpParams) => Promise<{ error: AuthError | null }>
  signIn: (params: SignInParams) => Promise<{ error: AuthError | null }>
  signOut: () => Promise<void>
  refreshProfile: () => Promise<void>
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined)

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [session, setSession] = useState<Session | null>(null)
  const [profile, setProfile] = useState<Profile | null>(null)
  const [loading, setLoading] = useState(true)

  const loadProfile = async (userId: string) => {
    const { data } = await supabase.from("profiles").select("*").eq("id", userId).single()
    setProfile(data ?? null)
  }

  useEffect(() => {
    let mounted = true

    supabase.auth.getSession().then(({ data }) => {
      if (!mounted) return
      setSession(data.session)
      if (data.session?.user) {
        loadProfile(data.session.user.id).finally(() => setLoading(false))
      } else {
        setLoading(false)
      }
    })

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      setSession(nextSession)
      if (nextSession?.user) {
        loadProfile(nextSession.user.id)
      } else {
        setProfile(null)
      }
    })

    return () => {
      mounted = false
      subscription.unsubscribe()
    }
  }, [])

  const signUp = async ({ email, password, fullName, role }: SignUpParams) => {
    const { error } = await supabase.auth.signUp({
      email,
      password,
      options: { data: { full_name: fullName, role } },
    })
    return { error }
  }

  const signIn = async ({ email, password }: SignInParams) => {
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    return { error }
  }

  const signOut = async () => {
    await supabase.auth.signOut()
  }

  const refreshProfile = async () => {
    if (session?.user) {
      await loadProfile(session.user.id)
    }
  }

  const value: AuthContextValue = {
    session,
    user: session?.user ?? null,
    profile,
    loading,
    signUp,
    signIn,
    signOut,
    refreshProfile,
  }

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error("useAuth must be used within an AuthProvider")
  return ctx
}
