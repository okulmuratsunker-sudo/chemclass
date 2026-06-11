import { useEffect, useMemo, useState } from "react"
import { ScrollView, StyleSheet, Text, TextInput, TouchableOpacity, View } from "react-native"
import { DAYS_OF_WEEK, PERIODS, isoDayOfWeek, useSchedule } from "@chemclass/shared"
import { colors } from "../../constants/colors"

export default function ScheduleScreen() {
  const { entries, setEntry } = useSchedule()
  const [selectedDay, setSelectedDay] = useState(() => isoDayOfWeek(new Date()))
  const [pending, setPending] = useState<Record<number, string>>({})

  useEffect(() => {
    setPending({})
  }, [selectedDay])

  const entryMap = useMemo(() => {
    const map = new Map<number, string>()
    for (const entry of entries) {
      if (entry.day_of_week === selectedDay) map.set(entry.period_number, entry.subject_name)
    }
    return map
  }, [entries, selectedDay])

  const valueFor = (period: number) => pending[period] ?? entryMap.get(period) ?? ""

  const onEndEditing = async (period: number) => {
    const value = pending[period]
    if (value === undefined) return
    await setEntry(selectedDay, period, value)
    setPending((current) => {
      const next = { ...current }
      delete next[period]
      return next
    })
  }

  return (
    <ScrollView style={styles.container} contentContainerStyle={{ padding: 16, gap: 16 }}>
      <Text style={styles.title}>Ders Programım</Text>

      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ gap: 8 }}>
        {DAYS_OF_WEEK.map((day) => {
          const selected = day.value === selectedDay
          return (
            <TouchableOpacity
              key={day.value}
              style={[styles.dayChip, selected && styles.dayChipSelected]}
              onPress={() => setSelectedDay(day.value)}
            >
              <Text style={[styles.dayChipText, selected && styles.dayChipTextSelected]}>{day.label}</Text>
            </TouchableOpacity>
          )
        })}
      </ScrollView>

      <View style={styles.section}>
        {PERIODS.map((period) => (
          <View key={period} style={styles.row}>
            <Text style={styles.periodLabel}>{period}. Ders</Text>
            <TextInput
              style={styles.input}
              value={valueFor(period)}
              onChangeText={(text) => setPending((current) => ({ ...current, [period]: text }))}
              onEndEditing={() => onEndEditing(period)}
              placeholder="Boş"
              placeholderTextColor={colors.muted}
            />
          </View>
        ))}
      </View>
    </ScrollView>
  )
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  title: { fontSize: 24, fontWeight: "700", color: colors.text },
  dayChip: {
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 999,
    paddingHorizontal: 16,
    paddingVertical: 10,
  },
  dayChipSelected: { backgroundColor: colors.primary, borderColor: colors.primary },
  dayChipText: { color: colors.text, fontWeight: "500" },
  dayChipTextSelected: { color: colors.primaryText },
  section: {
    backgroundColor: colors.surface,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.border,
    padding: 16,
    gap: 12,
  },
  row: { flexDirection: "row", alignItems: "center", gap: 12 },
  periodLabel: { width: 64, fontWeight: "600", color: colors.text },
  input: {
    flex: 1,
    backgroundColor: colors.background,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 10,
    paddingHorizontal: 16,
    paddingVertical: 10,
    fontSize: 16,
    color: colors.text,
  },
})
