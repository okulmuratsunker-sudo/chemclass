import { useState } from "react"
import { ActivityIndicator, FlatList, StyleSheet, Text, TextInput, TouchableOpacity, View } from "react-native"
import { useRouter } from "expo-router"
import { joinClassByCode, useAuth, useStudentClasses } from "@chemclass/shared"
import { colors } from "../../../constants/colors"

export default function ClassesScreen() {
  const { profile } = useAuth()
  const { classes, loading, refetch } = useStudentClasses(profile?.id ?? null)
  const router = useRouter()
  const [code, setCode] = useState("")
  const [joining, setJoining] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const onJoin = async () => {
    if (!code.trim()) return
    setError(null)
    setJoining(true)
    const { error: joinError } = await joinClassByCode(code)
    setJoining(false)
    if (joinError) {
      setError("Geçersiz kod. Tekrar deneyin.")
      return
    }
    setCode("")
    refetch()
  }

  return (
    <View style={styles.container}>
      <View style={styles.createRow}>
        <TextInput
          style={styles.input}
          placeholder="Sınıf kodu (örn. AB12CD)"
          autoCapitalize="characters"
          value={code}
          onChangeText={setCode}
        />
        <TouchableOpacity style={styles.createButton} onPress={onJoin} disabled={joining || !code.trim()}>
          {joining ? <ActivityIndicator color={colors.primaryText} /> : <Text style={styles.createButtonText}>Katıl</Text>}
        </TouchableOpacity>
      </View>
      {error ? <Text style={styles.error}>{error}</Text> : null}

      {loading ? (
        <ActivityIndicator color={colors.primary} style={{ marginTop: 32 }} />
      ) : (
        <FlatList
          data={classes}
          keyExtractor={(item) => item.id}
          contentContainerStyle={{ padding: 16, gap: 12 }}
          ListEmptyComponent={<Text style={styles.empty}>Henüz bir sınıfa katılmadın.</Text>}
          renderItem={({ item }) => (
            <TouchableOpacity style={styles.card} onPress={() => router.push(`/classes/${item.id}`)}>
              <Text style={styles.cardTitle}>{item.name}</Text>
            </TouchableOpacity>
          )}
        />
      )}
    </View>
  )
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  createRow: { flexDirection: "row", gap: 8, padding: 16, paddingBottom: 4 },
  input: {
    flex: 1,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 10,
    paddingHorizontal: 16,
    paddingVertical: 12,
    fontSize: 16,
  },
  createButton: {
    backgroundColor: colors.primary,
    borderRadius: 10,
    paddingHorizontal: 20,
    justifyContent: "center",
  },
  createButtonText: { color: colors.primaryText, fontWeight: "600" },
  error: { color: colors.danger, marginHorizontal: 16, marginTop: 8 },
  card: {
    backgroundColor: colors.surface,
    borderRadius: 12,
    padding: 16,
    borderWidth: 1,
    borderColor: colors.border,
  },
  cardTitle: { fontSize: 18, fontWeight: "600", color: colors.text },
  empty: { textAlign: "center", color: colors.muted, marginTop: 32 },
})
