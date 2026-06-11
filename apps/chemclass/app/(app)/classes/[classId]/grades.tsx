import { useMemo, useState } from "react"
import { ActivityIndicator, FlatList, StyleSheet, Text, TextInput, TouchableOpacity, View } from "react-native"
import { useLocalSearchParams } from "expo-router"
import { Ionicons } from "@expo/vector-icons"
import { supabase, useAuth, useClassRoster, useRealtimeList } from "@chemclass/shared"
import { colors } from "../../../../constants/colors"

export default function GradesScreen() {
  const { classId } = useLocalSearchParams<{ classId: string }>()
  const { profile } = useAuth()
  const { roster, loading: loadingRoster } = useClassRoster(classId ?? null)

  const { data: grades, loading: loadingGrades } = useRealtimeList({
    table: "grades",
    match: { class_id: classId },
    orderBy: { column: "created_at", ascending: false },
  })

  const studentNames = useMemo(() => {
    const map = new Map<string, string>()
    for (const entry of roster) {
      if (entry.profile) map.set(entry.student_id, entry.profile.full_name)
    }
    return map
  }, [roster])

  const [selectedStudentId, setSelectedStudentId] = useState<string | null>(null)
  const [title, setTitle] = useState("")
  const [score, setScore] = useState("")
  const [maxScore, setMaxScore] = useState("100")
  const [sending, setSending] = useState(false)

  const onCreate = async () => {
    const scoreValue = Number(score)
    const maxScoreValue = Number(maxScore)
    if (!selectedStudentId || !title.trim() || !profile || !classId) return
    if (Number.isNaN(scoreValue) || Number.isNaN(maxScoreValue)) return
    setSending(true)
    const { error } = await supabase.from("grades").insert({
      class_id: classId,
      student_id: selectedStudentId,
      given_by: profile.id,
      title: title.trim(),
      score: scoreValue,
      max_score: maxScoreValue,
    })
    setSending(false)
    if (!error) {
      setTitle("")
      setScore("")
    }
  }

  const onDelete = async (id: string) => {
    await supabase.from("grades").delete().eq("id", id)
  }

  return (
    <FlatList
      style={styles.container}
      data={grades}
      keyExtractor={(item) => item.id}
      contentContainerStyle={{ padding: 16, gap: 12 }}
      ListHeaderComponent={
        <View style={styles.form}>
          <Text style={styles.sectionTitle}>Yeni Not</Text>
          {loadingRoster ? (
            <ActivityIndicator color={colors.primary} />
          ) : (
            <FlatList
              horizontal
              data={roster}
              keyExtractor={(item) => item.student_id}
              showsHorizontalScrollIndicator={false}
              contentContainerStyle={{ gap: 8 }}
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
          <TextInput style={styles.input} placeholder="Sınav / Ödev adı" value={title} onChangeText={setTitle} />
          <View style={styles.scoreRow}>
            <TextInput
              style={[styles.input, { flex: 1 }]}
              placeholder="Puan"
              keyboardType="numeric"
              value={score}
              onChangeText={setScore}
            />
            <Text style={styles.scoreSeparator}>/</Text>
            <TextInput
              style={[styles.input, { flex: 1 }]}
              placeholder="Üst Limit"
              keyboardType="numeric"
              value={maxScore}
              onChangeText={setMaxScore}
            />
          </View>
          <TouchableOpacity
            style={styles.submitButton}
            onPress={onCreate}
            disabled={sending || !selectedStudentId || !title.trim() || !score.trim()}
          >
            {sending ? <ActivityIndicator color={colors.primaryText} /> : <Text style={styles.submitButtonText}>Notu Kaydet</Text>}
          </TouchableOpacity>
          <Text style={styles.sectionTitle}>Notlar</Text>
          {loadingGrades ? <ActivityIndicator color={colors.primary} /> : null}
        </View>
      }
      ListEmptyComponent={!loadingGrades ? <Text style={styles.empty}>Henüz not girilmedi.</Text> : null}
      renderItem={({ item }) => (
        <View style={styles.card}>
          <View style={{ flex: 1 }}>
            <Text style={styles.cardTitle}>{studentNames.get(item.student_id) ?? "Öğrenci"}</Text>
            <Text style={styles.cardText}>{item.title}</Text>
          </View>
          <Text style={styles.cardScore}>
            {item.score}/{item.max_score}
          </Text>
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
  scoreRow: { flexDirection: "row", alignItems: "center", gap: 8 },
  scoreSeparator: { fontSize: 18, color: colors.muted, fontWeight: "600" },
  submitButton: {
    backgroundColor: colors.primary,
    borderRadius: 10,
    paddingVertical: 14,
    alignItems: "center",
  },
  submitButtonText: { color: colors.primaryText, fontWeight: "600" },
  empty: { textAlign: "center", color: colors.muted, marginTop: 16 },
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
  cardScore: { fontWeight: "700", color: colors.primary },
})
