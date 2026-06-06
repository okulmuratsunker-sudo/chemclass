// ─────────────────────────────────────────────────────────────────────────────
// Kasa Worker  —  Cloudflare Worker + D1 + R2
// Endpoints:
//   POST   /auth/register
//   POST   /auth/login
//   GET    /health
//   GET    /bills          POST /bills
//   PUT    /bills/:id      DELETE /bills/:id
//   GET    /ids            POST /ids
//   PUT    /ids/:id        DELETE /ids/:id
//   POST   /upload
//   GET    /files/:key
// ─────────────────────────────────────────────────────────────────────────────

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS });
    }

    const url  = new URL(request.url);
    const path = url.pathname;

    try {
      if (path === '/health') return ok({ status: 'ok' });
      if (path === '/auth/register' && request.method === 'POST') return register(request, env);
      if (path === '/auth/login'    && request.method === 'POST') return login(request, env);

      // All other routes require a valid token
      const userId = await authenticate(request, env);

      // Bills
      if (path === '/bills') {
        if (request.method === 'GET')  return getBills(userId, env);
        if (request.method === 'POST') return createBill(request, userId, env);
      }
      const billId = matchId(path, '/bills/');
      if (billId) {
        if (request.method === 'PUT')    return updateBill(request, billId, userId, env);
        if (request.method === 'DELETE') return deleteBill(billId, userId, env);
      }

      // IDs
      if (path === '/ids') {
        if (request.method === 'GET')  return getIds(userId, env);
        if (request.method === 'POST') return createId(request, userId, env);
      }
      const docId = matchId(path, '/ids/');
      if (docId) {
        if (request.method === 'PUT')    return updateId(request, docId, userId, env);
        if (request.method === 'DELETE') return deleteId(docId, userId, env);
      }

      // Files
      if (path === '/upload' && request.method === 'POST') return uploadFile(request, userId, env);
      const fileKey = matchPrefix(path, '/files/');
      if (fileKey && request.method === 'GET') return getFile(fileKey, userId, env);

      return err('Not Found', 404);
    } catch (e) {
      if (e.status) return err(e.message, e.status);
      console.error(e);
      return err(e.message || 'Internal Server Error', 500);
    }
  },
};

// ─── ROUTING HELPERS ─────────────────────────────────────────────────────────

function matchId(path, prefix) {
  if (!path.startsWith(prefix)) return null;
  const rest = path.slice(prefix.length);
  return rest && !rest.includes('/') ? rest : null;
}

function matchPrefix(path, prefix) {
  return path.startsWith(prefix) ? path.slice(prefix.length) : null;
}

// ─── RESPONSE HELPERS ────────────────────────────────────────────────────────

function ok(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  });
}

function err(message, status = 400) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  });
}

function httpError(message, status) {
  const e = new Error(message);
  e.status = status;
  return e;
}

// ─── JWT ─────────────────────────────────────────────────────────────────────

function b64url(buf) {
  return btoa(String.fromCharCode(...new Uint8Array(buf)))
    .replace(/=+$/, '').replace(/\+/g, '-').replace(/\//g, '_');
}

function fromb64url(s) {
  return Uint8Array.from(atob(s.replace(/-/g, '+').replace(/_/g, '/')), c => c.charCodeAt(0));
}

async function jwtSign(payload, secret) {
  const enc = new TextEncoder();
  const header = b64url(enc.encode(JSON.stringify({ alg: 'HS256', typ: 'JWT' })));
  const body   = b64url(enc.encode(JSON.stringify(payload)));
  const data   = `${header}.${body}`;
  const key    = await crypto.subtle.importKey('raw', enc.encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const sig    = b64url(await crypto.subtle.sign('HMAC', key, enc.encode(data)));
  return `${data}.${sig}`;
}

async function jwtVerify(token, secret) {
  const parts = token.split('.');
  if (parts.length !== 3) throw httpError('Unauthorized', 401);
  const [header, body, sig] = parts;
  const enc  = new TextEncoder();
  const key  = await crypto.subtle.importKey('raw', enc.encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['verify']);
  const valid = await crypto.subtle.verify('HMAC', key, fromb64url(sig), enc.encode(`${header}.${body}`));
  if (!valid) throw httpError('Unauthorized', 401);
  const payload = JSON.parse(new TextDecoder().decode(fromb64url(body)));
  if (payload.exp && payload.exp < Math.floor(Date.now() / 1000)) throw httpError('Unauthorized', 401);
  return payload;
}

// ─── PASSWORD HASHING (PBKDF2) ───────────────────────────────────────────────

async function hashPassword(password) {
  const salt    = crypto.getRandomValues(new Uint8Array(16));
  const enc     = new TextEncoder();
  const baseKey = await crypto.subtle.importKey('raw', enc.encode(password), 'PBKDF2', false, ['deriveBits']);
  const bits    = await crypto.subtle.deriveBits(
    { name: 'PBKDF2', salt, iterations: 100_000, hash: 'SHA-256' },
    baseKey, 256
  );
  return {
    hash: btoa(String.fromCharCode(...new Uint8Array(bits))),
    salt: btoa(String.fromCharCode(...salt)),
  };
}

async function verifyPassword(password, hashB64, saltB64) {
  const salt    = Uint8Array.from(atob(saltB64), c => c.charCodeAt(0));
  const enc     = new TextEncoder();
  const baseKey = await crypto.subtle.importKey('raw', enc.encode(password), 'PBKDF2', false, ['deriveBits']);
  const bits    = await crypto.subtle.deriveBits(
    { name: 'PBKDF2', salt, iterations: 100_000, hash: 'SHA-256' },
    baseKey, 256
  );
  return btoa(String.fromCharCode(...new Uint8Array(bits))) === hashB64;
}

// ─── AUTH MIDDLEWARE ─────────────────────────────────────────────────────────

async function authenticate(request, env) {
  const auth = request.headers.get('Authorization') || '';
  if (!auth.startsWith('Bearer ')) throw httpError('Unauthorized', 401);
  const payload = await jwtVerify(auth.slice(7), env.JWT_SECRET);
  return payload.sub;
}

// ─── AUTH ROUTES ─────────────────────────────────────────────────────────────

async function register(request, env) {
  const { email, password } = await request.json();
  if (!email || !password) return err('E-posta ve şifre gerekli');
  if (password.length < 6) return err('Şifre en az 6 karakter olmalı');

  const existing = await env.DB.prepare('SELECT id FROM users WHERE email = ?').bind(email.toLowerCase()).first();
  if (existing) return err('Bu e-posta zaten kayıtlı', 409);

  const id = crypto.randomUUID();
  const { hash, salt } = await hashPassword(password);
  await env.DB.prepare('INSERT INTO users (id, email, pass_hash, pass_salt) VALUES (?, ?, ?, ?)')
    .bind(id, email.toLowerCase(), hash, salt).run();

  const token = await jwtSign({ sub: id, email: email.toLowerCase(), exp: Math.floor(Date.now() / 1000) + 60 * 60 * 24 * 30 }, env.JWT_SECRET);
  return ok({ token, user: { email: email.toLowerCase() } }, 201);
}

async function login(request, env) {
  const { email, password } = await request.json();
  if (!email || !password) return err('E-posta ve şifre gerekli');

  const user = await env.DB.prepare('SELECT * FROM users WHERE email = ?').bind(email.toLowerCase()).first();
  if (!user) return err('E-posta veya şifre yanlış', 401);

  const valid = await verifyPassword(password, user.pass_hash, user.pass_salt);
  if (!valid) return err('E-posta veya şifre yanlış', 401);

  const token = await jwtSign({ sub: user.id, email: user.email, exp: Math.floor(Date.now() / 1000) + 60 * 60 * 24 * 30 }, env.JWT_SECRET);
  return ok({ token, user: { email: user.email } });
}

// ─── BILLS ───────────────────────────────────────────────────────────────────

function billRow(row) {
  return { ...row, paid: !!row.paid };
}

async function getBills(userId, env) {
  const { results } = await env.DB.prepare(
    'SELECT * FROM bills WHERE user_id = ? ORDER BY due_date ASC, created_at DESC'
  ).bind(userId).all();
  return ok(results.map(billRow));
}

async function createBill(request, userId, env) {
  const d  = await request.json();
  if (!d.title) return err('Başlık gerekli');
  const id = crypto.randomUUID();
  await env.DB.prepare(
    `INSERT INTO bills (id, user_id, title, category, amount, currency, bill_date, due_date, paid, notes)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
  ).bind(id, userId, d.title, d.category || null, d.amount || 0, d.currency || 'TRY',
         d.bill_date || null, d.due_date || null, d.paid ? 1 : 0, d.notes || null).run();
  const row = await env.DB.prepare('SELECT * FROM bills WHERE id = ?').bind(id).first();
  return ok(billRow(row), 201);
}

async function updateBill(request, id, userId, env) {
  const d = await request.json();
  if (!d.title) return err('Başlık gerekli');
  const res = await env.DB.prepare(
    `UPDATE bills SET title=?, category=?, amount=?, currency=?, bill_date=?, due_date=?, paid=?, notes=?, updated_at=datetime('now')
     WHERE id = ? AND user_id = ?`
  ).bind(d.title, d.category || null, d.amount || 0, d.currency || 'TRY',
         d.bill_date || null, d.due_date || null, d.paid ? 1 : 0, d.notes || null, id, userId).run();
  if (!res.meta.changes) return err('Kayıt bulunamadı', 404);
  const row = await env.DB.prepare('SELECT * FROM bills WHERE id = ?').bind(id).first();
  return ok(billRow(row));
}

async function deleteBill(id, userId, env) {
  const res = await env.DB.prepare('DELETE FROM bills WHERE id = ? AND user_id = ?').bind(id, userId).run();
  if (!res.meta.changes) return err('Kayıt bulunamadı', 404);
  return ok({ deleted: true });
}

// ─── IDS ─────────────────────────────────────────────────────────────────────

async function getIds(userId, env) {
  const { results } = await env.DB.prepare(
    'SELECT * FROM ids WHERE user_id = ? ORDER BY expiry_date ASC, created_at DESC'
  ).bind(userId).all();
  return ok(results);
}

async function createId(request, userId, env) {
  const d  = await request.json();
  if (!d.title) return err('Başlık gerekli');
  const id = crypto.randomUUID();
  await env.DB.prepare(
    `INSERT INTO ids (id, user_id, title, doc_type, doc_number, issuer, issue_date, expiry_date, notes, file_key, file_name, file_type)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
  ).bind(id, userId, d.title, d.doc_type || null, d.doc_number || null, d.issuer || null,
         d.issue_date || null, d.expiry_date || null, d.notes || null,
         d.file_key || null, d.file_name || null, d.file_type || null).run();
  const row = await env.DB.prepare('SELECT * FROM ids WHERE id = ?').bind(id).first();
  return ok(row, 201);
}

async function updateId(request, id, userId, env) {
  const d = await request.json();
  if (!d.title) return err('Başlık gerekli');
  const res = await env.DB.prepare(
    `UPDATE ids SET title=?, doc_type=?, doc_number=?, issuer=?, issue_date=?, expiry_date=?, notes=?,
     file_key=?, file_name=?, file_type=?, updated_at=datetime('now')
     WHERE id = ? AND user_id = ?`
  ).bind(d.title, d.doc_type || null, d.doc_number || null, d.issuer || null,
         d.issue_date || null, d.expiry_date || null, d.notes || null,
         d.file_key || null, d.file_name || null, d.file_type || null, id, userId).run();
  if (!res.meta.changes) return err('Kayıt bulunamadı', 404);
  const row = await env.DB.prepare('SELECT * FROM ids WHERE id = ?').bind(id).first();
  return ok(row);
}

async function deleteId(id, userId, env) {
  const res = await env.DB.prepare('DELETE FROM ids WHERE id = ? AND user_id = ?').bind(id, userId).run();
  if (!res.meta.changes) return err('Kayıt bulunamadı', 404);
  return ok({ deleted: true });
}

// ─── FILE UPLOAD / RETRIEVE ──────────────────────────────────────────────────

async function uploadFile(request, userId, env) {
  if (!env.R2) return err('R2 yapılandırılmamış', 500);
  const formData = await request.formData();
  const file = formData.get('file');
  if (!file) return err('Dosya bulunamadı');

  const key  = `${userId}/${crypto.randomUUID()}-${file.name}`;
  const buf  = await file.arrayBuffer();
  await env.R2.put(key, buf, { httpMetadata: { contentType: file.type } });

  return ok({ key, name: file.name, type: file.type }, 201);
}

async function getFile(key, userId, env) {
  if (!env.R2) return err('R2 yapılandırılmamış', 500);
  // Enforce ownership: key must start with userId/
  if (!key.startsWith(userId + '/')) throw httpError('Unauthorized', 401);

  const obj = await env.R2.get(key);
  if (!obj) return err('Dosya bulunamadı', 404);

  const headers = new Headers(CORS);
  headers.set('Content-Type', obj.httpMetadata?.contentType || 'application/octet-stream');
  headers.set('Content-Disposition', `inline; filename="${key.split('/').pop()}"`);
  return new Response(obj.body, { headers });
}
