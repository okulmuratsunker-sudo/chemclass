import { useState } from "react"
import { ActivityIndicator, FlatList, StyleSheet, Text, TextInput, TouchableOpacity, View } from "react-native"
import { useRouter } from "expo-router"
import { createClass, useAuth, useTeacherClasses } from "@chemclass/shared"
import { colors } from "../../../constants/colors"

export default function ClassesScreen() {
  const { profile } = useAuth()
  const { classes, loading, refetch } = useTeacherClasses(profile?.id ?? null)
  const router = useRouter()
  const [name, setName] = useState("")
  const [creating, setCreating] = useState(false)

  const onCreate = async () => {
    if (!profile || !name.trim()) return
    setCreating(true)
    const { error } = await createClass(profile.id, name.trim())
    setCreating(false)
    if (!error) {
      setName("")
      refetch()
    }
  }

  return (
    <View style={styles.container}>
      <View style={styles.createRow}>
        <TextInput style={styles.input} placeholder="Yeni sınıf adı (örn. 10-A)" value={name} onChangeText={setName} />
        <TouchableOpacity style={styles.createButton} onPress={onCreate} disabled={creating || !name.trim()}>
          {creating ? <ActivityIndicator color={colors.primaryText} /> : <Text style={styles.createButtonText}>Ekle</Text>}
        </TouchableOpacity>
      </View>

      {loading ? (
        <ActivityIndicator color={colors.primary} style={{ marginTop: 32 }} />
      ) : (
        <FlatList
          data={classes}
          keyExtractor={(item) => item.id}
          contentContainerStyle={{ padding: 16, gap: 12 }}
          ListEmptyComponent={<Text style={styles.empty}>Henüz sınıf eklenmedi.</Text>}
          renderItem={({ item }) => (
            <TouchableOpacity style={styles.card} onPress={() => router.push(`/classes/${item.id}`)}>
              <Text style={styles.cardTitle}>{item.name}</Text>
              <Text style={styles.cardCode}>Katılım kodu: {item.join_code}</Text>
            </TouchableOpacity>
          )}
        />
      )}
    </View>
  )
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  createRow: { flexDirection: "row", gap: 8, padding: 16 },
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
  card: {
    backgroundColor: colors.surface,
    borderRadius: 12,
    padding: 16,
    borderWidth: 1,
    borderColor: colors.border,
  },
  cardTitle: { fontSize: 18, fontWeight: "600", color: colors.text },
  cardCode: { fontSize: 14, color: colors.muted, marginTop: 4 },
  empty: { textAlign: "center", color: colors.muted, marginTop: 32 },
})
