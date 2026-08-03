# Changelog

Toutes les modifications notables de La Taverne iOS sont documentées ici.
Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
versionnement [semver](https://semver.org/lang/fr/).

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
