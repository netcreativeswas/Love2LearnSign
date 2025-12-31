# 🔑 Comment mettre la nouvelle clé API Firebase

## Méthode 1 : FlutterFire CLI (Recommandé - Auto-génère le fichier)

### Étape 1 : Installer FlutterFire CLI

```bash
# Installer FlutterFire CLI globalement
dart pub global activate flutterfire_cli
```

**Si ça ne fonctionne pas**, essaie :
```bash
flutter pub global activate flutterfire_cli
```

### Étape 2 : Vérifier que FlutterFire est dans le PATH

```bash
# Ajouter FlutterFire au PATH (macOS/Linux)
export PATH="$PATH":"$HOME/.pub-cache/bin"

# Vérifier que ça fonctionne
flutterfire --version
```

**Note** : Si tu utilises zsh (terminal par défaut sur macOS), ajoute cette ligne à ton fichier `~/.zshrc` :
```bash
echo 'export PATH="$PATH":"$HOME/.pub-cache/bin"' >> ~/.zshrc
source ~/.zshrc
```

### Étape 3 : Se connecter à Firebase

```bash
cd /Users/jl/Love2LearnSign/dashboard
firebase login
```

### Étape 4 : Générer le fichier firebase_options.dart

```bash
cd /Users/jl/Love2LearnSign/dashboard
flutterfire configure
```

**Suis les instructions** :
- Sélectionne le projet Firebase : **"Love2LearnSign"** (ID: `love2learnsign-1914ce`)
- Sélectionne les plateformes que tu veux configurer (Web, Android, iOS, etc.)
- FlutterFire va générer automatiquement `lib/firebase_options.dart` avec ta nouvelle clé API

---

## Méthode 2 : Manuel (Si FlutterFire ne fonctionne pas)

### Étape 1 : Copier le fichier exemple

```bash
cd /Users/jl/Love2LearnSign/dashboard
cp lib/firebase_options.example.dart lib/firebase_options.dart
```

### Étape 2 : Récupérer les valeurs depuis Firebase Console

1. Va sur : https://console.firebase.google.com/
2. Sélectionne le projet **"Love to Learn Sign"**
3. Clique sur l'icône ⚙️ → **"Project settings"**
4. Dans l'onglet **"General"**, descends jusqu'à **"Your apps"**

#### Pour Web :
- Clique sur l'icône **Web** (</>)
- Tu verras la configuration Firebase avec :
  - `apiKey` → Remplace `YOUR_WEB_API_KEY`
  - `authDomain` → Remplace `YOUR_PROJECT.firebaseapp.com`
  - `projectId` → Remplace `YOUR_PROJECT_ID`
  - `storageBucket` → Remplace `YOUR_PROJECT.appspot.com`
  - `messagingSenderId` → Remplace `YOUR_SENDER_ID`
  - `appId` → Remplace `YOUR_WEB_APP_ID`
  - `measurementId` → Remplace `YOUR_MEASUREMENT_ID` (optionnel)

#### Pour Android :
- Clique sur l'icône **Android** (🤖)
- Si tu n'as pas d'app Android, tu peux en créer une (package name : `com.lovetolearnsign.dashboard`)
- Copie les valeurs :
  - `apiKey` → Remplace `YOUR_ANDROID_API_KEY`
  - `appId` → Remplace `YOUR_ANDROID_APP_ID`
  - `messagingSenderId` → Remplace `YOUR_SENDER_ID`
  - `projectId` → Remplace `YOUR_PROJECT_ID`
  - `storageBucket` → Remplace `YOUR_PROJECT.appspot.com`

#### Pour iOS :
- Clique sur l'icône **iOS** (🍎)
- Si tu n'as pas d'app iOS, tu peux en créer une
- Copie les valeurs depuis le fichier `GoogleService-Info.plist` ou depuis la console

### Étape 3 : Éditer le fichier

Ouvre `dashboard/lib/firebase_options.dart` et remplace tous les `YOUR_*` par les vraies valeurs.

---

## Vérification

Après avoir créé le fichier, vérifie que tout fonctionne :

```bash
cd /Users/jl/Love2LearnSign/dashboard
flutter pub get
flutter run
```

Le fichier `firebase_options.dart` est **ignoré par Git** (dans `.gitignore`), donc il ne sera **pas** commité sur GitHub.

---

## ⚠️ Important

- **Ne commit jamais** `firebase_options.dart` dans un repo public
- Le fichier est déjà dans `.gitignore`, donc tu ne peux pas l'ajouter par accident
- Si tu veux vérifier : `git status` ne devrait **pas** montrer `firebase_options.dart`

