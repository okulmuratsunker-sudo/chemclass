import { useState } from "react"
import { ActivityIndicator, KeyboardAvoidingView, Platform, StyleSheet, Text, TextInput, TouchableOpacity } from "react-native"
import { Link } from "expo-router"
import { useAuth } from "@chemclass/shared"
import { colors } from "../../constants/colors"

export default function SignupScreen() {
  const { signUp } = useAuth()
  const [fullName, setFullName] = useState("")
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [error, setError] = useState<string | null>(null)
  const [info, setInfo] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)

  const onSubmit = async () => {
    setError(null)
    setInfo(null)
    if (!fullName || !email || !password) {
      setError("Tüm alanları doldurun.")
      return
    }
    if (password.length < 6) {
      setError("Şifre en az 6 karakter olmalı.")
      return
    }
    setSubmitting(true)
    const { error: signUpError } = await signUp({
      email: email.trim(),
      password,
      fullName: fullName.trim(),
      role: "student",
    })
    setSubmitting(false)
    if (signUpError) {
      setError(signUpError.message)
      return
    }
    setInfo("Hesabınız oluşturuldu. Giriş yapabilirsiniz.")
  }

  return (
    <KeyboardAvoidingView style={styles.container} behavior={Platform.OS === "ios" ? "padding" : undefined}>
      <Text style={styles.title}>ChemClass</Text>
      <Text style={styles.subtitle}>Öğrenci Kaydı</Text>

      <TextInput style={styles.input} placeholder="Ad Soyad" value={fullName} onChangeText={setFullName} />
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
      {info ? <Text style={styles.info}>{info}</Text> : null}

      <TouchableOpacity style={styles.button} onPress={onSubmit} disabled={submitting}>
        {submitting ? <ActivityIndicator color={colors.primaryText} /> : <Text style={styles.buttonText}>Kayıt Ol</Text>}
      </TouchableOpacity>

      <Link href="/login" style={styles.link}>
        Zaten hesabın var mı? Giriş yap
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
  info: {
    color: colors.success,
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
