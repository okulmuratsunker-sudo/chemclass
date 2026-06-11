import "react-native-url-polyfill/auto"
import AsyncStorage from "@react-native-async-storage/async-storage"
import { createClient } from "@supabase/supabase-js"
import type { Database } from "./database.types"

export const SUPABASE_URL = "https://zajzfbvduhewrvaetyuk.supabase.co"
export const SUPABASE_PUBLISHABLE_KEY = "sb_publishable_X2JnnRYovgj3D7pDbhfN-A_VWSDIXEt"

export const supabase = createClient<Database>(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
  auth: {
    storage: AsyncStorage,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false,
  },
})
