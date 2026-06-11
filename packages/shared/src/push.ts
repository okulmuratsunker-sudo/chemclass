import { supabase } from "./supabaseClient"

/** Saves (or updates) the Expo push token for a user. The token is obtained via expo-notifications in each app. */
export async function savePushToken(userId: string, expoPushToken: string) {
  const { error } = await supabase
    .from("push_tokens")
    .upsert({ user_id: userId, expo_push_token: expoPushToken }, { onConflict: "expo_push_token" })
  return { error }
}

/** Removes a push token, e.g. on sign out. */
export async function removePushToken(expoPushToken: string) {
  const { error } = await supabase.from("push_tokens").delete().eq("expo_push_token", expoPushToken)
  return { error }
}
