// ============================================================
//  firebase-sync.js — Synchronisation cloud GTA  v4
//  - Realtime DB  : données texte (utilisateurs, paramètres…)
//  - Netlify /api/upload : fichiers → Firebase Storage (sans CORS)
//  - Compression avatar automatique (600px max)
// ============================================================

const GTA_FIREBASE_URL = 'https://gta-group-structure-default-rtdb.europe-west1.firebasedatabase.app/gta';

// ── Sanitize clés Firebase (interdit : . $ # [ ] /) ─────────
function _fkey(key) { return key.replace(/[.$#[\]/]/g, '_'); }

// ────────────────────────────────────────────────────────────
//  PULL — Firebase Realtime DB → localStorage (au démarrage)
// ────────────────────────────────────────────────────────────
async function pullFromCloud() {
    try {
        const resp = await fetch(`${GTA_FIREBASE_URL}.json`);
        if (!resp.ok) return;
        const data = await resp.json();
        if (!data || typeof data !== 'object') return;
        Object.entries(data).forEach(([key, value]) => {
            if (value !== null && value !== undefined)
                localStorage.setItem(key, JSON.stringify(value));
        });
        console.log('[GTA Sync] ✅ Données synchronisées depuis le cloud.');
    } catch (e) {
        console.warn('[GTA Sync] ⚠️ Firebase inaccessible — données locales utilisées.', e.message);
    }
}

// ────────────────────────────────────────────────────────────
//  PUSH — données → Firebase Realtime DB (à chaque save)
//  Les dataURL/URL de fichiers ne sont pas stockés en DB.
// ────────────────────────────────────────────────────────────
function pushToCloud(key, data) {
    let payload = data;

    // Documents : ne stocker que les métadonnées (pas les dataURL)
    if (key === 'gta_docs' && Array.isArray(data)) {
        payload = data.map(({ dataURL, ...rest }) => rest);
    }
    // Profils : ne pas stocker les avatars base64 en DB
    if (payload && typeof payload === 'object' && !Array.isArray(payload) &&
        typeof payload.avatarData === 'string' && payload.avatarData.startsWith('data:')) {
        payload = { ...payload, avatarData: null };
    }

    fetch(`${GTA_FIREBASE_URL}/${_fkey(key)}.json`, {
        method:  'PUT',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify(payload),
    }).catch(e => console.warn('[GTA Sync] Push DB error:', e.message));
}

// ────────────────────────────────────────────────────────────
//  UPLOAD — Fichier → /api/upload (Netlify Function → Firebase Storage)
//  Pas de CORS car l'appel passe par Netlify côté serveur.
//  Retourne l'URL publique de téléchargement.
// ────────────────────────────────────────────────────────────
async function uploadFile(storagePath, fileOrBlob, contentType) {
    // 1. Convertir fichier en base64
    const base64 = await new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onerror = reject;
        reader.onload = (ev) => resolve(ev.target.result.split(',')[1]);
        reader.readAsDataURL(fileOrBlob);
    });

    // 2. Envoyer au proxy Netlify
    const resp = await fetch('/api/upload', {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({ path: storagePath, contentType, data: base64 }),
    });

    const json = await resp.json();
    if (!resp.ok || !json.ok) throw new Error(json.error || 'Échec upload');
    return json.url;
}

// ────────────────────────────────────────────────────────────
//  COMPRESSION IMAGE — réduit les photos de profil
//  Max 600×600px, JPEG 82% → ~30-60 Ko quelle que soit la taille
// ────────────────────────────────────────────────────────────
function compressImage(file, maxDim = 600, quality = 0.82) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onerror = reject;
        reader.onload = (ev) => {
            const img = new Image();
            img.onerror = reject;
            img.onload = () => {
                const scale  = Math.min(1, maxDim / Math.max(img.width, img.height));
                const canvas = document.createElement('canvas');
                canvas.width  = Math.round(img.width  * scale);
                canvas.height = Math.round(img.height * scale);
                canvas.getContext('2d').drawImage(img, 0, 0, canvas.width, canvas.height);
                canvas.toBlob(
                    blob => blob ? resolve(blob) : reject(new Error('Compression échouée')),
                    'image/jpeg', quality
                );
            };
            img.src = ev.target.result;
        };
        reader.readAsDataURL(file);
    });
}

// ── API publique ─────────────────────────────────────────────
window.gtaSync = { pullFromCloud, pushToCloud, uploadFile, compressImage };
