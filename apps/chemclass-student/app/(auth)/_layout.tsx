import { Redirect, Stack } from "expo-router"
import { useAuth } from "@chemclass/shared"

export default function AuthLayout() {
  const { session, loading } = useAuth()

  if (!loading && session) {
    return <Redirect href="/classes" />
  }

  return <Stack screenOptions={{ headerShown: false }} />
}
