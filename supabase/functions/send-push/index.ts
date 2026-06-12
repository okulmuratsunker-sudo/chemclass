// ChemClass push notifications — send-push Edge Function
//
// Triggered by Supabase Database Webhooks (INSERT) on chemclass_messages
// and chemclass_assignments. Looks up the affected devices in
// chemclass_push_tokens and sends each one a Firebase Cloud Messaging (FCM)
// HTTP v1 notification.
//
// Required secrets (set via `supabase secrets set ...`):
//   FCM_SERVICE_ACCOUNT_JSON  - full JSON of a Firebase service account key
//                               with the "Firebase Cloud Messaging API" role
// SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY are provided automatically.
//
// See supabase/PUSH_KURULUM.md for the full setup walkthrough.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ASSIGNMENT_TYPE_LABEL: Record<string, string> = {
  odev: "📘 Ödev",
  duyuru: "📢 Duyuru",
  gorev: "✅ Görev",
};

interface WebhookPayload {
  type: string;
  table: string;
  record: Record<string, unknown>;
}

interface ServiceAccount {
  client_email: string;
  private_key: string;
  project_id: string;
}

function base64Url(bytes: ArrayBuffer | string): string {
  const bin = typeof bytes === "string" ? bytes : String.fromCharCode(...new Uint8Array(bytes));
  return btoa(bin).replace(/=+$/, "").replace(/\+/g, "-").replace(/\//g, "_");
}

async function getAccessToken(account: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64Url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = base64Url(JSON.stringify({
    iss: account.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const unsigned = `${header}.${claims}`;

  const pem = account.private_key.replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "").replace(/\s/g, "");
  const keyBytes = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    keyBytes,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  const jwt = `${unsigned}.${base64Url(signature)}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const json = await res.json();
  if (!res.ok) throw new Error(`FCM auth failed: ${JSON.stringify(json)}`);
  return json.access_token as string;
}

async function sendFcm(
  projectId: string,
  accessToken: string,
  fcmToken: string,
  title: string,
  body: string,
): Promise<Response> {
  return fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      message: {
        token: fcmToken,
        notification: { title, body },
      },
    }),
  });
}

Deno.serve(async (req) => {
  let payload: WebhookPayload;
  try {
    payload = await req.json();
  } catch {
    return new Response("bad request", { status: 400 });
  }

  const { table, record } = payload;
  if (!record || payload.type !== "INSERT") {
    return new Response("ignored");
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  let title: string;
  let body: string;
  let query = supabase.from("chemclass_push_tokens").select("fcm_token");

  if (table === "chemclass_messages") {
    const teacherId = record.teacher_id as string;
    if (record.sender === "teacher") {
      title = "💬 Öğretmen";
      body = (record.body as string) ?? "";
      query = query.eq("owner_type", "student").eq("teacher_id", teacherId);
      if (record.student_id) {
        query = query.eq("student_id", record.student_id as string);
      } else if (record.class_name) {
        query = query.eq("class_name", record.class_name as string);
      }
      // else: broadcast to everyone in this teacher's classes (no extra filter)
    } else {
      title = (record.sender_name as string) || "Bir öğrenci";
      body = (record.body as string) ?? "";
      query = query.eq("owner_type", "teacher").eq("teacher_id", teacherId);
    }
  } else if (table === "chemclass_assignments") {
    const className = record.class_name as string;
    title = `${ASSIGNMENT_TYPE_LABEL[record.type as string] ?? record.type} • ${className}`;
    body = (record.title as string) ?? "";
    query = query
      .eq("owner_type", "student")
      .eq("teacher_id", record.teacher_id as string)
      .eq("class_name", className);
  } else {
    return new Response("ignored");
  }

  const { data: tokens, error } = await query;
  if (error) return new Response(`token lookup failed: ${error.message}`, { status: 500 });
  if (!tokens || tokens.length === 0) return new Response("no devices to notify");

  const serviceAccount: ServiceAccount = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT_JSON")!);
  const accessToken = await getAccessToken(serviceAccount);

  const staleTokens: string[] = [];
  for (const { fcm_token } of tokens) {
    const res = await sendFcm(serviceAccount.project_id, accessToken, fcm_token, title, body);
    if (res.status === 404 || res.status === 410) {
      staleTokens.push(fcm_token);
    } else if (!res.ok) {
      console.error(`FCM send failed for ${fcm_token}: ${res.status} ${await res.text()}`);
    }
  }

  if (staleTokens.length > 0) {
    await supabase.from("chemclass_push_tokens").delete().in("fcm_token", staleTokens);
  }

  return new Response("ok");
});
