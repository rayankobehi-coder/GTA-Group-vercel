// ============================================================
//  Netlify Function — Proxy upload Firebase Storage
//  Route : /api/upload  →  /.netlify/functions/upload
//
//  Pourquoi ? Firebase Storage bloque les requêtes directes
//  depuis un navigateur (CORS). On passe par cette fonction
//  serveur qui n'a pas de restriction CORS.
//
//  Limite : fichiers jusqu'à ~4 Mo (plafond Netlify 6 Mo
//  en tenant compte de l'overhead base64 ~33%)
// ============================================================

const BUCKET = 'gta-group-structure.firebasestorage.app';

exports.handler = async (event) => {
  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'POST uniquement' }),
    };
  }

  // ── Parse le corps JSON ──────────────────────────────────
  let path, contentType, data;
  try {
    ({ path, contentType, data } = JSON.parse(event.body || '{}'));
  } catch {
    return { statusCode: 400, body: JSON.stringify({ error: 'JSON invalide' }) };
  }

  if (!path || !contentType || !data) {
    return {
      statusCode: 400,
      body: JSON.stringify({ error: 'Champs requis : path, contentType, data (base64)' }),
    };
  }

  // ── Convertit base64 → Buffer binaire ────────────────────
  const buffer = Buffer.from(data, 'base64');

  // ── Upload vers Firebase Storage (côté serveur = pas de CORS) ─
  const encoded  = encodeURIComponent(path);
  const endpoint = `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o`
                 + `?uploadType=media&name=${encoded}`;

  try {
    const resp = await fetch(endpoint, {
      method:  'POST',
      headers: { 'Content-Type': contentType },
      body:    buffer,
    });

    const json = await resp.json();

    if (!resp.ok) {
      console.error('[upload.js] Firebase Storage erreur :', JSON.stringify(json));
      return {
        statusCode: 502,
        body: JSON.stringify({ error: json.error?.message || 'Échec de l\'upload' }),
      };
    }

    // URL de téléchargement publique (pas besoin de token avec allow read: if true)
    const token = json.downloadTokens;
    const url   = `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${encoded}?alt=media`
                + (token ? `&token=${token}` : '');

    return {
      statusCode: 200,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ ok: true, url }),
    };

  } catch (err) {
    console.error('[upload.js] Erreur réseau :', err);
    return {
      statusCode: 503,
      body: JSON.stringify({ error: 'Impossible de joindre Firebase Storage' }),
    };
  }
};
