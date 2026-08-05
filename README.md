# La Tournée iOS

[![version](https://img.shields.io/badge/version-0.15.1-D4A437?style=flat-square)](CHANGELOG.md)
[![CI](https://img.shields.io/github/actions/workflow/status/Adam-Blf/la-tournee-ios/ci.yml?branch=main&style=flat-square&label=CI)](https://github.com/Adam-Blf/la-tournee-ios/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/actions/workflow/status/Adam-Blf/la-tournee-ios/release.yml?label=release&style=flat-square)](RELEASING.md)
[![platform](https://img.shields.io/badge/platform-iOS%2017%2B-001329?style=flat-square)](project.yml)
[![license](https://img.shields.io/badge/license-proprietary-D4A437?style=flat-square)](LICENSE)

App iOS native de La Tournée, jeu de cartes et de défis pour soirées entre
adultes (dépôt GitHub `la-tournee-ios`, renommé en conséquence - voir
CHANGELOG 0.15.0). Direction artistique néobrutalisme
taverne, thèmes clair et sombre : papier crème ou encre neutre (jamais de
brun/bois), accent orange, ombres dures noires, carte blanche géante comme
élément signature. Bascule clair/sombre/système persistée, discrète dans
le Hub. L'univers taverne est conservé intact : le jeu de cartes s'appelle
toujours Le Coupe-Gorge, "Le Taulier" reste Le Taulier, etc.

Développé sur Windows. Aucun compilateur Swift local n'est disponible sur
cette machine : le projet Xcode est **généré par XcodeGen** depuis
`project.yml`, et **compilé et testé par la CI GitHub Actions** sur runner
`macos-15`. Toute contribution doit passer par une Pull Request pour être
validée par la CI avant merge.

## Stack

- Swift 5.10, SwiftUI, iOS 17+
- XcodeGen (`project.yml`) pour générer `LaTournee.xcodeproj`
- XCTest pour la couverture du moteur de jeu
- GitHub Actions (`macos-15`) pour build + tests, plus un job `secrets`
  (gitleaks, historique complet) sur chaque push et chaque PR
- RevenueCat (`purchases-ios` 5.83.0) pour le billing, PostHog
  (`posthog-ios` 3.69.0) pour l'analytics, les deux gated par clé de
  configuration (voir Monétisation)

## Démarrage (sur une machine macOS avec Xcode)

```bash
brew install xcodegen
xcodegen generate
open LaTournee.xcodeproj
```

En local, `brew install xcodegen` suffit. En CI, XcodeGen est installé depuis
l'archive de release **2.46.0**, checksum SHA-256 vérifié avant extraction :
le build doit être reproductible et ne pas dépendre de la version du jour
d'une formule Homebrew.

Pour resynchroniser les packs de contenu depuis `la-taverne-content` (dépôt
frère, chemin relatif `../la-taverne-content`) :

```bash
python scripts/sync_content.py
```

Pour régénérer l'icône App Store 1024x1024 :

```bash
python scripts/gen_app_icon.py
```

## Architecture

```mermaid
flowchart TD
    subgraph Core["LaTourneeCore (framework, logique pure, zéro dépendance UI)"]
        Deck["Deck / Card / Rank / Suit"]
        Player["Player / PlayerRotation (gender + relationship optionnels, locaux)"]
        Targeting["Targeting (gender-m/f, pair, single, couple - RNG injectable)"]
        Penalty["PenaltyCalculator / ContestState"]
        Engine["BorderlandEngine"]
        Content["ContentPack (Codable) / ContentLibrary"]
        Prompt["PromptSession (tirage, règles persistantes, interpolation)"]
        TribunalSession["TribunalSession (moteur pur : accusations, pickAccused, verdicts)"]
        AuctionContent["AuctionContent (50 thèmes, pickTheme sans répétition)"]
        QuizSession["QuizSession (moteur pur : cagnotte, choice cumuler/distribuer)"]
        RankingSession["RankingSession (moteur pur : podium secret, guessQuestion)"]
        WouldYouRatherSession["WouldYouRatherSession (moteur pur : vote A/B, minorité pénalisée)"]
        ThemePalette["ThemePalette (hex bruts clair/sombre, source unique - miroir tokens.css)"]
    end

    subgraph App["La Tournée (SwiftUI app)"]
        Theme["Theme (SwiftUI Color depuis ThemePalette, polices)"]
        Welcome["WelcomeView (check-in joueurs + genre/statut facultatifs)"]
        Hub["HubView (grille des modes)"]
        Borderland["BorderlandView (Le Coupe-Gorge : carte, flip, contest)"]
        PromptView["PromptView (générique multi-modes)"]
        Roulette["RouletteView (La Roue du Destin, embarqué)"]
        TribunalView["TribunalView (Le Pilori, embarqué, récap local)"]
        AuctionView["AuctionView (La Criée, embarqué, chrono 60s)"]
        QuizView["QuizView (Quitte ou Trinque, embarqué, récap local)"]
        RankingView["RankingView (Le Tableau d'Honneur, embarqué, récap local)"]
        WouldYouRatherView["WouldYouRatherView (Tu préfères, embarqué, récap local)"]
        Recap["RecapView (podium)"]
        Paywall["PaywallView (3 offres, achat + restauration)"]
        Settings["SettingsView (apparence, premium, confidentialité, légal, réinitialisation)"]
        Billing["Billing: EntitlementProviding (RevenueCatEntitlements si clé, sinon StubEntitlements)"]
        Analytics["Analytics: AnalyticsProviding (PostHogAnalytics si clé + consentement, sinon StubAnalytics)"]
    end

    subgraph Resources["Resources"]
        Packs["Packs/*.json (packs gratuits embarqués)"]
        Catalog["premium-catalog.json (métadonnées, packs premium non embarqués)"]
        Fonts["Fonts/*.ttf (Anton, Space Grotesk, Space Mono)"]
    end

    Welcome --> Hub --> Borderland
    Hub --> PromptView
    Hub --> Roulette
    Hub --> TribunalView
    Hub --> AuctionView
    Hub --> QuizView
    Hub --> RankingView
    Hub --> WouldYouRatherView
    Borderland --> Recap
    PromptView --> Recap
    Engine --> Deck
    Engine --> Player
    Engine --> Penalty
    Prompt --> Content
    PromptView -.resolves via.-> Targeting
    Targeting --> Player
    TribunalSession --> Player
    TribunalSession -.mirrors.-> Prompt
    QuizSession --> Player
    RankingSession --> Player
    WouldYouRatherSession --> Player
    Borderland -.uses.-> Engine
    PromptView -.uses.-> Prompt
    TribunalView -.uses.-> TribunalSession
    AuctionView -.uses.-> AuctionContent
    QuizView -.uses.-> QuizSession
    RankingView -.uses.-> RankingSession
    WouldYouRatherView -.uses.-> WouldYouRatherSession
    App -.embeds.-> Core
    App -.loads.-> Resources
    Theme -.builds Color from.-> ThemePalette
    Hub -.gates premium.-> Billing
    Hub --> Paywall
    Hub --> Settings
    Paywall -.purchase/restore.-> Billing
    Paywall -.paywall_shown/dismissed/purchase_*.-> Analytics
    Settings -.premium status/restore.-> Billing
    Settings -.consent toggle.-> Analytics
    Settings --> Paywall
```

## Contenu

Les packs de contenu (Action ou Vérité, Picolo, etc.) sont maintenus dans le
dépôt frère `la-taverne-content` et synchronisés ici via
`scripts/sync_content.py` :

`Tu préfères` n'est plus un pack de prompt : depuis la v0.9.0 c'est un mode
embarqué à mécanique de vote (`WouldYouRatherSession.swift`,
`WouldYouRatherContent.swift`, `WouldYouRatherView.swift`), au même titre que
Quitte ou Trinque ou Le Tableau d'Honneur. Le pack `tu-preferes-classique`
de `la-taverne-content` reste à retirer côté dépôt frère lors du prochain
`sync_content.py` pour éviter qu'il ne réapparaisse dans le catalogue.

- **Packs gratuits** (`premium=false`) : copiés intégralement dans
  `LaTournee/Resources/Packs/`, embarqués dans le binaire.
- **Packs premium** : seules les métadonnées (titre, mode, intensité)
  vivent dans `LaTournee/Resources/premium-catalog.json`, pour afficher les
  cartes verrouillées du Hub. Le contenu réel n'est jamais livré tant que
  le billing n'est pas branché (zéro spoiler dans le binaire gratuit).

## Thème clair/sombre

`Theme.Color` est entièrement dynamique : chaque token résout vers sa paire
clair/sombre via un `UIColor` calculé au trait collection courant (voir
`Theme.dynamic(light:dark:)`), construit depuis `LaTourneeCore.ThemePalette`
(source unique de hex bruts, miroir de `la-taverne/src/styles/tokens.css`),
donc aucun écran n'a besoin de connaître le thème actif. La préférence
(`ThemeMode` : système / clair / sombre) vit dans `AppState.themeMode`,
persistée (`UserDefaults`), appliquée via `.preferredColorScheme` sur la
`WindowGroup`. Bascule discrète dans le Hub (icône soleil/lune, à côté de
Récap). Le sombre reste sur une encre neutre (`#141216`/`#2E2836`), jamais
teintée bois/brun.

**Encre fixe sur fonds clairs (`tileInk`/`cardInk`)** : les aplats "pop"
(tuiles de modes, roulette) et l'accent `neon`/`neonDeep`/`neonSoft`
restent clairs dans les deux thèmes - tout texte/icône posé dessus utilise
`Theme.Color.tileInk` (`#111111`, jamais thématisé), jamais `Theme.Color.ink`
(qui s'inverse en sombre et y deviendrait illisible, cf. CHANGELOG 0.14.1).
Même logique pour `cardInk` sur `cardFace` (carte blanche fixe). Un rouge
d'UI sémantique (erreur, action destructive, compte à rebours) utilise
`Theme.Color.danger` (thémable), jamais `cardRed` (fixe, réservé aux pips
de carte). Vérifié mécaniquement en CI par
`LaTourneeTests/ContrastGuardTests.swift`, qui calcule le ratio WCAG 2.1 réel
de chaque paire encre/fond dérivée de `ThemePalette`.

## Genre et statut relationnel des joueurs (facultatif)

Chaque joueur peut déclarer sur `WelcomeView`, dans un panneau replié par
défaut (icône réglages à côté de son nom) : un genre (Homme / Femme / Autre)
et/ou un statut relationnel (Célibataire / En couple). Les deux champs
restent optionnels et ne bloquent jamais la partie.

- **Stockage** : `Player.gender` / `Player.relationship`
  (`LaTourneeCore/Player.swift`), 100 % local (`UserDefaults` via
  `AppState.playerAttributes`), **jamais envoyés en analytics** (aucun call
  site de `AnalyticsProviding.track` ne référence ces champs).
- **Ciblage de contenu** : `LaTourneeCore/Targeting.swift` résout
  `PromptTarget.genderMasculine/.genderFeminine/.single/.couple/.pair` vers
  un ou deux joueurs concrets, RNG injectable et seedable par tour
  (`Targeting.seededRng`) pour rester stable entre deux re-rendus du même
  tour. Si personne à table n'a déclaré l'attribut demandé, repli gracieux
  sur un joueur actif tiré au hasard - la partie ne bloque jamais. Affiché
  sur `PromptView` sous forme de bannière "C'est à … de jouer", à parité
  avec `la-taverne/src/components/screens/PromptGameScreen.tsx`.

## Conformité App Store

- **Âge** : 17+, contenu réservé aux adultes, aucune référence à l'alcool
  (guideline 1.4.3). Wording store-safe : "pénalité" / "PÉNALITÉ MAJEURE",
  jamais de gorgée, shot ou alcool nommés. Mention "Jouez responsable."
  affichée sur l'écran d'accueil.
- **Achats in-app** (guideline 3.1.1) : billing réel via RevenueCat (voir
  section Monétisation), gated par clé de configuration absente par
  défaut. Sans clé (CI, clone frais), `StubEntitlements` renvoie
  `isPremium = false`, chaque pack premium reste visuellement verrouillé,
  et le bouton d'achat du paywall affiche "Bientôt disponible" au lieu
  d'un checkout cassé.
- **Suppression de compte** : l'app ne crée aucun compte serveur en v0.1
  (pas d'auth, pas de backend). RevenueCat identifie l'utilisateur par un
  identifiant anonyme géré par le SDK, pas de compte à supprimer. Si un
  compte serveur est introduit plus tard, une fonctionnalité de
  suppression de compte devra être ajoutée avant soumission (guideline 5.1.1v).
- **Vie privée** : `Analytics/AnalyticsProviding` est désactivée par défaut
  (`isEnabled = false`), aucune télémétrie n'est envoyée sans consentement
  explicite, même quand une clé PostHog est configurée. Le consentement se
  pilote depuis `SettingsView` (interrupteur "Mesure d'audience", section
  Confidentialité) - `AppState.analyticsConsent`, persisté, jamais
  pré-coché, répercuté sur `analytics.isEnabled` (v0.13.0). Aucune donnée
  personnelle collectée en v0.1 (les noms de joueurs, ainsi que le genre et
  le statut relationnel optionnels déclarés depuis la v0.12.0, restent en
  local, `UserDefaults`, jamais transmis).
- **Polices et assets** : entièrement embarqués (`Resources/Fonts/`,
  `Assets.xcassets`), aucune dépendance CDN, fonctionne hors ligne.

## Monétisation

Billing (RevenueCat) et analytics (PostHog) sont **gated par configuration** :
sans clé, l'app tourne entièrement en mode invité, jamais de crash.

- **Entitlement** : `La Tournee Pro` (sans accent, id exact du dashboard
  RevenueCat), identique au web (`la-taverne/src/lib/billing.ts`) et à
  l'Android. Renommé au renommage produit v0.15.0 (Meskova -> La Tournée) -
  l'app n'étant pas encore publiée, aucun abonné existant à migrer.
- **Produits** : `premium_monthly` (4,99 €), `premium_yearly` (19,99 €),
  `premium_lifetime` (34,99 €, mis en avant comme meilleure offre),
  offering `default`. Le catalogue de plans et les prix de repli vivent
  dans `LaTourneeCore/PremiumPlan.swift` (pur, testé).
- **Sélection du provider** : `EntitlementsFactory.make()` /
  `AnalyticsFactory.make()` lisent `REVENUECAT_API_KEY` /
  `POSTHOG_API_KEY` dans l'Info.plist (interpolées depuis
  `LaTournee/Config/Config.xcconfig` + `Config.local.xcconfig`, gitignored).
  Clé absente → `StubEntitlements` / `StubAnalytics`, comportement
  identique à avant cette version.
- **Configuration locale** : copier
  `LaTournee/Config/Config.local.xcconfig.example` vers
  `LaTournee/Config/Config.local.xcconfig` (jamais commité) et renseigner
  les clés RevenueCat/PostHog réelles.
- **Paywall** : `Screens/PaywallView.swift`, accessible depuis le bouton
  "Premium" du Hub et depuis tout pack premium verrouillé. Affiche
  toujours les 3 prix annoncés (prix de repli si les offerings
  RevenueCat ne sont pas encore chargés), aucun essai gratuit annoncé,
  bouton d'achat désactivé tant qu'aucun package réel n'est disponible.
- **Analytics** : PostHog EU (`https://eu.i.posthog.com`), autocapture et
  écrans désactivés, uniquement les événements explicites déjà en place
  (`session_completed`, etc.) plus `paywall_shown`, `paywall_dismissed`,
  `purchase_started`, `purchase_completed`, `restore_completed`. Capture
  coupée tant que `isEnabled` n'est pas activé, via l'interrupteur de
  consentement de `SettingsView` (section Confidentialité).
- **Réglages** : `Screens/SettingsView.swift`, accessible depuis l'icône
  engrenage du Hub. Apparence (thème système/clair/sombre), statut premium
  + accès au paywall + restauration des achats, consentement analytics,
  lien vers la politique de confidentialité et les mentions légales/CGU
  (renvoie vers `lataverne.beloucif.com`, ces textes n'ont pas encore
  d'écran natif ni de route URL dédiée côté web), à propos (version,
  éditeur), réinitialisation de la tablée (joueurs + partie en cours,
  jamais le statut premium).

## Ce qu'il reste pour TestFlight

1. **Compte Apple Developer Program** (99 $/an) rattaché à l'identité
   d'Adam Beloucif ou à une entité, condition préalable à toute soumission.
2. **App Store Connect** : créer l'app (bundle id `com.beloucif.latournee`),
   remplir fiche (description, mots-clés, captures d'écran, catégorie
   Jeux/Divertissement, classification d'âge 17+).
3. **Signing** : générer un certificat de distribution + provisioning
   profile App Store, ou déléguer à `fastlane match` (recommandé, gère la
   rotation et le partage d'équipe). Non inclus dans ce dépôt v0.1 (aucun
   secret de signature commité, cf. `.gitignore`).
4. **Fastlane** (à ajouter) : `fastlane/Fastfile` avec une lane `beta` qui
   build en Release, signe via `match`, et pousse vers TestFlight
   (`pilot upload`). La CI actuelle ne fait que build + test, pas de
   déploiement.
5. **Secrets CI** : si l'upload TestFlight est automatisé, stocker
   `APP_STORE_CONNECT_API_KEY` (clé API App Store Connect, format JSON/P8)
   en secret GitHub Actions, jamais en clair dans le repo. Garde-fous déjà
   en place (v0.15.1) : actions tierces épinglées au SHA de commit, jeton
   `GITHUB_TOKEN` en `contents: read` sauf sur le job qui publie la
   release, scan gitleaks sur l'historique complet, `.gitignore` couvrant
   les formes de jetons et le matériel de signature (`*.p8`, `*.p12`,
   `*.mobileprovision`, `*.cer`, `*.key`, `*.pem`).
6. **Icône finale** : le PNG 1024x1024 généré par `scripts/gen_app_icon.py`
   est une v1 fonctionnelle, à faire relire par un regard design avant
   soumission finale.
7. **Produits App Store Connect** : créer les 3 produits (`premium_monthly`
   abonnement, `premium_yearly` abonnement, `premium_lifetime`
   non-consommable) et l'offering `default` côté dashboard RevenueCat,
   puis tester l'achat/restauration sur compte sandbox avant soumission.
