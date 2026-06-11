import { useState } from "react"
import { ActivityIndicator, FlatList, KeyboardAvoidingView, Platform, StyleSheet, Text, TextInput, TouchableOpacity, View } from "react-native"
import { useLocalSearchParams } from "expo-router"
import { Ionicons } from "@expo/vector-icons"
import { supabase, useAuth, useClass, useRealtimeList } from "@chemclass/shared"
import { colors } from "../../../../constants/colors"

export default function MessagesScreen() {
  const { classId } = useLocalSearchParams<{ classId: string }>()
  const { profile } = useAuth()
  const { classRow, loading: loadingClass } = useClass(classId ?? null)

  const { data: messages, loading: loadingMessages } = useRealtimeList({
    table: "messages",
    match: { class_id: classId },
    orderBy: { column: "created_at", ascending: true },
    enabled: !!profile,
  })

  const [text, setText] = useState("")
  const [sending, setSending] = useState(false)

  const onSend = async () => {
    const content = text.trim()
    if (!content || !profile || !classRow || !classId) return
    setSending(true)
    setText("")
    const { error } = await supabase.from("messages").insert({
      class_id: classId,
      sender_id: profile.id,
      recipient_id: classRow.teacher_id,
      content,
    })
    setSending(false)
    if (error) setText(content)
  }

  if (loadingClass || loadingMessages) {
    return (
      <View style={styles.center}>
        <ActivityIndicator color={colors.primary} />
      </View>
    )
  }

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === "ios" ? "padding" : undefined}
      keyboardVerticalOffset={90}
    >
      <FlatList
        data={messages}
        keyExtractor={(item) => item.id}
        contentContainerStyle={{ padding: 16, gap: 8 }}
        ListEmptyComponent={<Text style={styles.empty}>Henüz mesaj yok. Öğretmenine yaz!</Text>}
        renderItem={({ item }) => {
          const isMine = item.sender_id === profile?.id
          return (
            <View style={[styles.bubble, isMine ? styles.bubbleMine : styles.bubbleTheirs]}>
              <Text style={[styles.bubbleText, isMine && styles.bubbleTextMine]}>{item.content}</Text>
            </View>
          )
        }}
      />

      <View style={styles.inputRow}>
        <TextInput
          style={styles.input}
          placeholder="Mesaj yaz..."
          value={text}
          onChangeText={setText}
          multiline
        />
        <TouchableOpacity style={styles.sendButton} onPress={onSend} disabled={sending || !text.trim()}>
          {sending ? <ActivityIndicator color={colors.primaryText} /> : <Ionicons name="send" size={18} color={colors.primaryText} />}
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  )
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  center: { flex: 1, alignItems: "center", justifyContent: "center", backgroundColor: colors.background },
  empty: { textAlign: "center", color: colors.muted, marginTop: 32 },
  bubble: {
    maxWidth: "80%",
    borderRadius: 12,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  bubbleMine: {
    backgroundColor: colors.primary,
    alignSelf: "flex-end",
  },
  bubbleTheirs: {
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    alignSelf: "flex-start",
  },
  bubbleText: { color: colors.text, fontSize: 15 },
  bubbleTextMine: { color: colors.primaryText },
  inputRow: {
    flexDirection: "row",
    alignItems: "flex-end",
    gap: 8,
    padding: 12,
    borderTopWidth: 1,
    borderTopColor: colors.border,
    backgroundColor: colors.surface,
  },
  input: {
    flex: 1,
    backgroundColor: colors.background,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 18,
    paddingHorizontal: 16,
    paddingVertical: 10,
    fontSize: 15,
    maxHeight: 100,
  },
  sendButton: {
    backgroundColor: colors.primary,
    borderRadius: 20,
    width: 40,
    height: 40,
    alignItems: "center",
    justifyContent: "center",
  },
})
