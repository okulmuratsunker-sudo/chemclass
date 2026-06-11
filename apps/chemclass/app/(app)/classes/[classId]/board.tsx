import { useState } from "react"
import { ActivityIndicator, ScrollView, Share, StyleSheet, Text, TextInput, TouchableOpacity, View } from "react-native"
import { useLocalSearchParams } from "expo-router"
import { useBoardSessionForClass, useBoardState, useClassRoster } from "@chemclass/shared"
import { colors } from "../../../../constants/colors"

const TAHTA_URL = "https://tahta.chemclass.app"

function shuffle<T>(items: T[]): T[] {
  const arr = [...items]
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[arr[i], arr[j]] = [arr[j], arr[i]]
  }
  return arr
}

export default function BoardScreen() {
  const { classId } = useLocalSearchParams<{ classId: string }>()
  const { boardSession, loading: loadingSession } = useBoardSessionForClass(classId ?? null)
  const { state, updateState } = useBoardState(boardSession?.id ?? null)
  const { roster } = useClassRoster(classId ?? null)

  const [minutes, setMinutes] = useState("5")
  const [groupCount, setGroupCount] = useState("4")

  const onShareLink = async () => {
    if (!boardSession) return
    await Share.share({
      message: `ChemClass Tahtası: ${TAHTA_URL}\nSınıf kodu: ${boardSession.code}`,
    })
  }

  const onStartCountdown = async () => {
    const total = Math.max(1, parseInt(minutes, 10) || 0) * 60
    const endsAt = new Date(Date.now() + total * 1000).toISOString()
    await updateState("countdown", { durationSeconds: total, endsAt })
  }

  const onStopCountdown = async () => {
    await updateState("idle", {})
  }

  const onSelectStudent = async (studentId: string, studentName: string) => {
    await updateState("student", { studentId, studentName })
  }

  const onSelectRandomStudent = async () => {
    if (roster.length === 0) return
    const pick = roster[Math.floor(Math.random() * roster.length)]
    await onSelectStudent(pick.student_id, pick.profile?.full_name ?? "Öğrenci")
  }

  const onCreateGroups = async () => {
    const count = Math.max(1, parseInt(groupCount, 10) || 1)
    const shuffled = shuffle(roster)
    const groups: { name: string; members: string[] }[] = Array.from({ length: count }, (_, i) => ({
      name: `Grup ${i + 1}`,
      members: [],
    }))
    shuffled.forEach((entry, index) => {
      groups[index % count].members.push(entry.profile?.full_name ?? "Öğrenci")
    })
    await updateState("groups", { groups })
  }

  const onClear = async () => {
    await updateState("idle", {})
  }

  if (loadingSession || !boardSession) {
    return (
      <View style={styles.center}>
        <ActivityIndicator color={colors.primary} />
      </View>
    )
  }

  return (
    <ScrollView style={styles.container} contentContainerStyle={{ padding: 16, gap: 16 }}>
      <View style={styles.codeCard}>
        <Text style={styles.codeLabel}>Tahta Kodu</Text>
        <Text style={styles.codeValue}>{boardSession.code}</Text>
        <TouchableOpacity style={styles.shareButton} onPress={onShareLink}>
          <Text style={styles.shareButtonText}>Linki Paylaş</Text>
        </TouchableOpacity>
        {state ? <Text style={styles.stateInfo}>Tahtada şu an: {state.state_type}</Text> : null}
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Geri Sayım</Text>
        <View style={styles.row}>
          <TextInput
            style={styles.minutesInput}
            keyboardType="number-pad"
            value={minutes}
            onChangeText={setMinutes}
          />
          <Text style={styles.rowLabel}>dakika</Text>
          <TouchableOpacity style={styles.actionButton} onPress={onStartCountdown}>
            <Text style={styles.actionButtonText}>Başlat</Text>
          </TouchableOpacity>
          <TouchableOpacity style={[styles.actionButton, styles.secondaryButton]} onPress={onStopCountdown}>
            <Text style={styles.secondaryButtonText}>Durdur</Text>
          </TouchableOpacity>
        </View>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Öğrenci Seç</Text>
        <TouchableOpacity style={styles.actionButton} onPress={onSelectRandomStudent}>
          <Text style={styles.actionButtonText}>Rastgele Öğrenci Seç</Text>
        </TouchableOpacity>
        <View style={styles.chipWrap}>
          {roster.map((entry) => (
            <TouchableOpacity
              key={entry.student_id}
              style={styles.chip}
              onPress={() => onSelectStudent(entry.student_id, entry.profile?.full_name ?? "Öğrenci")}
            >
              <Text style={styles.chipText}>{entry.profile?.full_name ?? "İsimsiz"}</Text>
            </TouchableOpacity>
          ))}
        </View>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Grup Oluştur</Text>
        <View style={styles.row}>
          <TextInput
            style={styles.minutesInput}
            keyboardType="number-pad"
            value={groupCount}
            onChangeText={setGroupCount}
          />
          <Text style={styles.rowLabel}>grup</Text>
          <TouchableOpacity style={styles.actionButton} onPress={onCreateGroups}>
            <Text style={styles.actionButtonText}>Oluştur</Text>
          </TouchableOpacity>
        </View>
      </View>

      <TouchableOpacity style={[styles.actionButton, styles.secondaryButton]} onPress={onClear}>
        <Text style={styles.secondaryButtonText}>Tahtayı Temizle</Text>
      </TouchableOpacity>
    </ScrollView>
  )
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  center: { flex: 1, alignItems: "center", justifyContent: "center", backgroundColor: colors.background },
  codeCard: {
    backgroundColor: colors.surface,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.border,
    padding: 20,
    alignItems: "center",
    gap: 8,
  },
  codeLabel: { color: colors.muted, fontSize: 14 },
  codeValue: { fontSize: 36, fontWeight: "800", letterSpacing: 4, color: colors.primary },
  shareButton: { marginTop: 4, paddingVertical: 8, paddingHorizontal: 16, borderRadius: 8, backgroundColor: colors.primary },
  shareButtonText: { color: colors.primaryText, fontWeight: "600" },
  stateInfo: { color: colors.muted, fontSize: 13, marginTop: 4 },
  section: {
    backgroundColor: colors.surface,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.border,
    padding: 16,
    gap: 12,
  },
  sectionTitle: { fontSize: 16, fontWeight: "600", color: colors.text },
  row: { flexDirection: "row", alignItems: "center", gap: 8 },
  rowLabel: { color: colors.muted },
  minutesInput: {
    width: 64,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    paddingHorizontal: 10,
    paddingVertical: 8,
    fontSize: 16,
    textAlign: "center",
  },
  actionButton: { backgroundColor: colors.primary, borderRadius: 8, paddingVertical: 10, paddingHorizontal: 16, alignItems: "center" },
  actionButtonText: { color: colors.primaryText, fontWeight: "600" },
  secondaryButton: { backgroundColor: "#f1f5f9" },
  secondaryButtonText: { color: colors.text, fontWeight: "600" },
  chipWrap: { flexDirection: "row", flexWrap: "wrap", gap: 8 },
  chip: { backgroundColor: "#f1f5f9", borderRadius: 999, paddingHorizontal: 14, paddingVertical: 8 },
  chipText: { color: colors.text, fontWeight: "500" },
})
