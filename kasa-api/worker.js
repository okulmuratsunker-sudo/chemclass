// Kasa API — Cloudflare Worker
// Multi-user: JWT auth, per-user data isolation
// Bindings: DB (D1), FILES (R2 optional), JWT_SECRET (secret), API_KEY (secret, optional admin)

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type,Authorization',
  'Access-Control-Max-Age': '86400',
};

const j = (data, status=200) => new Response(JSON.stringify(data), {status, headers:{...CORS,'Content-Type':'application/json'}});
const err = (msg, status=400) => j({error:msg}, status);
const now = () => new Date().toISOString();
const uid = () => crypto.randomUUID();

// ── JWT ──────────────────────────────────────────────────────────────────────

async function signJWT(payload, secret) {
  const enc = new TextEncoder();
  const header = btoa(JSON.stringify({alg:'HS256',typ:'JWT'})).replace(/=/g,'');
  const body = btoa(JSON.stringify(payload)).replace(/=/g,'');
  const msg = `${header}.${body}`;
  const key = await crypto.subtle.importKey('raw', enc.encode(secret), {name:'HMAC',hash:'SHA-256'}, false, ['sign']);
  const sig = await crypto.subtle.sign('HMAC', key, enc.encode(msg));
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig))).replace(/\+/g,'-').replace(/\//g,'_').replace(/=/g,'');
  return `${msg}.${sigB64}`;
}

async function verifyJWT(token, secret) {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    const msg = `${parts[0]}.${parts[1]}`;
    const enc = new TextEncoder();
    const key = await crypto.subtle.importKey('raw', enc.encode(secret), {name:'HMAC',hash:'SHA-256'}, false, ['verify']);
    const sig = Uint8Array.from(atob(parts[2].replace(/-/g,'+').replace(/_/g,'/')), c=>c.charCodeAt(0));
    const valid = await crypto.subtle.verify('HMAC', key, sig, enc.encode(msg));
    if (!valid) return null;
    const payload = JSON.parse(atob(parts[1]+'=='));
    if (payload.exp && payload.exp < Math.floor(Date.now()/1000)) return null;
    return payload;
  } catch { return null; }
}

// ── PASSWORD HASH ────────────────────────────────────────────────────────────

async function hashPassword(password, salt) {
  const enc = new TextEncoder();
  const key = await crypto.subtle.importKey('raw', enc.encode(password), {name:'PBKDF2'}, false, ['deriveBits']);
  const bits = await crypto.subtle.deriveBits({name:'PBKDF2', salt:enc.encode(salt), iterations:100000, hash:'SHA-256'}, key, 256);
  return btoa(String.fromCharCode(...new Uint8Array(bits)));
}

function randomSalt() {
  return btoa(String.fromCharCode(...crypto.getRandomValues(new Uint8Array(16))));
}

// ── AUTH MIDDLEWARE ──────────────────────────────────────────────────────────

async function requireAuth(request, env) {
  const auth = request.headers.get('Authorization') || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : '';
  if (!token) return null;
  return await verifyJWT(token, env.JWT_SECRET);
}

// ── AUTH ROUTES ──────────────────────────────────────────────────────────────

async function register(env, data) {
  const {email, password} = data;
  if (!email || !password) return err('E-posta ve şifre gerekli');
  if (password.length < 6) return err('Şifre en az 6 karakter olmalı');
  const existing = await env.DB.prepare('SELECT id FROM users WHERE email=?').bind(email.toLowerCase()).first();
  if (existing) return err('Bu e-posta zaten kayıtlı');
  const salt = randomSalt();
  const hash = await hashPassword(password, salt);
  const id = uid();
  await env.DB.prepare('INSERT INTO users (id,email,password_hash,salt) VALUES (?,?,?,?)').bind(id, email.toLowerCase(), hash, salt).run();
  const token = await signJWT({sub:id, email:email.toLowerCase(), exp:Math.floor(Date.now()/1000)+60*60*24*30}, env.JWT_SECRET);
  return j({token, user:{id, email:email.toLowerCase()}}, 201);
}

async function login(env, data) {
  const {email, password} = data;
  if (!email || !password) return err('E-posta ve şifre gerekli');
  const user = await env.DB.prepare('SELECT * FROM users WHERE email=?').bind(email.toLowerCase()).first();
  if (!user) return err('E-posta veya şifre hatalı', 401);
  const hash = await hashPassword(password, user.salt);
  if (hash !== user.password_hash) return err('E-posta veya şifre hatalı', 401);
  const token = await signJWT({sub:user.id, email:user.email, exp:Math.floor(Date.now()/1000)+60*60*24*30}, env.JWT_SECRET);
  return j({token, user:{id:user.id, email:user.email}});
}

// ── BILLS ────────────────────────────────────────────────────────────────────

async function listBills(env, userId) {
  const {results} = await env.DB.prepare('SELECT * FROM bills WHERE user_id=? ORDER BY due_date ASC, created_at DESC').bind(userId).all();
  return j(results);
}

async function createBill(env, userId, data) {
  const id = uid(); const ts = now();
  const {title='', category='Diğer', amount=0, currency='TRY', bill_date=null, due_date=null, paid=0, notes='', file_key=null, file_name=null, file_type=null} = data;
  await env.DB.prepare('INSERT INTO bills (id,user_id,title,category,amount,currency,bill_date,due_date,paid,notes,file_key,file_name,file_type,created_at,updated_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)')
    .bind(id,userId,title,category,amount,currency,bill_date,due_date,paid?1:0,notes,file_key,file_name,file_type,ts,ts).run();
  return j(await env.DB.prepare('SELECT * FROM bills WHERE id=?').bind(id).first(), 201);
}

async function updateBill(env, userId, id, data) {
  const existing = await env.DB.prepare('SELECT * FROM bills WHERE id=? AND user_id=?').bind(id, userId).first();
  if (!existing) return err('Fatura bulunamadı', 404);
  const {title=existing.title, category=existing.category, amount=existing.amount, currency=existing.currency, bill_date=existing.bill_date, due_date=existing.due_date, paid=existing.paid, notes=existing.notes, file_key=existing.file_key, file_name=existing.file_name, file_type=existing.file_type} = data;
  const ts = now();
  await env.DB.prepare('UPDATE bills SET title=?,category=?,amount=?,currency=?,bill_date=?,due_date=?,paid=?,notes=?,file_key=?,file_name=?,file_type=?,updated_at=? WHERE id=? AND user_id=?')
    .bind(title,category,amount,currency,bill_date,due_date,paid?1:0,notes,file_key,file_name,file_type,ts,id,userId).run();
  return j(await env.DB.prepare('SELECT * FROM bills WHERE id=?').bind(id).first());
}

async function deleteBill(env, userId, id) {
  const row = await env.DB.prepare('SELECT * FROM bills WHERE id=? AND user_id=?').bind(id, userId).first();
  if (!row) return err('Fatura bulunamadı', 404);
  if (row.file_key && env.FILES) { try { await env.FILES.delete(row.file_key); } catch {} }
  await env.DB.prepare('DELETE FROM bills WHERE id=? AND user_id=?').bind(id, userId).run();
  return j({deleted:true});
}

// ── IDENTITIES ───────────────────────────────────────────────────────────────

async function listIds(env, userId) {
  const {results} = await env.DB.prepare('SELECT * FROM identities WHERE user_id=? ORDER BY expiry_date ASC, created_at DESC').bind(userId).all();
  return j(results);
}

async function createId(env, userId, data) {
  const id = uid(); const ts = now();
  const {title='', doc_type='Kimlik', doc_number='', issuer='', issue_date=null, expiry_date=null, notes='', file_key=null, file_name=null, file_type=null} = data;
  await env.DB.prepare('INSERT INTO identities (id,user_id,title,doc_type,doc_number,issuer,issue_date,expiry_date,notes,file_key,file_name,file_type,created_at,updated_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)')
    .bind(id,userId,title,doc_type,doc_number,issuer,issue_date,expiry_date,notes,file_key,file_name,file_type,ts,ts).run();
  return j(await env.DB.prepare('SELECT * FROM identities WHERE id=?').bind(id).first(), 201);
}

async function updateId(env, userId, id, data) {
  const existing = await env.DB.prepare('SELECT * FROM identities WHERE id=? AND user_id=?').bind(id, userId).first();
  if (!existing) return err('Kimlik bulunamadı', 404);
  const {title=existing.title, doc_type=existing.doc_type, doc_number=existing.doc_number, issuer=existing.issuer, issue_date=existing.issue_date, expiry_date=existing.expiry_date, notes=existing.notes, file_key=existing.file_key, file_name=existing.file_name, file_type=existing.file_type} = data;
  const ts = now();
  await env.DB.prepare('UPDATE identities SET title=?,doc_type=?,doc_number=?,issuer=?,issue_date=?,expiry_date=?,notes=?,file_key=?,file_name=?,file_type=?,updated_at=? WHERE id=? AND user_id=?')
    .bind(title,doc_type,doc_number,issuer,issue_date,expiry_date,notes,file_key,file_name,file_type,ts,id,userId).run();
  return j(await env.DB.prepare('SELECT * FROM identities WHERE id=?').bind(id).first());
}

async function deleteId(env, userId, id) {
  const row = await env.DB.prepare('SELECT * FROM identities WHERE id=? AND user_id=?').bind(id, userId).first();
  if (!row) return err('Kimlik bulunamadı', 404);
  if (row.file_key && env.FILES) { try { await env.FILES.delete(row.file_key); } catch {} }
  await env.DB.prepare('DELETE FROM identities WHERE id=? AND user_id=?').bind(id, userId).run();
  return j({deleted:true});
}

// ── FILES ────────────────────────────────────────────────────────────────────

async function uploadFile(request, env) {
  if (!env.FILES) return err('Dosya depolama henüz aktif değil', 503);
  let form; try { form = await request.formData(); } catch { return err('Geçersiz form'); }
  const file = form.get('file');
  if (!file || typeof file === 'string') return err('Dosya bulunamadı');
  const key = `${uid()}-${file.name.replace(/[^a-zA-Z0-9._-]/g,'_')}`;
  await env.FILES.put(key, await file.arrayBuffer(), {httpMetadata:{contentType:file.type||'application/octet-stream'}, customMetadata:{originalName:file.name}});
  return j({key, name:file.name, type:file.type}, 201);
}

async function serveFile(env, key) {
  if (!env.FILES) return err('Dosya depolama henüz aktif değil', 503);
  const obj = await env.FILES.get(key);
  if (!obj) return err('Dosya bulunamadı', 404);
  return new Response(obj.body, {headers:{...CORS,'Content-Type':obj.httpMetadata?.contentType||'application/octet-stream','Cache-Control':'private,max-age=3600'}});
}

async function deleteFile(env, key) {
  if (!env.FILES) return err('Dosya depolama henüz aktif değil', 503);
  try { await env.FILES.delete(key); } catch { return err('Silinemedi', 500); }
  return j({deleted:true});
}

// ── ROUTER ───────────────────────────────────────────────────────────────────

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') return new Response(null, {status:204, headers:CORS});

    const url = new URL(request.url);
    const path = url.pathname.replace(/\/$/, '') || '/';
    const method = request.method;

    // Parse body
    let body = {};
    if (['POST','PUT'].includes(method) && !path.startsWith('/upload')) {
      try { const t = await request.text(); body = t ? JSON.parse(t) : {}; } catch { return err('Geçersiz JSON'); }
    }

    try {
      // ── Public auth routes ──
      if (path === '/auth/register' && method === 'POST') return register(env, body);
      if (path === '/auth/login'    && method === 'POST') return login(env, body);
      if (path === '/health'        && method === 'GET')  return j({status:'ok', ts:now()});

      // ── Protected routes ──
      const user = await requireAuth(request, env);
      if (!user) return err('Giriş yapınız', 401);
      const userId = user.sub;

      // Me
      if (path === '/auth/me' && method === 'GET') return j({id:userId, email:user.email});

      // Bills
      if (path === '/bills') {
        if (method === 'GET')  return listBills(env, userId);
        if (method === 'POST') return createBill(env, userId, body);
      }
      const bm = path.match(/^\/bills\/([^/]+)$/);
      if (bm) {
        if (method === 'PUT')    return updateBill(env, userId, bm[1], body);
        if (method === 'DELETE') return deleteBill(env, userId, bm[1]);
      }

      // IDs
      if (path === '/ids') {
        if (method === 'GET')  return listIds(env, userId);
        if (method === 'POST') return createId(env, userId, body);
      }
      const im = path.match(/^\/ids\/([^/]+)$/);
      if (im) {
        if (method === 'PUT')    return updateId(env, userId, im[1], body);
        if (method === 'DELETE') return deleteId(env, userId, im[1]);
      }

      // Files
      if (path === '/upload' && method === 'POST') return uploadFile(request, env);
      const fm = path.match(/^\/files\/(.+)$/);
      if (fm) {
        if (method === 'GET')    return serveFile(env, fm[1]);
        if (method === 'DELETE') return deleteFile(env, fm[1]);
      }

      return err('Bulunamadı', 404);
    } catch(e) {
      console.error(e);
      return err('Sunucu hatası: '+e.message, 500);
    }
  }
};
