# GGStats

Application iOS en SwiftUI pour consulter les statistiques d'un joueur **League of Legends** et **TFT** à partir de son Riot ID, avec une app Apple Watch, un widget et une connexion par compte Firebase.

## Fonctionnalités

### App iPhone
- **Connexion** avec Firebase Authentication : email et mot de passe, compte Google ou Apple (voir [Limites](#limites)). La session reste ouverte entre deux lancements.
- **Recherche d'un joueur** avec son Riot ID (`Pseudo#TAG`) dans la file **SoloQ**, **Flex** ou **TFT**.
- **Profil** : icône, niveau, rang, LP, victoires et défaites, win rate.
- **Top 3 des maîtrises** de champion.
- **5 dernières parties** et win rate (ou taux de Top 4 en TFT). Le détail d'une partie LoL montre les 10 joueurs avec leur KDA.

### App Apple Watch
- Recherche d'un joueur, rang, maîtrises et dernières parties, dans une version adaptée à la montre.

### Widget
- Widget « Compte LoL » : rang, LP et win rate d'un joueur choisi.
- Tailles petite et moyenne sur l'écran d'accueil, rectangulaire et circulaire sur l'écran verrouillé.

## Prérequis

- **Xcode 26** ou plus récent
- iOS 26.2 et watchOS 26.0 minimum
- Un compte Riot pour obtenir une clé API

Les packages Swift (Firebase et GoogleSignIn) sont téléchargés automatiquement par Xcode à la première ouverture.

## Installation

Le fichier de configuration Firebase est fourni dans le dépôt. Seule la clé API Riot est **absente** et doit être ajoutée avant de compiler.

### 1. Clé API Riot → `Partage/Secrets.swift`

1. Va sur [developer.riotgames.com](https://developer.riotgames.com), connecte-toi et copie la **Development API Key**. Si elle a expiré, régénère-la avec « Regenerate API Key ».
2. À la racine du projet, lance :

   ```sh
   ./scripts/changer-cle-api.sh
   ```

   Le script demande la clé (sans l'afficher), vérifie son format, la teste auprès de Riot, puis crée `Partage/Secrets.swift`.

> ⚠️ Une clé de développement **expire au bout de 24 h**. Si l'app affiche « Erreur 401/403 : clé API invalide ou expirée », régénère-la et relance le script.

### 2. Configuration Firebase → `GGStats/GoogleService-Info.plist`

Le fichier `GGStats/GoogleService-Info.plist` est **inclus dans le dépôt** : il pointe vers le projet Firebase de GGStats (Bundle ID **`com.dev.GGStats`**), avec l'authentification email et Google déjà activée. Il n'y a rien à faire.

Ce fichier n'est pas un secret : il identifie l'app auprès de Firebase, et l'accès aux données reste contrôlé par les règles de sécurité Firebase.

**Pour utiliser ton propre projet Firebase** (facultatif) :

1. Dans la [console Firebase](https://console.firebase.google.com), crée un projet et ajoute une app iOS avec le Bundle ID **`com.dev.GGStats`**.
2. Dans **Authentication > Sign-in method**, active **Email/Mot de passe** et **Google**.
3. Télécharge `GoogleService-Info.plist` **après** avoir activé Google, pour qu'il contienne le `CLIENT_ID`, et remplace celui du dossier `GGStats/` en gardant **exactement** ce nom.
4. Remplace l'URL Scheme dans `GGStats/Info.plist` par la valeur `REVERSED_CLIENT_ID` de ton plist. Dans Xcode, c'est dans la cible GGStats, onglet Info, section URL Types.

### 3. Lancer l'app

Ouvre `GGStats.xcodeproj`, choisis le schéma **GGStats** et un simulateur iPhone, puis lance avec **Cmd + R**.

## Tests

Les tests unitaires utilisent **Swift Testing** et un faux serveur Riot : ils ne dépendent ni d'Internet ni de la clé API.

Dans Xcode : **Cmd + U**. En ligne de commande :

```sh
xcodebuild test -project GGStats.xcodeproj -scheme GGStats \
  -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:GGStatsTests
```

Ils couvrent l'analyse du Riot ID, les calculs de statistiques, le service `APIRiot` et le ViewModel du joueur.

## Organisation du projet

```
GGStats/              App iPhone
  GGStatsApp.swift      Point d'entrée, initialisation de Firebase
  Services/             AuthManager (Firebase Auth : email, Google, Apple)
  View/                 Écrans SwiftUI (connexion, accueil, recherche, profil…)
GGStatsWatch/         App Apple Watch
GGStatsWidget/        Widget (écran d'accueil et écran verrouillé)
Partage/              Code commun à l'iPhone, la montre et le widget
  Modeles/              Modèles de données (compte, classement, parties…)
  Services/APIRiot.swift  Appels à l'API Riot et à Data Dragon
  ViewModeles/          JoueurVueModele
  ThemeGG.swift         Couleurs et fond dégradé
GGStatsTests/         Tests unitaires
scripts/              changer-cle-api.sh
```

Le dossier `Partage/` est compilé dans les trois cibles. Le code qui utilise Firebase reste dans `GGStats/`, car seule l'app iPhone en dépend.

## Sources de données

- **API Riot Games** : comptes (Riot ID), profil, classements, maîtrises, historique LoL et TFT.
- **Data Dragon** : noms et images des champions, icônes de profil. La dernière version est récupérée automatiquement.

## Limites

- **Serveur EUW uniquement** : les requêtes sont envoyées aux régions `europe` et `euw1`.
- **Clé API de développement** : elle expire toutes les 24 h et ses limites de requêtes sont basses.
- **Sign in with Apple** : le code est en place (nonce SHA-256, credential Firebase), mais il faut un **compte Apple Developer payant** pour qu'il fonctionne. Sans ce compte, un message d'erreur s'affiche. Pour l'activer :
  1. Ajouter la capability « Sign in with Apple » sur la cible GGStats.
  2. Activer le fournisseur Apple dans Firebase, avec un Service ID et une clé .p8.

---

*GGStats n'est pas affilié à Riot Games. League of Legends et Teamfight Tactics sont des marques de Riot Games, Inc.*
