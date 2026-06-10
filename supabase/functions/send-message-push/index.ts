// Supabase Edge Function: send-message-push
//
// chemclass_messages tablosuna yeni bir satır eklendiğinde
// (Database Webhook ile) çağrılır. Eğer mesaj öğretmenden
// geliyorsa, ilgili öğrenci(ler)in cihaz token'larına FCM HTTP v1
// API üzerinden push bildirim gönderir.
//
// Gerekli ortam değişkenleri (Supabase Dashboard > Edge Functions > Secrets):
//   FCM_PROJECT_ID          -> Firebase proje ID'si
//   FCM_SERVICE_ACCOUNT_JSON -> Firebase servis hesabı JSON içeriği (tek satır)
//   SUPABASE_URL ve SUPABASE_SERVICE_ROLE_KEY otomatik olarak sağlanır.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_PROJECT_ID = Deno.env.get("FCM_PROJECT_ID")!;
const FCM_SERVICE_ACCOUNT_JSON = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON")!;

const sb = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

function base64UrlEncode(bytes: Uint8Array | string): string {
  const raw = typeof bytes === "string" ? bytes : String.fromCharCode(...bytes);
  return btoa(raw).replace(/=+$/, "").replace(/\+/g, "-").replace(/\//g, "_");
}

// Firebase servis hesabı private key'i ile imzalanmış bir JWT
// oluşturup Google OAuth2 token endpoint'inden access token alır.
async function getAccessToken(): Promise<string> {
  const sa = JSON.parse(FCM_SERVICE_ACCOUNT_JSON);
  const now = Math.floor(Date.now() / 1000);

  const header = { alg: "RS256", typ: "JWT" };
  const claims = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const unsigned =
    `${base64UrlEncode(JSON.stringify(header))}.${base64UrlEncode(JSON.stringify(claims))}`;

  const pem = (sa.private_key as string)
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const keyBytes = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    keyBytes,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(unsigned),
  );

  const jwt = `${unsigned}.${base64UrlEncode(new Uint8Array(signature))}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const data = await res.json();
  if (!res.ok) throw new Error(`OAuth token error: ${JSON.stringify(data)}`);
  return data.access_token as string;
}

async function sendPush(
  token: string,
  title: string,
  body: string,
  accessToken: string,
) {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          apns: { payload: { aps: { sound: "default" } } },
        },
      }),
    },
  );

  if (!res.ok) {
    const err = await res.text();
    console.error(`FCM send error for token ${token}: ${err}`);
    // Geçersiz/iptal edilmiş token'ları temizle
    if (res.status === 404 || res.status === 400) {
      await sb.from("chemclass_device_tokens").delete().eq("token", token);
    }
  }
}

Deno.serve(async (req) => {
  try {
    const payload = await req.json();
    const record = payload.record as Record<string, unknown> | undefined;

    // Sadece öğretmenden öğrenciye giden mesajlar için bildirim gönder
    if (!record || record.sender !== "teacher") {
      return new Response("ignored", { status: 200 });
    }

    let query = sb
      .from("chemclass_device_tokens")
      .select("token")
      .eq("role", "student")
      .eq("teacher_id", record.teacher_id as string);

    if (record.student_id) {
      query = query.eq("student_id", record.student_id as string);
    } else if (record.class_name) {
      query = query.eq("class_name", record.class_name as string);
    }
    // ikisi de null ise: tüm öğrencilere genel duyuru

    const { data: tokens, error } = await query;
    if (error) throw error;
    if (!tokens || tokens.length === 0) {
      return new Response("no tokens", { status: 200 });
    }

    const accessToken = await getAccessToken();
    const title = (record.sender_name as string) || "ChemClass";
    const body = String(record.body ?? "").slice(0, 200);

    await Promise.all(
      tokens.map((t) => sendPush(t.token as string, title, body, accessToken)),
    );

    return new Response("ok", { status: 200 });
  } catch (e) {
    console.error(e);
    return new Response(String(e), { status: 500 });
  }
});
