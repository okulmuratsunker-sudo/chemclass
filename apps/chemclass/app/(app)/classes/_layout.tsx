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
      <Stack.Screen name="[classId]/board" options={{ title: "Tahta" }} />
      <Stack.Screen name="[classId]/messages/index" options={{ title: "Mesajlar" }} />
      <Stack.Screen name="[classId]/messages/[studentId]" options={{ title: "Mesajlar" }} />
      <Stack.Screen name="[classId]/announcements" options={{ title: "Duyurular" }} />
      <Stack.Screen name="[classId]/homework" options={{ title: "Ödevler" }} />
      <Stack.Screen name="[classId]/grades" options={{ title: "Notlar" }} />
    </Stack>
  )
}
