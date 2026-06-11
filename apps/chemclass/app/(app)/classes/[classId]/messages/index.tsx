import { useMemo } from "react"
import { ActivityIndicator, FlatList, StyleSheet, Text, TouchableOpacity, View } from "react-native"
import { useLocalSearchParams, useRouter } from "expo-router"
import { useAuth, useClassRoster, useRealtimeList } from "@chemclass/shared"
import { colors } from "../../../../../constants/colors"

export default function MessagesInboxScreen() {
  const { classId } = useLocalSearchParams<{ classId: string }>()
  const router = useRouter()
  const { profile } = useAuth()
  const { roster, loading: loadingRoster } = useClassRoster(classId ?? null)

  const { data: messages } = useRealtimeList({
    table: "messages",
    match: { class_id: classId },
    orderBy: { column: "created_at", ascending: false },
    enabled: !!profile,
  })

  const conversations = useMemo(() => {
    const teacherId = profile?.id
    return roster
      .map((entry) => {
        const thread = messages.filter(
          (m) =>
            (m.sender_id === entry.student_id && m.recipient_id === teacherId) ||
            (m.sender_id === teacherId && m.recipient_id === entry.student_id),
        )
        const lastMessage = thread[0] ?? null
        const unreadCount = thread.filter((m) => m.sender_id === entry.student_id && m.recipient_id === teacherId && !m.read_at).length
        return { entry, lastMessage, unreadCount }
      })
      .sort((a, b) => {
        if (!a.lastMessage && !b.lastMessage) return 0
        if (!a.lastMessage) return 1
        if (!b.lastMessage) return -1
        return a.lastMessage.created_at < b.lastMessage.created_at ? 1 : -1
      })
  }, [roster, messages, profile?.id])

  if (loadingRoster) {
    return (
      <View style={styles.center}>
        <ActivityIndicator color={colors.primary} />
      </View>
    )
  }

  return (
    <FlatList
      style={styles.container}
      data={conversations}
      keyExtractor={(item) => item.entry.student_id}
      contentContainerStyle={{ padding: 16, gap: 8 }}
      ListEmptyComponent={<Text style={styles.empty}>Bu sınıfa henüz öğrenci katılmadı.</Text>}
      renderItem={({ item }) => (
        <TouchableOpacity
          style={styles.row}
          onPress={() =>
            router.push({
              pathname: "/classes/[classId]/messages/[studentId]",
              params: {
                classId: classId ?? "",
                studentId: item.entry.student_id,
                name: item.entry.profile?.full_name ?? "Öğrenci",
              },
            })
          }
        >
          <View style={{ flex: 1 }}>
            <Text style={styles.name}>{item.entry.profile?.full_name ?? "İsimsiz"}</Text>
            <Text style={styles.preview} numberOfLines={1}>
              {item.lastMessage ? item.lastMessage.content : "Henüz mesaj yok"}
            </Text>
          </View>
          {item.unreadCount > 0 ? (
            <View style={styles.badge}>
              <Text style={styles.badgeText}>{item.unreadCount}</Text>
            </View>
          ) : null}
        </TouchableOpacity>
      )}
    />
  )
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  center: { flex: 1, alignItems: "center", justifyContent: "center", backgroundColor: colors.background },
  empty: { textAlign: "center", color: colors.muted, marginTop: 32 },
  row: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: colors.surface,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.border,
    padding: 14,
    gap: 12,
  },
  name: { fontWeight: "600", color: colors.text, marginBottom: 2 },
  preview: { color: colors.muted },
  badge: {
    backgroundColor: colors.primary,
    borderRadius: 999,
    minWidth: 24,
    height: 24,
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 6,
  },
  badgeText: { color: colors.primaryText, fontWeight: "700", fontSize: 12 },
})
