# 📋 Guide de déploiement — Groupe GTA sur Netlify

---

## PROBLÈME RÉSOLU — Synchronisation entre appareils

**Avant :** Les données étaient stockées dans `localStorage` (mémoire du navigateur).
Chaque appareil avait ses propres données → pas de partage possible.

**Après :** Toutes les données sont stockées dans **Firebase** (base de données en ligne).
Tous les appareils lisent et écrivent au même endroit.

---

## ÉTAPE 1 — Créer une base Firebase (gratuit)

1. Va sur **https://console.firebase.google.com**
2. Clique **"Ajouter un projet"**
3. Nomme-le `groupe-gta` → clique **Continuer** (désactive Google Analytics) → **Créer**
4. Dans le menu gauche : **"Realtime Database"** → **"Créer une base de données"**
5. Choisis la région **"europe-west1 (Belgium)"** → **Suivant**
6. Sélectionne **"Commencer en mode test"** → **Activer**
7. Copie l'URL affichée — elle ressemble à :
   ```
   https://groupe-gta-default-rtdb.europe-west1.firebasedatabase.app
   ```

---

## ÉTAPE 2 — Configurer le fichier firebase-sync.js

Ouvre le fichier `js/firebase-sync.js` et remplace la ligne :

```javascript
const GTA_FIREBASE_URL = 'https://gta-group-structure-default-rtdb.europe-west1.firebasedatabase.app/gta';
```

Par ton URL **+ `/gta`** à la fin :

```javascript
const GTA_FIREBASE_URL = 'https://groupe-gta-default-rtdb.europe-west1.firebasedatabase.app/gta';
```

---

## ÉTAPE 3 — Variables d'environnement Netlify

Va sur **app.netlify.com** → ton site → **Site Settings** → **Environment Variables** :

| Key                  | Value                                                      |
|----------------------|------------------------------------------------------------|
| `TELEGRAM_BOT_TOKEN` | `8672835698:AAE5XG2wSh8DSTWAc32ncYhf-WR-eMJ_yNk`        |
| `TELEGRAM_CHAT_ID`   | `8714500858`                                               |

---

## ÉTAPE 4 — Déployer le ZIP sur Netlify

1. Va sur **app.netlify.com** → ton site → **Deploys**
2. Fais glisser le dossier ou le ZIP dans la zone de dépôt
3. Attends que le déploiement se termine (~30 secondes)

---

## Vérification

1. Ouvre le site sur ton **téléphone** → connecte-toi → modifie quelque chose
2. Ouvre le même lien sur ton **ordinateur** → l'information doit être visible

---

## Structure des fichiers modifiés

```
GTA_web_FINAL/
├── netlify.toml                    ← Config Netlify (Functions + redirects)
├── netlify/functions/telegram.js   ← Proxy Telegram (token sécurisé)
├── js/firebase-sync.js             ← Synchronisation cloud ← NOUVEAU
├── index.html
└── page/
    ├── CEEJAY.html    ← modifié (sync Firebase + proxy Telegram)
    ├── prof.html      ← modifié (sync Firebase)
    ├── eleve.html     ← modifié (sync Firebase + proxy Telegram)
    ├── lepere.html    ← modifié (sync Firebase)
    └── accueil.html   ← modifié (proxy Telegram)
```

---

## En cas de problème

| Symptôme | Cause | Solution |
|----------|-------|----------|
| Données non partagées | URL Firebase non configurée | Vérifier js/firebase-sync.js |
| Erreur 401 Firebase | Règles de sécurité trop strictes | Remettre le mode "test" dans Firebase |
| Telegram ne fonctionne pas | Variables Netlify manquantes | Vérifier ÉTAPE 3 |
