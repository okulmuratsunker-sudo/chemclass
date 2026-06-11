import { useState } from "react"
import { ActivityIndicator, FlatList, StyleSheet, Text, TextInput, TouchableOpacity, View } from "react-native"
import { useLocalSearchParams } from "expo-router"
import { Ionicons } from "@expo/vector-icons"
import { supabase, useAuth, useRealtimeList } from "@chemclass/shared"
import { colors } from "../../../../constants/colors"

export default function HomeworkScreen() {
  const { classId } = useLocalSearchParams<{ classId: string }>()
  const { profile } = useAuth()

  const { data: homework, loading } = useRealtimeList({
    table: "homework",
    match: { class_id: classId },
    orderBy: { column: "created_at", ascending: false },
  })

  const [title, setTitle] = useState("")
  const [description, setDescription] = useState("")
  const [dueDate, setDueDate] = useState("")
  const [sending, setSending] = useState(false)

  const onCreate = async () => {
    if (!title.trim() || !profile || !classId) return
    setSending(true)
    const { error } = await supabase.from("homework").insert({
      class_id: classId,
      created_by: profile.id,
      title: title.trim(),
      description: description.trim() || null,
      due_date: dueDate.trim() || null,
    })
    setSending(false)
    if (!error) {
      setTitle("")
      setDescription("")
      setDueDate("")
    }
  }

  const onDelete = async (id: string) => {
    await supabase.from("homework").delete().eq("id", id)
  }

  return (
    <FlatList
      style={styles.container}
      data={homework}
      keyExtractor={(item) => item.id}
      contentContainerStyle={{ padding: 16, gap: 12 }}
      ListHeaderComponent={
        <View style={styles.form}>
          <Text style={styles.sectionTitle}>Yeni Ödev</Text>
          <TextInput style={styles.input} placeholder="Başlık" value={title} onChangeText={setTitle} />
          <TextInput
            style={[styles.input, styles.textArea]}
            placeholder="Açıklama"
            value={description}
            onChangeText={setDescription}
            multiline
          />
          <TextInput
            style={styles.input}
            placeholder="Teslim tarihi (örn. 2026-06-20)"
            value={dueDate}
            onChangeText={setDueDate}
          />
          <TouchableOpacity style={styles.submitButton} onPress={onCreate} disabled={sending || !title.trim()}>
            {sending ? <ActivityIndicator color={colors.primaryText} /> : <Text style={styles.submitButtonText}>Ödev Ver</Text>}
          </TouchableOpacity>
          <Text style={styles.sectionTitle}>Ödevler</Text>
          {loading ? <ActivityIndicator color={colors.primary} /> : null}
        </View>
      }
      ListEmptyComponent={!loading ? <Text style={styles.empty}>Henüz ödev yok.</Text> : null}
      renderItem={({ item }) => (
        <View style={styles.card}>
          <View style={{ flex: 1 }}>
            <Text style={styles.cardTitle}>{item.title}</Text>
            {item.description ? <Text style={styles.cardText}>{item.description}</Text> : null}
            {item.due_date ? <Text style={styles.dueDate}>Teslim: {item.due_date}</Text> : null}
          </View>
          <TouchableOpacity onPress={() => onDelete(item.id)}>
            <Ionicons name="trash-outline" size={20} color={colors.danger} />
          </TouchableOpacity>
        </View>
      )}
    />
  )
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  form: { gap: 8, marginBottom: 8 },
  sectionTitle: { fontSize: 16, fontWeight: "600", color: colors.text, marginTop: 8 },
  input: {
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 10,
    paddingHorizontal: 16,
    paddingVertical: 12,
    fontSize: 16,
  },
  textArea: { minHeight: 80, textAlignVertical: "top" },
  submitButton: {
    backgroundColor: colors.primary,
    borderRadius: 10,
    paddingVertical: 14,
    alignItems: "center",
  },
  submitButtonText: { color: colors.primaryText, fontWeight: "600" },
  empty: { textAlign: "center", color: colors.muted, marginTop: 16 },
  card: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    backgroundColor: colors.surface,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.border,
    padding: 14,
  },
  cardTitle: { fontWeight: "600", color: colors.text, marginBottom: 4 },
  cardText: { color: colors.muted },
  dueDate: { color: colors.muted, fontSize: 12, marginTop: 4 },
})
