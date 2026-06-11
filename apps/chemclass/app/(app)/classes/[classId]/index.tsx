import { useMemo, useState } from "react"
import { ActivityIndicator, FlatList, ScrollView, Share, StyleSheet, Text, TouchableOpacity, View } from "react-native"
import { useLocalSearchParams, useRouter } from "expo-router"
import { Ionicons } from "@expo/vector-icons"
import { giveBehaviorPoint, useAuth, useClass, useClassRoster, useRealtimeList } from "@chemclass/shared"
import { colors } from "../../../../constants/colors"

const POINT_OPTIONS = [-5, -1, 1, 5]

const QUICK_ACTIONS = [
  { key: "messages", label: "Mesajlar", icon: "chatbubble-outline" as const },
  { key: "board", label: "Tahta", icon: "easel-outline" as const },
  { key: "announcements", label: "Duyurular", icon: "megaphone-outline" as const },
  { key: "homework", label: "Ödevler", icon: "book-outline" as const },
  { key: "grades", label: "Notlar", icon: "school-outline" as const },
]

export default function ClassDetailScreen() {
  const { classId } = useLocalSearchParams<{ classId: string }>()
  const router = useRouter()
  const { profile } = useAuth()
  const { classRow, loading: loadingClass } = useClass(classId ?? null)
  const { roster, loading: loadingRoster } = useClassRoster(classId ?? null)
  const { data: points } = useRealtimeList({
    table: "behavior_points",
    match: { class_id: classId },
    orderBy: { column: "created_at", ascending: false },
  })

  const [selectedStudentId, setSelectedStudentId] = useState<string | null>(null)
  const [sending, setSending] = useState(false)

  const studentNames = useMemo(() => {
    const map = new Map<string, string>()
    for (const entry of roster) {
      if (entry.profile) map.set(entry.student_id, entry.profile.full_name)
    }
    return map
  }, [roster])

  const onSharCode = async () => {
    if (!classRow) return
    await Share.share({
      message: `${classRow.name} sınıfına katılmak için ChemClass Öğrenci uygulamasında bu kodu kullan: ${classRow.join_code}`,
    })
  }

  const onGivePoint = async (value: number) => {
    if (!classId || !selectedStudentId || !profile) return
    setSending(true)
    await giveBehaviorPoint({
      classId,
      studentId: selectedStudentId,
      givenBy: profile.id,
      points: value,
    })
    setSending(false)
  }

  if (loadingClass || !classRow) {
    return (
      <View style={styles.center}>
        <ActivityIndicator color={colors.primary} />
      </View>
    )
  }

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.className}>{classRow.name}</Text>
        <View style={styles.headerActions}>
          <TouchableOpacity style={styles.codeChip} onPress={onSharCode}>
            <Ionicons name="share-outline" size={16} color={colors.primary} />
            <Text style={styles.codeText}>Kod: {classRow.join_code}</Text>
          </TouchableOpacity>
        </View>
      </View>

      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.quickActions}>
        {QUICK_ACTIONS.map((action) => (
          <TouchableOpacity
            key={action.key}
            style={styles.quickActionButton}
            onPress={() => router.push(`/classes/${classId}/${action.key}`)}
          >
            <Ionicons name={action.icon} size={18} color={colors.primaryText} />
            <Text style={styles.quickActionText}>{action.label}</Text>
          </TouchableOpacity>
        ))}
      </ScrollView>

      <Text style={styles.sectionTitle}>Öğrenci Seç</Text>
      {loadingRoster ? (
        <ActivityIndicator color={colors.primary} />
      ) : (
        <FlatList
          horizontal
          data={roster}
          keyExtractor={(item) => item.student_id}
          contentContainerStyle={{ paddingHorizontal: 16, gap: 8 }}
          showsHorizontalScrollIndicator={false}
          ListEmptyComponent={<Text style={styles.empty}>Bu sınıfa henüz öğrenci katılmadı.</Text>}
          renderItem={({ item }) => {
            const selected = item.student_id === selectedStudentId
            return (
              <TouchableOpacity
                style={[styles.studentChip, selected && styles.studentChipSelected]}
                onPress={() => setSelectedStudentId(item.student_id)}
              >
                <Text style={[styles.studentChipText, selected && styles.studentChipTextSelected]}>
                  {item.profile?.full_name ?? "İsimsiz"}
                </Text>
              </TouchableOpacity>
            )
          }}
        />
      )}

      <Text style={styles.sectionTitle}>Davranış Puanı Ver</Text>
      <View style={styles.pointsRow}>
        {POINT_OPTIONS.map((value) => (
          <TouchableOpacity
            key={value}
            style={[styles.pointButton, value > 0 ? styles.pointButtonPositive : styles.pointButtonNegative]}
            disabled={!selectedStudentId || sending}
            onPress={() => onGivePoint(value)}
          >
            <Text style={styles.pointButtonText}>{value > 0 ? `+${value}` : value}</Text>
          </TouchableOpacity>
        ))}
      </View>

      <Text style={styles.sectionTitle}>Son Hareketler</Text>
      <FlatList
        style={{ flex: 1 }}
        data={points}
        keyExtractor={(item) => item.id}
        contentContainerStyle={{ padding: 16, paddingTop: 0, gap: 8 }}
        ListEmptyComponent={<Text style={styles.empty}>Henüz puan verilmedi.</Text>}
        renderItem={({ item }) => (
          <View style={styles.pointRow}>
            <Text style={styles.pointRowName}>{studentNames.get(item.student_id) ?? "Öğrenci"}</Text>
            <Text style={[styles.pointRowValue, item.points >= 0 ? styles.positive : styles.negative]}>
              {item.points > 0 ? `+${item.points}` : item.points}
            </Text>
          </View>
        )}
      />
    </View>
  )
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  center: { flex: 1, alignItems: "center", justifyContent: "center", backgroundColor: colors.background },
  header: { padding: 16, gap: 12 },
  className: { fontSize: 24, fontWeight: "700", color: colors.text },
  headerActions: { flexDirection: "row", gap: 8, flexWrap: "wrap" },
  codeChip: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  codeText: { color: colors.primary, fontWeight: "600" },
  quickActions: { paddingHorizontal: 16, gap: 8 },
  quickActionButton: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    backgroundColor: colors.primary,
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  quickActionText: { color: colors.primaryText, fontWeight: "600" },
  sectionTitle: { fontSize: 16, fontWeight: "600", color: colors.text, marginHorizontal: 16, marginTop: 16, marginBottom: 8 },
  studentChip: {
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 999,
    paddingHorizontal: 16,
    paddingVertical: 10,
  },
  studentChipSelected: { backgroundColor: colors.primary, borderColor: colors.primary },
  studentChipText: { color: colors.text, fontWeight: "500" },
  studentChipTextSelected: { color: colors.primaryText },
  pointsRow: { flexDirection: "row", gap: 8, marginHorizontal: 16 },
  pointButton: { flex: 1, borderRadius: 10, paddingVertical: 14, alignItems: "center" },
  pointButtonPositive: { backgroundColor: "#dcfce7" },
  pointButtonNegative: { backgroundColor: "#fee2e2" },
  pointButtonText: { fontWeight: "700", fontSize: 16, color: colors.text },
  pointRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    backgroundColor: colors.surface,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: colors.border,
    paddingHorizontal: 14,
    paddingVertical: 10,
  },
  pointRowName: { color: colors.text, fontWeight: "500" },
  pointRowValue: { fontWeight: "700" },
  positive: { color: colors.success },
  negative: { color: colors.danger },
  empty: { textAlign: "center", color: colors.muted, marginVertical: 16 },
})
