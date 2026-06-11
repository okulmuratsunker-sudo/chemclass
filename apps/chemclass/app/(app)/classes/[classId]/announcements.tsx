import { useState } from "react"
import { ActivityIndicator, FlatList, StyleSheet, Text, TextInput, TouchableOpacity, View } from "react-native"
import { useLocalSearchParams } from "expo-router"
import { Ionicons } from "@expo/vector-icons"
import { supabase, useAuth, useRealtimeList } from "@chemclass/shared"
import { colors } from "../../../../constants/colors"

export default function AnnouncementsScreen() {
  const { classId } = useLocalSearchParams<{ classId: string }>()
  const { profile } = useAuth()

  const { data: announcements, loading } = useRealtimeList({
    table: "announcements",
    match: { class_id: classId },
    orderBy: { column: "created_at", ascending: false },
  })

  const [title, setTitle] = useState("")
  const [content, setContent] = useState("")
  const [sending, setSending] = useState(false)

  const onShare = async () => {
    if (!title.trim() || !content.trim() || !profile || !classId) return
    setSending(true)
    const { error } = await supabase.from("announcements").insert({
      class_id: classId,
      created_by: profile.id,
      title: title.trim(),
      content: content.trim(),
    })
    setSending(false)
    if (!error) {
      setTitle("")
      setContent("")
    }
  }

  const onDelete = async (id: string) => {
    await supabase.from("announcements").delete().eq("id", id)
  }

  return (
    <FlatList
      style={styles.container}
      data={announcements}
      keyExtractor={(item) => item.id}
      contentContainerStyle={{ padding: 16, gap: 12 }}
      ListHeaderComponent={
        <View style={styles.form}>
          <Text style={styles.sectionTitle}>Yeni Duyuru</Text>
          <TextInput style={styles.input} placeholder="Başlık" value={title} onChangeText={setTitle} />
          <TextInput
            style={[styles.input, styles.textArea]}
            placeholder="İçerik"
            value={content}
            onChangeText={setContent}
            multiline
          />
          <TouchableOpacity
            style={styles.submitButton}
            onPress={onShare}
            disabled={sending || !title.trim() || !content.trim()}
          >
            {sending ? <ActivityIndicator color={colors.primaryText} /> : <Text style={styles.submitButtonText}>Paylaş</Text>}
          </TouchableOpacity>
          <Text style={styles.sectionTitle}>Duyurular</Text>
          {loading ? <ActivityIndicator color={colors.primary} /> : null}
        </View>
      }
      ListEmptyComponent={!loading ? <Text style={styles.empty}>Henüz duyuru yok.</Text> : null}
      renderItem={({ item }) => (
        <View style={styles.card}>
          <View style={{ flex: 1 }}>
            <Text style={styles.cardTitle}>{item.title}</Text>
            <Text style={styles.cardText}>{item.content}</Text>
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
})
