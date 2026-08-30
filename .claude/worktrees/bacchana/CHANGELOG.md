# Changelog

## [0.16.0] - 2026-08-05

### Changé (renommage produit, définitif)

- **Renommage produit "La Tournée" -> "Bacchus"** (sixième nom du produit,
  définitif) : l'univers narratif de la taverne reste intact - "Le
  Coupe-Gorge", "Le Pilori", "La Criée", "Le Taulier" ne changent pas.
  - Bundle identifier : `com.beloucif.latournee` -> `com.beloucif.bacchus`
    (framework `com.beloucif.bacchus.core`, tests
    `com.beloucif.bacchus.coretests`), aligné sur l'Android qui utilise déjà
    exactement cet identifiant. Toujours aucun impact utilisateur, l'app
    n'est pas publiée (aucun tag de release, compte Apple Developer Program
    pas encore créé).
  - Cible XcodeGen `LaTournee` -> `Bacchus`, module framework
    `LaTourneeCore` -> `BacchusCore`, cible de tests `LaTourneeTests` ->
    `BacchusTests`. Dossiers physiques renommés en conséquence
    (`LaTournee/` -> `Bacchus/`, `LaTourneeCore/Sources/LaTourneeCore/` ->
    `BacchusCore/Sources/BacchusCore/`, `LaTourneeTests/` -> `BacchusTests/`),
    historique git préservé (`git mv`). Tous les `import LaTourneeCore` ->
    `import BacchusCore`, fichier `LaTourneeApp.swift` -> `BacchusApp.swift`
    (`struct LaTourneeApp` -> `struct BacchusApp`).
  - `CFBundleDisplayName`/`CFBundleName` -> "Bacchus" (sans accent, aligné
    Android `strings.xml` `app_name`). Chaînes visibles renommées : titre
    `WelcomeView` ("LA TOURNÉE" -> "BACCHUS"), en-tête et bouton d'achat
    `PaywallView` ("LA TOURNÉE PREMIUM" -> "BACCHUS PREMIUM" / "Débloquer
    Bacchus Premium"), libellé accessibilité `HubView` ("Découvrir Bacchus
    Premium"), section "À propos" de `SettingsView` ("Bacchus").
  - Clés `UserDefaults` renommées du préfixe `latournee.` vers `bacchus.`
    (`AppState`) : toujours aucune migration nécessaire, app jamais publiée.
  - Identifiant d'entitlement RevenueCat (`RevenueCatEntitlements.swift`)
    **renommé** (`"La Tournee Pro"` -> `"Bacchus Pro"`, sans accent, id
    technique déjà créé côté dashboard RevenueCat, aligné sur l'Android) -
    toujours aucun abonné existant à migrer.
  - `scripts/sync_content.py` : le dépôt frère de contenu a lui aussi été
    renommé (`la-taverne-content` -> `bacchus-content`, seul son dossier
    change, pas son contenu ni l'univers taverne) - `CONTENT_ROOT` mis à
    jour en conséquence, en plus des chemins de destination
    `Bacchus/Resources/...`. `scripts/gen_app_icon.py` : chemin de sortie
    mis à jour vers `Bacchus/Assets.xcassets/...` (même piège de chemin que
    0.10.0, 0.14.0 et 0.15.0, revérifié).
  - `SettingsView.swift` (`legalURL`) : `latournee.beloucif.com` ->
    `bacchus.beloucif.com`, aligné sur le domaine déjà utilisé côté
    Android. Le README référençait encore par erreur l'ancien
    `lataverne.beloucif.com` (drift de doc non corrigé au renommage 0.15.0),
    corrigé dans le même lot.
  - CI (`ci.yml`, `release.yml`), `fastlane/Fastfile`, `fastlane/Appfile`,
    `fastlane/Matchfile`, `RELEASING.md`, `README.md`, `LICENSE` : toutes
    les références `LaTournee`/`la-tournee` mises à jour vers
    `Bacchus`/`bacchus`. Badges et dépôt GitHub `Adam-Blf/bacchus-ios`
    (repo déjà renommé côté GitHub avant cette PR, ancienne URL
    `Adam-Blf/la-tournee-ios` toujours valide par redirection mais mise à
    jour ici).

## [0.15.1] - 2026-08-05

### Sécurité (durcissement chaîne de build)

- **Actions tierces épinglées au SHA de commit** (`ci.yml`, `release.yml`) :
  un tag `@v4` est mutable, l'auteur d'une action compromise peut le
  déplacer vers du code hostile qui s'exécuterait avec le jeton du dépôt.
  Chaque `uses:` pointe désormais un commit immuable, le tag d'origine
  restant en commentaire pour la lisibilité et les mises à jour :
  `actions/checkout` `11d5960a326750d5838078e36cf38b85af677262` (v4.4.0),
  `actions/upload-artifact` `ea165f8d65b6e75b540449e92b4886f43607fa02`
  (v4.6.2), `ruby/setup-ruby` `95ef2b042f9d7a56d8268cba8559e2842e2ad01b`
  (v1.321.0), `softprops/action-gh-release`
  `3bb12739c298aeb8a4eeaf626c5b8d85266b0e65` (v2.6.2),
  `gitleaks/gitleaks-action` `ff98106e4c7b2bc287b24eaf42907196329070c7`
  (v2.3.9).
- **Permissions du `GITHUB_TOKEN` restreintes** : `contents: read` au
  niveau des deux workflows. Seul `build-and-upload` (release.yml) est
  élevé à `contents: write`, parce qu'il publie la GitHub Release. Aucun
  job de CI ne peut plus écrire dans le dépôt.
- **Scan de secrets en CI** : nouveau job `secrets` dans `ci.yml`
  (`ubuntu-latest`, checkout `fetch-depth: 0` puis gitleaks), sur push et
  pull request, aligné sur le job équivalent du dépôt web `la-taverne`.
  Un identifiant fuité fait échouer la CI au lieu d'être découvert après
  coup, ce qui compte d'autant plus que des certificats de signature et
  une clé App Store Connect transiteront bientôt par ce dépôt.
- **`.gitignore` défensif** : ajout des formes de jetons (`sbp_*`,
  `ghp_*`, `gho_*`, `ghs_*`, `github_pat_*`, `sk_*`) et du matériel de
  signature restant (`*.key`, `*.certSigningRequest`, `*.provisionprofile`,
  `AuthKey_*.p8`), en complément des motifs déjà présents. Vérifié avant
  ajout : aucun fichier suivi par git ne correspond à ces motifs.
- **Bac à sable des scripts de build réactivé** :
  `ENABLE_USER_SCRIPT_SANDBOXING` repasse de `NO` à `YES`. Vérifié avant
  bascule : aucune cible ne déclare de phase de script et aucune
  dépendance (RevenueCat, PostHog) ne fournit de build tool plugin, donc
  le sandbox ne coûte rien et confinera tout script ajouté plus tard à
  côté des certificats.
- **`NSUserTrackingUsageDescription` retiré** : l'app n'appelle jamais
  `ATTrackingManager` ni `AppTrackingTransparency` (vérifié par recherche
  sur toutes les sources Swift) et `PrivacyInfo.xcprivacy` déclare
  `NSPrivacyTracking = false`. Une chaîne d'usage sans usage réel n'attire
  qu'une question du reviewer Apple.
- **XcodeGen épinglé en CI** : `brew install xcodegen` (version du jour,
  build non reproductible) remplacé par le téléchargement de l'archive de
  release 2.46.0 avec vérification SHA-256 (`4d9e34b6...96806`) avant
  extraction, dans les trois jobs concernés. Le `brew install` reste
  documenté pour le poste de développement local.

## [0.15.0] - 2026-08-05

### Changé (renommage produit)

- **Renommage produit "Meskova" -> "La Tournée"** (cinquième nom du
  produit) : l'univers narratif de la taverne reste intact - "Le
  Coupe-Gorge", "Le Pilori", "La Criée", "Le Taulier" ne changent pas.
  - Bundle identifier : `com.beloucif.meskova` -> `com.beloucif.latournee`
    (framework `com.beloucif.latournee.core`, tests
    `com.beloucif.latournee.coretests`). Toujours aucun impact utilisateur,
    l'app n'est pas publiée.
  - Cible XcodeGen `Meskova` -> `LaTournee`, module framework
    `MeskovaCore` -> `LaTourneeCore`, cible de tests `MeskovaTests` ->
    `LaTourneeTests`. Dossiers physiques renommés en conséquence
    (`Meskova/` -> `LaTournee/`, `MeskovaCore/Sources/MeskovaCore/` ->
    `LaTourneeCore/Sources/LaTourneeCore/`, `MeskovaTests/` ->
    `LaTourneeTests/`), historique git préservé (`git mv`). Tous les
    `import MeskovaCore` -> `import LaTourneeCore`.
  - `CFBundleDisplayName`/`CFBundleName` -> "La Tournée", texte ATT
    (`NSUserTrackingUsageDescription`) mis à jour. Chaînes visibles
    renommées : titre `WelcomeView` ("LA TOURNÉE"), en-tête et bouton
    d'achat `PaywallView` ("LA TOURNÉE PREMIUM" / "Débloquer La Tournée
    Premium"), libellé accessibilité `HubView` ("Découvrir La Tournée
    Premium"), section "À propos" de `SettingsView` ("La Tournée").
  - Clés `UserDefaults` renommées du préfixe `meskova.` vers `latournee.`
    (`AppState`) : toujours aucune migration nécessaire, app jamais
    publiée.
  - Contrairement au rebrand précédent, l'identifiant d'entitlement
    RevenueCat (`RevenueCatEntitlements.swift`) est cette fois
    **renommé** (`"La Taverne Pro"` -> `"La Tournee Pro"`, sans accent,
    id technique exact créé côté dashboard RevenueCat) - toujours aucun
    abonné existant à migrer.
  - `scripts/sync_content.py` et `scripts/gen_app_icon.py` : chemins de
    destination mis à jour vers `LaTournee/Resources/...` /
    `LaTournee/Assets.xcassets/...` (même piège de chemin que 0.10.0 et
    0.14.0, revérifié).
  - `SettingsView.swift` (`legalURL`) : `lataverne.beloucif.com` ->
    `latournee.beloucif.com` (actif), plus besoin d'attendre une
    décision DNS/web séparée.
  - CI (`ci.yml`, `release.yml`), `fastlane/Fastfile`, `fastlane/Appfile`,
    `fastlane/Matchfile`, `RELEASING.md`, `README.md`, `LICENSE` :
    projet/scheme `LaTournee.xcodeproj`/`LaTournee`, IPA
    `build/LaTournee.ipa`, `app_identifier` `com.beloucif.latournee`.
    Badges et dépôt GitHub `Adam-Blf/la-tournee-ios` (repo renommé).

## [0.14.1] - 2026-08-05

### Corrigé (contraste, thème sombre)

- **Texte illisible sur fonds clairs en thème sombre** : signalé en jouant
  ("du blanc sur du jaune c'est illisible, du blanc sur du vert clair c'est
  illisible"), déjà corrigé côté web le 2026-08-04, jamais porté sur iOS.
  Cause racine : `Theme.Color.ink` s'inverse avec le thème (foncé en clair,
  quasi blanc en sombre) alors que les aplats "pop" et l'accent `neon` /
  `neonDeep` / `neonSoft` restent CLAIRS dans les deux thèmes - du texte
  `ink` posé dessus tombait jusqu'à 1.20:1 en sombre (roulette, tuiles du
  hub, boutons d'action, paywall, réglages, tutoriel).
  - Nouveau token fixe `Theme.Color.tileInk` (`#111111`, jamais thématisé),
    appliqué à tout texte/icône posé sur un aplat `pop-*` ou un accent plein
    (`neon`/`neonDeep`/`neonSoft`) : roue de la roulette, boutons d'action
    principaux (tous les modes), bouton "+" d'ajout de joueur, bouton
    d'achat du paywall, bouton primaire des réglages.
  - Nouveau token thémable `Theme.Color.danger` (distinct de `cardRed`,
    fixe et réservé aux pips de carte/`cardFace`) : compte à rebours de la
    Criée, bouton destructif "Réinitialiser la tablée" des réglages -
    `cardRed` y tombait à 2.38:1 en sombre.
  - Rampe d'élévation du thème sombre resynchronisée avec la refonte web du
    2026-08-04 (`surface` `#1D1B20`->`#2E2836`, `surfaceElevated`
    `#26232B`->`#3C3446`, etc.), `inkMuted` sombre et l'alpha de bordure fine
    (0.20->0.38) alignés sur `docs/DESIGN_TOKENS.md`.
  - Textes secondaires posés directement sur `cardFace` (fixe, blanc dans
    les deux thèmes) basculés sur `cardInk.opacity(0.7)` au lieu de
    `inkSecondary`/`inkMuted` (thématisables) - même bug, sur fond carte au
    lieu d'un aplat pop.
  - Bannières de règles/cible actives du prompt déplacées de
    `surfaceElevated` vers `backgroundRaised` : `orangeInk` n'atteignait que
    4.39:1 sur `surfaceElevated` en clair (sous l'AA 4.5:1), détecté par la
    nouvelle garde de contraste.
  - Portage exact de la palette web (`la-taverne/src/styles/tokens.css`,
    `docs/DESIGN_TOKENS.md`) : palette source de vérité extraite dans
    `LaTourneeCore/Sources/LaTourneeCore/ThemePalette.swift` (hex bruts,
    platform-agnostic), `LaTournee/Theme/Theme.swift` ne construit plus les
    `Color` que depuis cette source unique.
- **Garde mécanique de contraste** (`LaTourneeTests/ContrastGuardTests.swift`) :
  calcule le ratio WCAG 2.1 réel de chaque paire encre/fond dérivée de
  `ThemePalette` (pas une liste écrite à la main), dans les deux thèmes, et
  échoue sous 4.5:1 (texte normal) ou 3:1 (texte large/objet UI). Tourne en
  CI sur chaque PR (`LaTourneeTests`, cible `LaTourneeCore`).

## [0.14.0] - 2026-08-04

### Changé (renommage produit)

- **Renommage produit "La Taverne" -> "Meskova"** : le nom d'app, de store et
  de titres devient Meskova partout, mais l'univers narratif de la taverne
  reste intact - "Le Coupe-Gorge", "Le Pilori", "La Criée", "Le Taulier" et
  tous les libellés de mode ne changent pas. Seule l'identité produit
  change, pas le contenu de jeu.
  - Bundle identifier : `com.beloucif.lataverne` -> `com.beloucif.meskova`
    (framework `com.beloucif.meskova.core`, tests
    `com.beloucif.meskova.coretests`). Sans impact utilisateur : l'app n'a
    jamais été soumise à TestFlight ni à l'App Store (aucun tag de release
    dans l'historique git, compte Apple Developer Program pas encore créé).
  - Cible XcodeGen `LaTaverne` -> `Meskova`, module framework
    `LaTaverneCore` -> `MeskovaCore`, cible de tests `LaTaverneTests` ->
    `MeskovaTests`, schemes et noms de produit alignés. Dossiers physiques
    renommés en conséquence (`LaTaverne/` -> `Meskova/`,
    `LaTaverneCore/Sources/LaTaverneCore/` -> `MeskovaCore/Sources/
    MeskovaCore/`, `LaTaverneTests/` -> `MeskovaTests/`), historique git
    préservé (`git mv`).
  - Tous les `import LaTaverneCore` -> `import MeskovaCore` (app, tests).
  - `CFBundleDisplayName`/`CFBundleName` -> Meskova, texte ATT
    (`NSUserTrackingUsageDescription`) mis à jour.
  - Chaînes visibles renommées : titre `WelcomeView` ("MESKOVA"), en-tête et
    bouton d'achat `PaywallView` ("MESKOVA PREMIUM" / "Débloquer Meskova
    Premium"), libellé accessibilité `HubView` ("Découvrir Meskova
    Premium"), section "À propos" de `SettingsView` ("Meskova").
  - Clés `UserDefaults` renommées du préfixe `lataverne.` vers `meskova.`
    (`AppState`) : aucune migration nécessaire, l'app n'a jamais été
    installée en dehors des simulateurs CI éphémères.
  - `scripts/sync_content.py` et `scripts/gen_app_icon.py` : chemins de
    destination mis à jour vers `Meskova/Resources/...` /
    `Meskova/Assets.xcassets/...` (rappel du bug de chemin déjà corrigé une
    fois en 0.10.0 - vigilance maintenue au renommage).
  - CI (`ci.yml`, `release.yml`), `fastlane/Fastfile`, `fastlane/Appfile`,
    `fastlane/Matchfile`, `RELEASING.md`, `README.md` : projet/scheme
    `Meskova.xcodeproj`/`Meskova`, IPA `build/Meskova.ipa`, `app_identifier`
    `com.beloucif.meskova`.
  - **Non modifié, volontairement** : l'identifiant d'entitlement
    RevenueCat reste littéralement `"La Taverne Pro"` (non renommable sans
    migration du dashboard RevenueCat, seul le libellé affiché change).
    Aucune intégration Supabase ajoutée. Dépôt GitHub, remote et badges
    inchangés (`Adam-Blf/la-taverne-ios`). Domaine `lataverne.beloucif.com`
    référencé depuis `SettingsView` laissé en l'état, décision DNS/web hors
    périmètre de ce renommage iOS.

## [0.13.0] - 2026-08-04

### Ajouté

- Écran Réglages (`SettingsView.swift`), accessible depuis l'icône engrenage du Hub, à
  parité avec `la-taverne/src/components/screens/SettingsScreen.tsx` : apparence
  (système/clair/sombre), statut premium + accès au paywall + restauration des achats,
  consentement RGPD pour la mesure d'audience (nouveau `AppState.analyticsConsent`,
  persisté, jamais pré-coché) avec lien vers la politique de confidentialité, section
  légale (mentions/CGU/confidentialité, renvoie vers `lataverne.beloucif.com` en
  attendant un portage natif), à propos (version, éditeur Adam Beloucif / BLF Labs), et
  réinitialisation de la tablée (`AppState.resetTablee()`, ne touche jamais au premium).
  Note de parité : la section "Mes règles" du web est omise, `LaTaverneCore` n'a pas
  encore de moteur de règles personnalisées.

### Corrigé

- `PaywallView` : le titre "La Taverne Premium" passe de l'encre à l'accent orange
  (`Theme.Color.orangeInk`) - en encre il se fondait avec le fond/la bordure du même ton
  dans les deux thèmes, illisible.

## [0.12.0] - 2026-08-03

### Ajouté

- Thème sombre "pop" sur encre neutre, à parité avec le refresh DA du web
  (PR web #52/#53, `la-taverne/src/styles/tokens.css`) : `Theme.Color` est
  désormais entièrement dynamique (`Theme.dynamic(light:dark:)`, `UIColor`
  résolu au trait collection courant), plus de token `orangeInk` (texte
  orange accessible) et de pops `popYellow`/`popPink`/`popBlue`/`popLime`.
  Corrections a11y appliquées aussi en clair (`cardRed` -> `#C71F2D`,
  `premium` -> `#855C12`). Préférence `ThemeMode` (système/clair/sombre)
  persistée dans `AppState.themeMode`, bascule discrète dans `HubView`
  (icône soleil/lune), aucune police serif introduite.
- Genre et statut relationnel facultatifs par joueur (feature #54) :
  `Player.gender` / `Player.relationship` (`LaTaverneCore`), saisis sur
  `WelcomeView` dans un panneau replié par défaut, jamais requis pour
  jouer. 100 % local (`AppState.playerAttributes`, `UserDefaults`),
  **jamais envoyés en analytics**.
- `LaTaverneCore/Targeting.swift` : résout `PromptTarget.genderMasculine`/
  `.genderFeminine`/`.single`/`.couple`/`.pair` vers un ou deux joueurs
  concrets, RNG injectable et seedable par tour, repli gracieux sur un
  joueur actif aléatoire si personne ne correspond au critère. Branché sur
  `PromptView` (bannière "C'est à … de jouer"), à parité avec
  `la-taverne/src/core/engine/targeting.ts` et
  `PromptGameScreen.tsx`. Couvert par `TargetingTests.swift`.

## [0.11.0] - 2026-08-03

- Contenu natif de La Roue du Destin porté de 8 à 40 segments et Le Pilori
  de 10 à 40 chefs d'accusation, à parité avec `la-taverne/src/content/
  roulette.ts` et `tribunal.ts` (commit c52783b, PR web #49). Store-safe :
  zéro alcool nommé, uniquement pénalités abstraites, défis d'ambiance et
  griefs de soirée.
- Commentaire de `RouletteView` corrigé (8-segment -> 40-segment wheel).
- Vérification anti-résidus : aucune mention Abel Studio/Abel Labs,
  BlackOut ou La Tournée dans les chaînes visibles ou la doc iOS.
- Note de parité : les sous-titres de mode du web (Action ou Vérité,
  Je n'ai jamais, C'est un 10 mais, 7 Secondes) n'ont pas d'équivalent
  affiché côté iOS - le Hub affiche des tuiles par pack (sous-titre
  Classique/Extrême propre à chaque pack), pas une tuile par mode comme
  sur le web. Aucun changement de copie appliqué là où le concept
  n'existe pas, pour ne pas écraser un sous-titre de pack correct.

## [0.10.0] - 2026-08-03

- Contenu des packs gratuits porte a 80 items chacun (sync depuis la-taverne-content 1.10.0).
- Correction du script scripts/sync_content.py : chemin de destination LaTaverne (le nom de dossier reel, sans espace).

Toutes les modifications notables de La Tournée iOS sont documentées ici.
Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
versionnement [semver](https://semver.org/lang/fr/).

## [0.10.0] - 2026-08-03

### Ajouté

- Billing réel via RevenueCat (`RevenueCatEntitlements`, package SPM
  `purchases-ios` 5.83.0), gated par `REVENUECAT_API_KEY` : clé absente
  (CI, clone frais) → `StubEntitlements` inchangé, mode invité, zéro
  crash. Entitlement `La Taverne Pro`, produits `premium_monthly`
  (4,99 €) / `premium_yearly` (19,99 €) / `premium_lifetime` (34,99 €),
  offering `default` - parité avec `la-taverne/src/lib/billing.ts`.
- Analytics réel via PostHog EU (`PostHogAnalytics`, package SPM
  `posthog-ios` 3.69.0), gated par `POSTHOG_API_KEY` et par le
  consentement explicite `AnalyticsProviding.isEnabled` (jamais pré-coché) :
  clé absente → `StubAnalytics` inchangé. Autocapture et écrans
  désactivés, seuls les événements explicites sont envoyés.
  Événements paywall : `paywall_shown`, `paywall_dismissed`,
  `purchase_started`, `purchase_completed`, `restore_completed`.
- `PaywallView` (SwiftUI) : 3 offres (mensuel / annuel / à vie mis en
  avant comme meilleure offre), prix toujours affichés (repli si les
  offerings RevenueCat ne sont pas chargés), aucun essai gratuit
  annoncé, achat désactivé ("Bientôt disponible") sans provider réel,
  bouton de restauration. Accessible depuis le bouton "Premium" du Hub
  et depuis tout pack premium verrouillé (nouvelle route `.paywall`).
- `LaTaverneCore/PremiumPlan.swift` : catalogue de plans et prix de
  repli, logique pure testée (`PremiumPlanTests.swift`), partagée entre
  le paywall et les providers de billing.
- `LaTaverne/Config/Config.xcconfig` (committé, clés vides par défaut) +
  `Config.local.xcconfig` (gitignored) + `.example` : les clés
  RevenueCat/PostHog s'injectent dans l'Info.plist via xcconfig, jamais
  en dur, jamais commitées.

### Changé

- `EntitlementProviding`/`AnalyticsProviding` étendus (`fetchPackages`,
  `purchase` ; sélection du provider via `EntitlementsFactory`/
  `AnalyticsFactory`) sans changer le comportement par défaut en mode
  invité.

## [0.9.0] - 2026-08-03

### Ajouté

- Mode "Tu préfères" (wouldYouRather) transformé en mode embarqué à
  mécanique de vote, en parité avec la version web : un dilemme A ou B
  s'affiche, le téléphone tourne, chaque joueur actif tape son camp en
  privé (`votes: [playerId: Side]`). Au reveal, la minorité trinque
  (`minorityPenalty`) ; égalité parfaite ou vote unanime, personne ne
  trinque. Porté fidèlement depuis
  `la-taverne/src/core/engine/wouldYouRatherSession.ts` et
  `la-taverne/src/content/wouldYouRather.ts`
  (`WouldYouRatherSession.swift`, `WouldYouRatherContent.swift`, LaTaverneCore ;
  `WouldYouRatherView.swift`). 84 dilemmes embarqués.
- `WouldYouRatherSessionState` : moteur pur à état de valeur (aléatoire
  injectable), phases voting → reveal → finished. Ne mute jamais `Player` :
  le récap de fin lit `penaltyCounts` en interne au lieu de passer par
  `RecapView`.
- Tuile "Tu préfères" dans le hub, route `.wouldYouRather` dans
  `AppState`/`RootView`, `session_completed` (`mode: "wouldYouRather"`,
  `turns: roundNumber`) au retour au hub.

### Changé

- "Tu préfères" quitte la voie prompt-carte passive : le pack
  `tu-preferes-classique` et son entrée dans `premium-catalog.json` sont
  retirés du binaire iOS au profit du mode embarqué ci-dessus.

## [0.8.0] - 2026-08-03

### Ajouté

- Mode "Le Tableau d'Honneur" (ranking) : le 5e et dernier mode. Un juge
  découvre une question de classement secrète et classe les autres joueurs
  selon elle, le groupe doit ensuite retrouver la vraie question parmi 4
  propositions sans jamais la voir avant le reveal, portées fidèlement
  depuis `la-taverne/src/core/engine/rankingSession.ts` et
  `la-taverne/src/content/ranking.ts` (`RankingSession.swift`,
  `RankingContent.swift`, LaTaverneCore ; `RankingView.swift`). 40 questions
  embarquées.
- `RankingSessionState` : moteur pur à état de valeur (aléatoire injectable),
  phases handoff → judging → return → guessing → reveal → finished. Bonne
  devinette : le juge prend `rankingJudgePenalty` (3) pénalités. Mauvaise :
  chaque non-juge prend `rankingGroupPenalty` (1) pénalité. Le rôle de juge
  tourne à chaque manche (`nextRound`). Ne mute jamais `Player` : le récap
  de fin (`RankingRecapView`, intégré à `RankingView`) lit `penaltyCounts`
  en interne au lieu de passer par `RecapView`.
- Tuile "Le Tableau d'Honneur" dans le hub (minimum 4 joueurs pour garder un
  juge distinct d'au moins 3 candidats à classer), route `.ranking` dans
  `AppState`/`RootView`, `session_completed` (`mode: "ranking"`,
  `turns: roundNumber`) au retour au hub.

## [0.7.0] - 2026-08-03

### Ajouté

- Mode "Quitte ou Trinque" (quiz) : chaque joueur répond à une question de
  culture générale valant 1 à 3 points tirés au hasard, portées fidèlement
  depuis `la-taverne/src/core/engine/quizSession.ts` et
  `la-taverne/src/content/quiz.ts` (`QuizSession.swift`, `QuizContent.swift`,
  LaTaverneCore ; `QuizView.swift`). 60 questions embarquées, 6 catégories
  (Histoire-géo, Culture G, Sport, Musique, Ciné & séries, À table).
- `QuizSessionState` : moteur pur à état de valeur (aléatoire injectable),
  bonne réponse → cagnotte, puis choix cumuler (`keepPot`, risque le tout au
  tour suivant) ou distribuer (`distributePot`, gloire sans pénalité pour le
  distributeur) ; mauvaise réponse (`answerWrong`) prend la cagnotte + les
  points en jeu en pénalité et fait tourner la file. Ne mute jamais `Player` :
  le récap de fin (`QuizRecapView`, intégré à `QuizView`) lit `penaltyCounts`
  en interne au lieu de passer par `RecapView`.
- Tuile "Quitte ou Trinque" dans le hub, route `.quiz` dans
  `AppState`/`RootView`, `session_completed` (`mode: "quiz"`,
  `turns: turnNumber`) au retour au hub.

## [0.6.0] - 2026-08-03

### Ajouté

- Mode "La Criée" (auction) : phases enchère → défi (chrono 60s) → résultat,
  portées fidèlement depuis `la-taverne/src/content/auction.ts` et
  `AuctionScreen.tsx` (`AuctionContent.swift`, `AuctionView.swift`).
  50 thèmes embarqués, tirage sans répétition immédiate (`pickTheme`).
- Timer de défi (`Timer.scheduledTimer`, 1s) invalidé à la sortie
  (`onDisappear`) et à chaque relance pour éviter toute fuite. Échec
  automatique à 0s, succès dès que le compte cité rattrape l'enchère.
- Tuile "La Criée" dans le hub, route `.auction` dans `AppState`/`RootView`,
  `session_completed` (`mode: "auction"`, `turns: roundsPlayed`) au retour
  au hub. Comme la roulette, aucun joueur nommé, aucune addition, aucun récap.

## [0.5.0] - 2026-08-03

### Ajouté

- Mode "Le Pilori" (tribunal) : phases intro → collecte (passe-le-téléphone
  + écriture secrète, 200 caractères max) ou chefs d'accusation embarqués
  → défense → vote à main levée → verdict, portées fidèlement depuis
  `la-taverne/src/content/tribunal.ts` et `TribunalScreen.tsx`
  (`TribunalContent.swift`, `TribunalSession.swift`, LaTaverneCore).
- `TribunalSession` : moteur pur (aléatoire injectable), tire une
  accusation au hasard puis un accusé excluant son auteur
  (`pickAccused`), majorité coupable incrémente une pénalité locale.
  Ne mute jamais `Player` : le récap de fin de procès (`TribunalRecapView`,
  intégré à `TribunalView`) lit `penaltyCounts` en interne au lieu de
  passer par `RecapView`.
- Tuile "Le Pilori" dans le hub (minimum 3 joueurs pour garder un accusé
  distinct de l'auteur), route `.tribunal` dans `AppState`/`RootView`,
  `session_completed` (`mode: "tribunal"`, `turns: trialsPlayed`) au
  retour au hub.

## [0.4.0] - 2026-08-03

### Ajouté

- Mode "La Roue du Destin" (roulette) : roue à 8 segments embarquée
  (`RouletteContent.swift`, LaTaverneCore), portée fidèlement depuis
  `la-taverne/src/content/roulette.ts` et `RouletteScreen.tsx`. Aucun
  joueur nommé, aucune addition, aucun récap : la roue compte
  uniquement les tours joués pour clôturer la session (`session_completed`,
  `mode: "roulette"`, `turns: spinsPlayed`).
- Animation de spin "casino" (`.timingCurve(0.17, 0.67, 0.12, 0.99)`,
  3.2s), 5 tours complets + alignement sur le segment tiré, haptics
  moyen au lancer et lourd au résultat. Dégrade proprement en résultat
  direct sans rotation si `accessibilityReduceMotion` est actif.
- Tuile "La Roue du Destin" dans le hub, route `.roulette` dans
  `AppState`/`RootView`.

## [0.3.0] - 2026-08-03

### Corrigé

- Fastlane : nom de projet, de scheme et d'IPA alignés sur la sortie
  XcodeGen (`LaTaverne.xcodeproj`, scheme `LaTaverne`, `build/LaTaverne.ipa`)
  au lieu de la variante avec espace qui faisait échouer `scan`,
  `build_app` et `upload_to_testflight`. Références documentaires
  (`README.md`, `RELEASING.md`) corrigées dans le même lot.

### Ajouté

- Manifeste de confidentialité Apple (`LaTaverne/PrivacyInfo.xcprivacy`),
  requis pour la soumission App Store : aucun tracking, aucune donnée
  collectée, déclaration de la required reason API
  `NSPrivacyAccessedAPICategoryUserDefaults` (raison `CA92.1`). Inclus
  dans la phase de ressources de la cible `LaTaverne` via `project.yml`.

### Modifié

- Renommage du pack Picolo vers son titre canonique "Le Taulier"
  (aligné sur la référence web) dans `premium-catalog.json` et
  `Packs/picolo-soiree.json`. Les identifiants techniques (`picolo`,
  `picolo-soiree`, `picolo-chaos`) restent inchangés.

## [0.2.0] - 2026-08-02

### Modifié

- Refonte visuelle complète vers la direction artistique taverne
  néobrutaliste, thème clair par défaut : papier crème (#FFF9F0), encre
  noire (#111111), accent orange (#FF5C00), surfaces blanches, ombres
  dures noires sans halo. Palette portée depuis
  `la-taverne-content/tokens/tokens.json` v2 dans `Theme.swift`.
- L'app force désormais le mode clair (`preferredColorScheme(.light)`),
  la couleur d'accent du catalogue d'assets passe à l'orange.
- Le jeu de cartes s'affiche sous son nom de taverne "Le Coupe-Gorge"
  dans le hub et les libellés d'accessibilité. Les identifiants
  techniques (modes, routes, moteur) restent inchangés.
- Carte signature : ombre dure noire décalée et contour encre à la place
  du halo néon.
- Icône App Store régénérée aux couleurs taverne (fond papier, plaque
  orange, carte blanche, pique noir, ombre dure) via
  `scripts/gen_app_icon.py`, chemin de sortie corrigé vers `LaTaverne/`.

## [0.1.0] - 2026-08-01

### Ajouté

- Structure XcodeGen (`project.yml`) : cible `La TaverneCore` (framework logique
  pure), `La Taverne` (app SwiftUI), `La TaverneTests` (XCTest sur le core).
- Portage fidèle des règles Borderland depuis la référence web
  (`la-taverne/src/core/borderland.ts`) : deck 52 cartes, As = pénalité
  majeure, multiplicateurs de contest {0:1, 1:1, 2:2, 3:4}, rotation des
  joueurs actifs.
- `PromptSession` : pile de tirage sans répétition avant épuisement, règles
  persistantes à durée (`durationTurns`), interpolation `{player}`/`{player2}`.
- `ContentPack` Codable aligné sur `la-taverne-content/schema/content.schema.json`.
- Écrans SwiftUI : Welcome (check-in joueurs), Hub (grille des modes, packs
  premium verrouillés), Borderland (carte géante, flip, contest), Prompt
  (générique multi-modes), Recap (podium).
- Thème Neo-Tokyo Borderland porté depuis `la-taverne-content/tokens/tokens.json`.
- Polices embarquées (Anton, Space Grotesk, Space Mono) en local, aucune
  dépendance CDN.
- 7 packs gratuits embarqués (`premium=false`), catalogue premium en
  métadonnées seules (`premium-catalog.json`), packs premium jamais livrés
  dans le binaire tant que le billing n'est pas branché.
- Providers `EntitlementProviding` / `AnalyticsProviding` avec stubs sûrs par
  défaut (`isPremium=false`, analytics désactivées), TODO documentés pour
  StoreKit 2 / RevenueCat et PostHog.
- Icône App Store 1024x1024 générée par script (`scripts/gen_app_icon.py`).
- CI GitHub Actions (`macos-15`) : génération XcodeGen, build et tests
  `La TaverneTests` sur simulateur iPhone 16.

### Notes de conformité

- Wording store-safe : aucune référence à l'alcool, unité "pénalité" /
  "PÉNALITÉ MAJEURE" uniquement.
- Aucun achat in-app actif dans cette version (guideline 3.1.1 respectée par
  construction, rien à vendre tant que StoreKit n'est pas branché).
