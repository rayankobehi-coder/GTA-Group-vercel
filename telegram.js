// ============================================================
//  Netlify Function — Proxy Telegram API
//  Route : /api/telegram  →  /.netlify/functions/telegram
//
//  Variables d'environnement à configurer sur Netlify :
//    TELEGRAM_BOT_TOKEN  — token de ton bot (ex: 123456:ABC...)
//    TELEGRAM_CHAT_ID    — ID du chat/groupe/canal destinataire
// ============================================================

exports.handler = async (event) => {
  // ── 1. Méthode HTTP ──────────────────────────────────────
  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Méthode non autorisée (POST uniquement)' }),
    };
  }

  // ── 2. Variables d'environnement ─────────────────────────
  const BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN;
  const CHAT_ID   = process.env.TELEGRAM_CHAT_ID;

  if (!BOT_TOKEN || !CHAT_ID) {
    console.error('[telegram.js] Variables d\'environnement manquantes : TELEGRAM_BOT_TOKEN et/ou TELEGRAM_CHAT_ID');
    return {
      statusCode: 500,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Configuration serveur incomplète. Contactez l\'administrateur.' }),
    };
  }

  // ── 3. Parsing du corps de la requête ────────────────────
  let text, parse_mode;
  try {
    const body = JSON.parse(event.body || '{}');
    text       = body.text;
    parse_mode = body.parse_mode || 'HTML';
  } catch {
    return {
      statusCode: 400,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Corps de requête JSON invalide' }),
    };
  }

  if (!text || typeof text !== 'string' || text.trim() === '') {
    return {
      statusCode: 400,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Le champ "text" est requis et ne peut pas être vide' }),
    };
  }

  // ── 4. Appel à l'API Telegram ────────────────────────────
  try {
    const telegramResponse = await fetch(
      `https://api.telegram.org/bot${BOT_TOKEN}/sendMessage`,
      {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({
          chat_id:    CHAT_ID,
          text:       text.trim(),
          parse_mode: parse_mode,
        }),
      }
    );

    const data = await telegramResponse.json();

    if (!data.ok) {
      console.error('[telegram.js] Telegram a refusé le message :', JSON.stringify(data));
      return {
        statusCode: 502,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ok:          false,
          error:       'Telegram a refusé le message',
          description: data.description || 'Erreur inconnue',
        }),
      };
    }

    // Succès ✅
    return {
      statusCode: 200,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ ok: true }),
    };

  } catch (err) {
    console.error('[telegram.js] Erreur réseau vers Telegram :', err);
    return {
      statusCode: 503,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ ok: false, error: 'Impossible de joindre l\'API Telegram' }),
    };
  }
};
