import { useEffect, useState } from "react"
import { ActivityIndicator, StyleSheet, Text, TextInput, TouchableOpacity, View } from "react-native"
import AsyncStorage from "@react-native-async-storage/async-storage"
import { redeemBoardCode, useBoardState } from "@chemclass/shared"
import { colors } from "../constants/colors"

const STORAGE_KEY_SESSION = "tahta:boardSessionId"
const STORAGE_KEY_CODE = "tahta:code"

function useClock() {
  const [now, setNow] = useState(() => new Date())
  useEffect(() => {
    const id = setInterval(() => setNow(new Date()), 1000)
    return () => clearInterval(id)
  }, [])
  return now
}

function formatClock(date: Date) {
  const pad = (n: number) => n.toString().padStart(2, "0")
  return `${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`
}

function CountdownView({ endsAt, durationSeconds }: { endsAt?: string; durationSeconds?: number }) {
  const now = useClock()
  const target = endsAt ? new Date(endsAt).getTime() : 0
  const remaining = Math.max(0, Math.round((target - now.getTime()) / 1000))
  const finished = remaining <= 0
  const minutes = Math.floor(remaining / 60)
  const seconds = remaining % 60
  const total = durationSeconds && durationSeconds > 0 ? durationSeconds : remaining || 1
  const progress = finished ? 0 : Math.min(1, remaining / total)

  return (
    <View style={styles.centerFill}>
      <Text style={styles.label}>GERİ SAYIM</Text>
      <Text style={[styles.countdownText, finished && styles.countdownFinished]}>
        {finished ? "SÜRE DOLDU" : `${minutes.toString().padStart(2, "0")}:${seconds.toString().padStart(2, "0")}`}
      </Text>
      {!finished ? (
        <View style={styles.progressTrack}>
          <View style={[styles.progressFill, { width: `${progress * 100}%` }]} />
        </View>
      ) : null}
    </View>
  )
}

function StudentView({ studentName }: { studentName?: string }) {
  return (
    <View style={styles.centerFill}>
      <Text style={styles.label}>SIRADA</Text>
      <Text style={styles.studentName}>{studentName || "Öğrenci"}</Text>
    </View>
  )
}

function GroupsView({ groups }: { groups?: { name: string; members: string[] }[] }) {
  if (!groups || groups.length === 0) {
    return (
      <View style={styles.centerFill}>
        <Text style={styles.label}>GRUPLAR</Text>
        <Text style={styles.muted}>Henüz grup oluşturulmadı.</Text>
      </View>
    )
  }
  return (
    <View style={styles.fill}>
      <Text style={[styles.label, { marginTop: 24, marginLeft: 24 }]}>GRUPLAR</Text>
      <View style={styles.groupGrid}>
        {groups.map((group, index) => (
          <View key={`${group.name}-${index}`} style={styles.groupCard}>
            <Text style={styles.groupName}>{group.name}</Text>
            {group.members.map((member, memberIndex) => (
              <Text key={`${member}-${memberIndex}`} style={styles.groupMember}>
                {member}
              </Text>
            ))}
          </View>
        ))}
      </View>
    </View>
  )
}

function IdleView({ code, now }: { code: string; now: Date }) {
  return (
    <View style={styles.centerFill}>
      <Text style={styles.brand}>ChemClass Tahtası</Text>
      <Text style={styles.clock}>{formatClock(now)}</Text>
      <Text style={styles.muted}>Bağlı sınıf kodu: {code}</Text>
    </View>
  )
}

export default function TahtaScreen() {
  const [hydrated, setHydrated] = useState(false)
  const [boardSessionId, setBoardSessionId] = useState<string | null>(null)
  const [connectedCode, setConnectedCode] = useState<string>("")

  const [codeInput, setCodeInput] = useState("")
  const [connecting, setConnecting] = useState(false)
  const [connectError, setConnectError] = useState<string | null>(null)

  const now = useClock()
  const { state, loading: loadingState, error: stateError } = useBoardState(boardSessionId)

  useEffect(() => {
    ;(async () => {
      const [storedSession, storedCode] = await Promise.all([
        AsyncStorage.getItem(STORAGE_KEY_SESSION),
        AsyncStorage.getItem(STORAGE_KEY_CODE),
      ])
      if (storedSession) {
        setBoardSessionId(storedSession)
        setConnectedCode(storedCode ?? "")
      }
      setHydrated(true)
    })()
  }, [])

  useEffect(() => {
    if (boardSessionId && !loadingState && stateError) {
      // Saved session no longer exists (e.g. class deleted) — go back to code entry.
      AsyncStorage.multiRemove([STORAGE_KEY_SESSION, STORAGE_KEY_CODE])
      setBoardSessionId(null)
      setConnectedCode("")
    }
  }, [boardSessionId, loadingState, stateError])

  const onConnect = async () => {
    const code = codeInput.trim().toUpperCase()
    if (code.length < 4) {
      setConnectError("Lütfen sınıf kodunu girin.")
      return
    }
    setConnecting(true)
    setConnectError(null)
    const { boardSessionId: id, error } = await redeemBoardCode(code)
    setConnecting(false)
    if (error || !id) {
      setConnectError("Kod bulunamadı. Lütfen tekrar deneyin.")
      return
    }
    await AsyncStorage.setItem(STORAGE_KEY_SESSION, id)
    await AsyncStorage.setItem(STORAGE_KEY_CODE, code)
    setBoardSessionId(id)
    setConnectedCode(code)
    setCodeInput("")
  }

  const onDisconnect = async () => {
    await AsyncStorage.multiRemove([STORAGE_KEY_SESSION, STORAGE_KEY_CODE])
    setBoardSessionId(null)
    setConnectedCode("")
    setCodeInput("")
    setConnectError(null)
  }

  if (!hydrated) {
    return (
      <View style={styles.centerFill}>
        <ActivityIndicator color={colors.primary} size="large" />
      </View>
    )
  }

  if (!boardSessionId) {
    return (
      <View style={styles.centerFill}>
        <Text style={styles.brand}>ChemClass Tahtası</Text>
        <Text style={styles.subtitle}>Sınıf kodunu girin</Text>
        <TextInput
          style={styles.codeInput}
          value={codeInput}
          onChangeText={(text) => setCodeInput(text.toUpperCase())}
          placeholder="ÖRN: AB12CD"
          placeholderTextColor={colors.muted}
          autoCapitalize="characters"
          autoCorrect={false}
          maxLength={8}
          onSubmitEditing={onConnect}
        />
        <TouchableOpacity style={styles.connectButton} onPress={onConnect} disabled={connecting}>
          {connecting ? <ActivityIndicator color={colors.primaryText} /> : <Text style={styles.connectButtonText}>Bağlan</Text>}
        </TouchableOpacity>
        {connectError ? <Text style={styles.errorText}>{connectError}</Text> : null}
      </View>
    )
  }

  if (loadingState && !state) {
    return (
      <View style={styles.centerFill}>
        <ActivityIndicator color={colors.primary} size="large" />
      </View>
    )
  }

  return (
    <View style={styles.fill}>
      {!state || state.state_type === "idle" ? <IdleView code={connectedCode} now={now} /> : null}
      {state?.state_type === "countdown" ? (
        <CountdownView
          endsAt={(state.payload as { endsAt?: string })?.endsAt}
          durationSeconds={(state.payload as { durationSeconds?: number })?.durationSeconds}
        />
      ) : null}
      {state?.state_type === "student" ? (
        <StudentView studentName={(state.payload as { studentName?: string })?.studentName} />
      ) : null}
      {state?.state_type === "groups" ? (
        <GroupsView groups={(state.payload as { groups?: { name: string; members: string[] }[] })?.groups} />
      ) : null}

      <TouchableOpacity style={styles.disconnectButton} onPress={onDisconnect}>
        <Text style={styles.disconnectButtonText}>Kod Değiştir</Text>
      </TouchableOpacity>
    </View>
  )
}

const styles = StyleSheet.create({
  fill: { flex: 1, backgroundColor: colors.background },
  centerFill: {
    flex: 1,
    backgroundColor: colors.background,
    alignItems: "center",
    justifyContent: "center",
    padding: 24,
    gap: 16,
  },
  brand: { fontSize: 36, fontWeight: "800", color: colors.text, letterSpacing: 1 },
  subtitle: { fontSize: 18, color: colors.muted },
  clock: { fontSize: 96, fontWeight: "800", color: colors.primary, fontVariant: ["tabular-nums"] },
  muted: { fontSize: 16, color: colors.muted },
  label: { fontSize: 18, fontWeight: "700", color: colors.muted, letterSpacing: 4 },
  errorText: { color: colors.danger, fontSize: 16 },
  codeInput: {
    backgroundColor: colors.surface,
    borderWidth: 2,
    borderColor: colors.border,
    borderRadius: 16,
    paddingHorizontal: 32,
    paddingVertical: 18,
    fontSize: 40,
    fontWeight: "700",
    letterSpacing: 8,
    color: colors.text,
    textAlign: "center",
    minWidth: 320,
  },
  connectButton: {
    backgroundColor: colors.primary,
    borderRadius: 12,
    paddingVertical: 16,
    paddingHorizontal: 48,
    alignItems: "center",
    minWidth: 200,
  },
  connectButtonText: { color: colors.primaryText, fontSize: 20, fontWeight: "700" },
  countdownText: {
    fontSize: 160,
    fontWeight: "800",
    color: colors.text,
    fontVariant: ["tabular-nums"],
  },
  countdownFinished: { color: colors.danger, fontSize: 80 },
  progressTrack: {
    width: "60%",
    maxWidth: 600,
    height: 16,
    borderRadius: 8,
    backgroundColor: colors.card,
    overflow: "hidden",
  },
  progressFill: { height: "100%", backgroundColor: colors.primary, borderRadius: 8 },
  studentName: {
    fontSize: 96,
    fontWeight: "800",
    color: colors.accent,
    textAlign: "center",
  },
  groupGrid: {
    flex: 1,
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 16,
    padding: 24,
    alignContent: "flex-start",
  },
  groupCard: {
    backgroundColor: colors.card,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: colors.border,
    padding: 20,
    minWidth: 220,
    flexGrow: 1,
    gap: 8,
  },
  groupName: { fontSize: 24, fontWeight: "800", color: colors.accent, marginBottom: 4 },
  groupMember: { fontSize: 20, color: colors.text },
  disconnectButton: {
    position: "absolute",
    bottom: 16,
    right: 16,
    backgroundColor: colors.card,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    paddingVertical: 8,
    paddingHorizontal: 14,
    opacity: 0.6,
  },
  disconnectButtonText: { color: colors.muted, fontSize: 12, fontWeight: "600" },
})
