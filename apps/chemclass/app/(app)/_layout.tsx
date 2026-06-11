import { ActivityIndicator, View } from "react-native"
import { Redirect, Tabs } from "expo-router"
import { Ionicons } from "@expo/vector-icons"
import { useAuth } from "@chemclass/shared"
import { colors } from "../../constants/colors"

export default function AppLayout() {
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

  return (
    <Tabs screenOptions={{ tabBarActiveTintColor: colors.primary, headerTintColor: colors.text }}>
      <Tabs.Screen
        name="classes"
        options={{
          title: "Sınıflarım",
          headerShown: false,
          tabBarIcon: ({ color, size }) => <Ionicons name="school-outline" size={size} color={color} />,
        }}
      />
      <Tabs.Screen
        name="profile"
        options={{
          title: "Profil",
          tabBarIcon: ({ color, size }) => <Ionicons name="person-outline" size={size} color={color} />,
        }}
      />
    </Tabs>
  )
}
