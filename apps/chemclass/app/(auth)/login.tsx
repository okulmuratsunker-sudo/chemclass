import { useState } from "react"
import { ActivityIndicator, KeyboardAvoidingView, Platform, StyleSheet, Text, TextInput, TouchableOpacity } from "react-native"
import { Link } from "expo-router"
import { useAuth } from "@chemclass/shared"
import { colors } from "../../constants/colors"

export default function LoginScreen() {
  const { signIn } = useAuth()
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [error, setError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)

  const onSubmit = async () => {
    setError(null)
    if (!email || !password) {
      setError("E-posta ve şifre gerekli.")
      return
    }
    setSubmitting(true)
    const { error: signInError } = await signIn({ email: email.trim(), password })
    setSubmitting(false)
    if (signInError) {
      setError(signInError.message)
    }
  }

  return (
    <KeyboardAvoidingView style={styles.container} behavior={Platform.OS === "ios" ? "padding" : undefined}>
      <Text style={styles.title}>ChemClass</Text>
      <Text style={styles.subtitle}>Öğretmen Girişi</Text>

      <TextInput
        style={styles.input}
        placeholder="E-posta"
        autoCapitalize="none"
        keyboardType="email-address"
        value={email}
        onChangeText={setEmail}
      />
      <TextInput style={styles.input} placeholder="Şifre" secureTextEntry value={password} onChangeText={setPassword} />

      {error ? <Text style={styles.error}>{error}</Text> : null}

      <TouchableOpacity style={styles.button} onPress={onSubmit} disabled={submitting}>
        {submitting ? <ActivityIndicator color={colors.primaryText} /> : <Text style={styles.buttonText}>Giriş Yap</Text>}
      </TouchableOpacity>

      <Link href="/signup" style={styles.link}>
        Hesabın yok mu? Kayıt ol
      </Link>
    </KeyboardAvoidingView>
  )
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: "center",
    padding: 24,
    backgroundColor: colors.background,
  },
  title: {
    fontSize: 32,
    fontWeight: "700",
    color: colors.primary,
    textAlign: "center",
  },
  subtitle: {
    fontSize: 16,
    color: colors.muted,
    textAlign: "center",
    marginBottom: 32,
  },
  input: {
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 10,
    paddingHorizontal: 16,
    paddingVertical: 14,
    fontSize: 16,
    marginBottom: 12,
  },
  button: {
    backgroundColor: colors.primary,
    borderRadius: 10,
    paddingVertical: 14,
    alignItems: "center",
    marginTop: 8,
  },
  buttonText: {
    color: colors.primaryText,
    fontSize: 16,
    fontWeight: "600",
  },
  error: {
    color: colors.danger,
    marginBottom: 8,
    textAlign: "center",
  },
  link: {
    textAlign: "center",
    marginTop: 20,
    color: colors.primary,
    fontSize: 14,
  },
})
