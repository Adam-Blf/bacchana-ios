# Publication Meskova iOS

Ce document décrit le processus de publication sur l'App Store.

## Prerequis one-shot

Avant la première publication, exécuter ces étapes une seule fois.

### 1. Créer un compte Apple Developer Program

- Aller sur https://developer.apple.com/enroll/
- Payer les 99 dollars de frais annuels
- Attendre l'activation du compte (24-48h)

### 2. Créer l'app dans App Store Connect

- Aller sur https://appstoreconnect.apple.com
- Ajouter une nouvelle app (Bundle ID `com.beloucif.meskova`)
- Remplir la fiche produit (description, captures d'écran, catégorie Jeux, classification d'âge 17+)
- Configurer les prix et disponibilité

### 3. Configurer les certificats et profils de signature via fastlane match

`fastlane match` automatise la gestion des certificats et profils en les stockant dans un repo git prive.

#### Étape 1 : Créer un repo git prive pour les certificats

Sur GitHub (ou GitLab), créer un repo prive nommé `certificates` ou `ios-certs`. Ce repo ne sera accessible qu'à toi.

```bash
# Exemple sur GitHub
gh repo create Adam-Blf/certificates --private --confirm
```

Garder le lien du repo pour l'étape suivante.

#### Étape 2 : Initialiser fastlane match (une seule fois)

Sur une machine macOS avec Xcode, lancer :

```bash
# Générer les certs et les stocker dans le repo certificates
fastlane match appstore -u adam.beloucif@efrei.net --team_id=XXXXXXXXXX

# Quand demandé, entrer :
# - Git URL du repo certificates (ex. https://github.com/Adam-Blf/certificates.git)
# - Un mot de passe encrypt git fort (mécanique de chiffrement de fastlane match)
```

Cela va :
- Créer un certificat de distribution dans Apple Developer
- Générer un profil de provisioning "Meskova App Store"
- Stocker le tout chiffré dans le repo certificates

Mémoriser ou sauvegarder le mot de passe git - il sera requis pour dechiffrer les certs en CI.

### 4. Créer une clé API App Store Connect

- Aller sur https://appstoreconnect.apple.com
- Settings > Users and Access > Integrations > App Store Connect API
- Créer une nouvelle clé (role Deveoper ou Admin)
- Télécharger la clé en format JSON (fichier `AuthKey_XXXXXXXXXX.p8`)
- Ne jamais commiter le fichier P8, le stocker en local sécurisé

### 5. Configurer les secrets GitHub Actions

Une fois tous les éléments en place, créer les secrets GitHub Actions :

```bash
# Team ID depuis Apple Developer
gh secret set FASTLANE_TEAM_ID --body "XXXXXXXXXX"

# Email Apple ID (ou AppleSeed account si créé)
gh secret set FASTLANE_APPLE_ID --body "adam.beloucif@efrei.net"

# URL du repo certificates (https ou ssh)
gh secret set MATCH_GIT_URL --body "https://github.com/Adam-Blf/certificates.git"

# Mot de passe fastlane match (celui d'encryptage des certs)
gh secret set MATCH_PASSWORD --body "MOT_DE_PASSE_FORT"

# Contenu du fichier JSON AuthKey (encoder en JSON valide)
gh secret set APP_STORE_CONNECT_API_KEY_JSON < chemin/vers/AuthKey_XXXXXXXXXX.json

# Vérifier tous les secrets
gh secret list
```

## Workflow quotidien : publier une version

### Étape 1 : Développer et tester

Développer les features sur une branche `feat/*` ou `fix/*`, commiter régulièrement, valider localement.

### Étape 2 : Une commande pour publier

Une fois prêt à publier (version testée, PR mergée sur main), exécuter **une seule commande** depuis ton Windows :

```bash
python scripts/release.py --version 1.0.0
```

Cela va :
- Bumper `MARKETING_VERSION` et `CURRENT_PROJECT_VERSION` dans `project.yml`
- Commiter avec le message `chore: bump version to 1.0.0`
- Créer un tag annoté `v1.0.0`
- Pousser commits et tags vers GitHub (`origin`)

### Étape 3 : GitHub Actions se charge du reste

À la réception du tag `v1.0.0` (push vers GitHub), la workflow `.github/workflows/release.yml` se déclenche automatiquement :

1. **Tests** : génère le projet Xcode via `xcodegen`, lance les tests sur simulateur
2. **Build signé** : décode les certificats depuis le repo `certificates` via `fastlane match`, construit l'IPA signé avec `build_app`
3. **Upload TestFlight** : envoie l'IPA à App Store Connect via `upload_to_testflight` (visible aux testeurs internes)
4. **GitHub Release** : crée une release GitHub avec le lien TestFlight

### Étape 4 : Tester sur TestFlight et soumettre

Une fois le build disponible sur TestFlight (accesible via l'app TestFlight pour les testeurs configurés) :

1. Tester l'app
2. Si tout est OK, soumettre manuellement via App Store Connect (button "Submit for Review")
3. Apple valide (~24-48h) et l'app devient disponible à tous les utilisateurs sur l'App Store

Optionnel : configurer une lane `release` dans `fastlane/Fastfile` pour automatiser la soumission avec `deliver`, mais cela demande une configuration plus complexe (capture d'écran, etc.).

## Dry run avant production

Avant ta première publication réelle, tester le workflow en dry-run :

```bash
python scripts/release.py --version 1.0.0 --dry-run
```

Cela affichera les changements qui seraient apportés sans rien commiter.

## Troubleshooting

### "fastlane match" échoue avec "Codesigning Identity"

Les certificats stockés dans le repo `certificates` sont possiblement expirés ou corrompus. Regénérer manuellement sur une Mac :

```bash
fastlane match appstore --force_for_new_devices -u adam.beloucif@efrei.net --team_id=XXXXXXXXXX
```

Cela va créer de nouveaux certs et les mettre à jour dans le repo.

### "upload_to_testflight" échoue

Vérifier dans App Store Connect :
1. L'app est créée et visible dans le dashboard
2. Les versions précédentes n'ont pas déjà des builds en attente de validation
3. La clé API App Store Connect a un rôle Admin ou Developer

### "XcodeGen generate" échoue

Vérifier que `project.yml` est bien valide YAML. Lancer localement (sur une Mac) :

```bash
xcodegen generate
open Meskova.xcodeproj
```

### Vérifier les secrets GitHub

```bash
gh secret list
```

Doit afficher les 5 secrets : `FASTLANE_TEAM_ID`, `FASTLANE_APPLE_ID`, `MATCH_GIT_URL`, `MATCH_PASSWORD`, `APP_STORE_CONNECT_API_KEY_JSON`.

Si l'un manque ou est mal configuré, le recréer exactement.

## Versioning

Suivre [Semantic Versioning](https://semver.org/) :
- `MAJOR.MINOR.PATCH` (ex. 1.0.0, 1.2.3)
- **MAJOR** : breaking change (nouvel UX, nouveau format de contenu)
- **MINOR** : feature utilisateur
- **PATCH** : bugfix ou perf

À chaque release, mettre à jour le badge version du README pour que le lecteur voit directement la version courante du repo.

## References

- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Fastlane Documentation](https://docs.fastlane.tools/)
- [Fastlane match](https://docs.fastlane.tools/actions/match/)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- [TestFlight Help](https://help.apple.com/testflight/)
