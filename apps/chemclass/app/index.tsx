import { ActivityIndicator, View } from "react-native"
import { Redirect } from "expo-router"
import { useAuth } from "@chemclass/shared"
import { colors } from "../constants/colors"

export default function Index() {
  const { session, loading } = useAuth()

  if (loading) {
    return (
      <View style={{ flex: 1, alignItems: "center", justifyContent: "center", backgroundColor: colors.background }}>
        <ActivityIndicator color={colors.primary} />
      </View>
    )
  }

  if (!session) {
    return <Redirect href="/login" />
  }

  return <Redirect href="/classes" />
}
