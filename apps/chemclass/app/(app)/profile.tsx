import { useEffect } from "react"
import { StyleSheet, Text, TouchableOpacity, View } from "react-native"
import { useAuth } from "@chemclass/shared"
import { colors } from "../../constants/colors"
import { registerForPushNotificationsAsync } from "../../lib/registerPushNotifications"

export default function ProfileScreen() {
  const { profile, user, signOut } = useAuth()

  useEffect(() => {
    if (user) {
      registerForPushNotificationsAsync(user.id).catch(() => {})
    }
  }, [user])

  return (
    <View style={styles.container}>
      <View style={styles.card}>
        <Text style={styles.name}>{profile?.full_name ?? "Öğretmen"}</Text>
        <Text style={styles.email}>{user?.email}</Text>
        <Text style={styles.role}>Rol: Öğretmen</Text>
      </View>

      <TouchableOpacity style={styles.signOutButton} onPress={() => signOut()}>
        <Text style={styles.signOutText}>Çıkış Yap</Text>
      </TouchableOpacity>
    </View>
  )
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background, padding: 16, gap: 16 },
  card: {
    backgroundColor: colors.surface,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.border,
    padding: 20,
    gap: 4,
  },
  name: { fontSize: 20, fontWeight: "700", color: colors.text },
  email: { fontSize: 14, color: colors.muted },
  role: { fontSize: 14, color: colors.muted, marginTop: 8 },
  signOutButton: {
    backgroundColor: colors.danger,
    borderRadius: 10,
    paddingVertical: 14,
    alignItems: "center",
  },
  signOutText: { color: colors.primaryText, fontWeight: "600" },
})
