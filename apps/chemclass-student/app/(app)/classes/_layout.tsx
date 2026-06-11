import { Stack } from "expo-router"
import { colors } from "../../../constants/colors"

export default function ClassesLayout() {
  return (
    <Stack
      screenOptions={{
        headerStyle: { backgroundColor: colors.surface },
        headerTintColor: colors.text,
        headerTitleStyle: { fontWeight: "600" },
      }}
    >
      <Stack.Screen name="index" options={{ title: "Sınıflarım" }} />
      <Stack.Screen name="[classId]/index" options={{ title: "Sınıf" }} />
      <Stack.Screen name="[classId]/messages" options={{ title: "Mesajlar" }} />
    </Stack>
  )
}
