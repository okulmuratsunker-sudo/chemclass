import { useMemo } from "react"
import { ActivityIndicator, ScrollView, StyleSheet, Text, TouchableOpacity, View } from "react-native"
import { useLocalSearchParams, useRouter } from "expo-router"
import { Ionicons } from "@expo/vector-icons"
import { useAuth, useClass, useRealtimeList } from "@chemclass/shared"
import { colors } from "../../../../constants/colors"

export default function ClassDetailScreen() {
  const { classId } = useLocalSearchParams<{ classId: string }>()
  const router = useRouter()
  const { profile } = useAuth()
  const { classRow, loading: loadingClass } = useClass(classId ?? null)

  const { data: points } = useRealtimeList({
    table: "behavior_points",
    match: { class_id: classId, student_id: profile?.id },
    orderBy: { column: "created_at", ascending: false },
    enabled: !!profile,
  })

  const { data: grades } = useRealtimeList({
    table: "grades",
    match: { class_id: classId, student_id: profile?.id },
    orderBy: { column: "created_at", ascending: false },
    enabled: !!profile,
  })

  const { data: announcements } = useRealtimeList({
    table: "announcements",
    match: { class_id: classId },
    orderBy: { column: "created_at", ascending: false },
  })

  const { data: homework } = useRealtimeList({
    table: "homework",
    match: { class_id: classId },
    orderBy: { column: "created_at", ascending: false },
  })

  const totalPoints = useMemo(() => points.reduce((sum, p) => sum + p.points, 0), [points])

  if (loadingClass || !classRow) {
    return (
      <View style={styles.center}>
        <ActivityIndicator color={colors.primary} />
      </View>
    )
  }

  return (
    <ScrollView style={styles.container} contentContainerStyle={{ padding: 16, gap: 16 }}>
      <View style={styles.header}>
        <Text style={styles.className}>{classRow.name}</Text>
        <TouchableOpacity style={styles.messagesButton} onPress={() => router.push(`/classes/${classId}/messages`)}>
          <Ionicons name="chatbubble-outline" size={16} color={colors.primaryText} />
          <Text style={styles.messagesButtonText}>Mesajlar</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.section}>
        <View style={styles.sectionHeaderRow}>
          <Text style={styles.sectionTitle}>Davranış Puanlarım</Text>
          <Text style={[styles.totalPoints, totalPoints >= 0 ? styles.positive : styles.negative]}>
            Toplam: {totalPoints > 0 ? `+${totalPoints}` : totalPoints}
          </Text>
        </View>
        {points.length === 0 ? (
          <Text style={styles.empty}>Henüz puan kaydı yok.</Text>
        ) : (
          points.map((item) => (
            <View key={item.id} style={styles.row}>
              <Text style={styles.rowText}>{item.reason || "Davranış puanı"}</Text>
              <Text style={[styles.rowValue, item.points >= 0 ? styles.positive : styles.negative]}>
                {item.points > 0 ? `+${item.points}` : item.points}
              </Text>
            </View>
          ))
        )}
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Notlarım</Text>
        {grades.length === 0 ? (
          <Text style={styles.empty}>Henüz not girilmedi.</Text>
        ) : (
          grades.map((item) => (
            <View key={item.id} style={styles.row}>
              <Text style={styles.rowText}>{item.title}</Text>
              <Text style={styles.rowValue}>
                {item.score}/{item.max_score}
              </Text>
            </View>
          ))
        )}
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Duyurular</Text>
        {announcements.length === 0 ? (
          <Text style={styles.empty}>Henüz duyuru yok.</Text>
        ) : (
          announcements.map((item) => (
            <View key={item.id} style={styles.row}>
              <View style={{ flex: 1 }}>
                <Text style={styles.rowTitle}>{item.title}</Text>
                <Text style={styles.rowText}>{item.content}</Text>
              </View>
            </View>
          ))
        )}
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Ödevler</Text>
        {homework.length === 0 ? (
          <Text style={styles.empty}>Henüz ödev yok.</Text>
        ) : (
          homework.map((item) => (
            <View key={item.id} style={styles.row}>
              <View style={{ flex: 1 }}>
                <Text style={styles.rowTitle}>{item.title}</Text>
                {item.description ? <Text style={styles.rowText}>{item.description}</Text> : null}
                {item.due_date ? <Text style={styles.dueDate}>Teslim: {item.due_date}</Text> : null}
              </View>
            </View>
          ))
        )}
      </View>
    </ScrollView>
  )
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  center: { flex: 1, alignItems: "center", justifyContent: "center", backgroundColor: colors.background },
  header: { flexDirection: "row", alignItems: "center", justifyContent: "space-between" },
  className: { fontSize: 24, fontWeight: "700", color: colors.text },
  messagesButton: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    backgroundColor: colors.primary,
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  messagesButtonText: { color: colors.primaryText, fontWeight: "600" },
  section: {
    backgroundColor: colors.surface,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.border,
    padding: 16,
    gap: 8,
  },
  sectionHeaderRow: { flexDirection: "row", justifyContent: "space-between", alignItems: "center" },
  sectionTitle: { fontSize: 16, fontWeight: "600", color: colors.text },
  totalPoints: { fontWeight: "700" },
  row: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    borderTopWidth: 1,
    borderTopColor: colors.border,
    paddingTop: 8,
    marginTop: 8,
  },
  rowTitle: { fontWeight: "600", color: colors.text, marginBottom: 2 },
  rowText: { color: colors.text, flex: 1 },
  rowValue: { fontWeight: "700", marginLeft: 8 },
  dueDate: { color: colors.muted, fontSize: 12, marginTop: 4 },
  positive: { color: colors.success },
  negative: { color: colors.danger },
  empty: { color: colors.muted },
})
