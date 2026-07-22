# Renta VTC — Spécification projet pour Claude Code

## 1. Contexte et objectif

Renta VTC est une application mobile destinée aux chauffeurs VTC (Uber, Bolt, Heetch, etc.)
sous statut **auto-entrepreneur**. Elle permet de savoir, course par course, ce qu'il reste
**réellement** au chauffeur une fois déduits le carburant et les cotisations sociales URSSAF.

**Problème résolu** : les chauffeurs voient un prix affiché par la plateforme (ex: "9,12 €
net TTC") mais ce montant ne reflète ni le coût réel du carburant, ni les cotisations
sociales qu'ils devront reverser à l'URSSAF. Renta VTC fait ce calcul en quelques secondes.

**Pas de compte utilisateur, pas de backend.** Toutes les données (profil véhicule, statut
fiscal) sont saisies une seule fois et stockées **localement sur l'appareil**. Aucune donnée
n'est envoyée à un serveur.

---

## 2. Stack technique

| Composant | Choix | Justification |
|---|---|---|
| Framework | **Flutter** (Dart) | Un seul code source pour Android + iOS, bon rendu UI natif, écosystème mature pour formulaires/stockage local |
| Stockage local | **shared_preferences** | Pas besoin de base relationnelle : quelques valeurs de config (profil véhicule, taux URSSAF) suffisent. Pas de compte, pas de sync cloud. |
| Format de config | JSON encodé en `String` dans SharedPreferences | Simple à faire évoluer sans migration lourde |
| Formatage nombres | `intl` | Formatage monétaire et décimal cohérent (virgule française) |
| Gestion d'état | `StatefulWidget` natif Flutter (pas de Provider/Riverpod/Bloc) | App simple à 2-3 écrans, pas besoin d'une lib de state management dédiée pour le MVP |
| Tests | `flutter_test` | Tests unitaires sur la logique de calcul (critique, doit être fiable) |
| CI/CD | GitHub Actions (optionnel, voir §8) | Build automatisé Android/iOS à chaque push |

**Explicitement hors scope pour le MVP** : compte utilisateur, backend, base de données
distante, lecture automatique d'écran (OCR/accessibility service), synchronisation
multi-appareils, statuts EURL/SASU.

---

## 3. Structure du projet

```
renta_vtc/
├── pubspec.yaml
├── lib/
│   ├── main.dart                      # Point d'entrée, thème, routing
│   ├── models/
│   │   ├── driver_profile.dart        # Profil chauffeur (véhicule, conso, URSSAF)
│   │   └── ride_result.dart           # Résultat de calcul d'une course
│   ├── services/
│   │   ├── calculator_service.dart    # Logique métier pure (voir §5)
│   │   └── storage_service.dart       # Persistance locale (SharedPreferences)
│   ├── screens/
│   │   ├── home_screen.dart           # Écran principal : saisie course + résultat
│   │   └── settings_screen.dart       # Réglages : profil véhicule + statut fiscal
│   ├── widgets/                       # Composants réutilisables (à extraire au besoin)
│   └── theme/
│       └── app_theme.dart             # Couleurs, typographie (voir §6)
└── test/
    └── calculator_service_test.dart   # Tests unitaires de la logique de calcul
```

---

## 4. Modèles de données

### `DriverProfile` (stocké en local, saisi une fois)
```dart
class DriverProfile {
  final String vehicleName;          // Nom libre, informatif (ex: "Clio V")
  final double consumptionL100km;    // Consommation en L/100km
  final double fuelPricePerLiter;    // Prix du carburant en €/L
  final double urssafRate;           // Taux de cotisations, ex: 0.212 pour 21,2%
}
```

### `RideResult` (calculé à chaque course, non persisté par défaut)
```dart
class RideResult {
  final double rideKm;              // Distance de la course (hors approche)
  final double clientPrice;         // Prix payé par le client (brut, avant commission)
  final double platformPayout;      // Montant versé par la plateforme au chauffeur
  final double fuelCost;            // Coût carburant calculé
  final double urssafCost;          // Cotisations calculées
  final double net;                 // Ce qu'il reste réellement au chauffeur
}
```

---

## 5. Logique métier — règles de calcul (critique, à ne pas dévier)

### 5.1 Champs saisis par le chauffeur à chaque course
- **Distance de la course** (km) — *uniquement* la distance client (pas la distance
  d'approche vers le client, volontairement exclue du calcul).
- **Prix payé par le client** (€) — le montant brut affiché côté client, avant commission
  de la plateforme.
- **Montant versé par la plateforme** (€) — ce que le chauffeur touche réellement sur son
  compte, après commission Uber/Bolt/etc.

### 5.2 Formule de calcul
```
coût_carburant = distance_course_km × (consommation_L100km / 100) × prix_carburant_par_litre

cotisations_urssaf = prix_payé_par_le_client × taux_urssaf

net_chauffeur = montant_versé_par_la_plateforme − coût_carburant − cotisations_urssaf

commission_plateforme_euros = prix_payé_par_le_client − montant_versé_par_la_plateforme
commission_plateforme_pourcentage = commission_plateforme_euros / prix_payé_par_le_client
```
Les deux valeurs de commission (euros et %) sont dérivées automatiquement dès que les deux
prix (brut client, versé plateforme) sont saisis — pas de champ de saisie séparé pour la
commission, elle doit toujours être calculée, jamais renseignée manuellement. Afficher les
deux formats (montant en € et taux en %) dans le détail du résultat, à côté du carburant et
de l'URSSAF.

### 5.3 Point réglementaire important — ne pas modifier sans validation
Les cotisations URSSAF pour un auto-entrepreneur VTC se calculent sur le **chiffre
d'affaires brut encaissé**, c'est-à-dire le prix payé par le client, **et non** sur le
montant net reçu après commission de la plateforme (la commission n'est pas déductible
en micro-entreprise). C'est pourquoi `cotisations_urssaf` se base sur `clientPrice` et
non sur `platformPayout`. Cette règle a été vérifiée par recherche et est intentionnelle.

### 5.4 Taux applicable (valeur par défaut, modifiable dans les réglages)
- Auto-entrepreneur VTC (prestations de services, BIC) : **21,2 %** du CA brut encaissé
  (taux 2026, à vérifier périodiquement car il évolue — prévoir que ce taux soit un champ
  modifiable par l'utilisateur, pas une constante codée en dur non éditable).

### 5.5 Statuts hors scope
Ne pas implémenter EURL/SASU dans le MVP : leur mode de calcul est fondamentalement
différent (bénéfice net ou salaire du dirigeant, pas un pourcentage direct du CA par
course) et nécessiterait une refonte du modèle. Statut fixe : "auto-entrepreneur" uniquement.

---

## 6. Design system

Esthétique "tableau de bord automobile" : fond sombre pour lisibilité en voiture,
lecture rapide en un coup d'œil, chiffres façon taximètre.

### Couleurs
```dart
bg            #111318   // fond général
surface       #1B1E24   // cartes
surfaceAlt    #242830   // éléments secondaires (icônes)
divider       #31363F
amber         #F2A93B   // accent principal, CTA, saisie active
green         #6FCF97   // montant net positif (résultat)
red           #E8735A   // alertes / net négatif
textPrimary   #F4F4F0
textMuted     #8B909A
```

### Typographie
- Corps de texte / labels : **Inter** (ou police système par défaut si Inter indisponible)
- Chiffres / montants / distances : police à chasse fixe (`monospace`, idéalement
  **Space Mono**) pour un effet "compteur numérique"

### Composants clés
- **Readout** : bloc principal en haut de l'écran, affiche le net en gros caractères verts,
  avec le détail (carburant, URSSAF, commission) en dessous après calcul.
- **Formulaire** : liste de champs avec icône + label + input aligné à droite, dans une
  carte à bords arrondis (18px), séparateurs fins entre champs.
- **CTA** : bouton plein largeur, fond ambre, texte foncé, coins arrondis (16px).

Une maquette HTML de référence a été produite (`maquette-renta-vtc.html`) — s'y référer
pour le détail visuel exact des deux écrans (calcul de course, réglages).

---

## 7. Écrans

### 7.1 `HomeScreen` (écran principal)
- Barre du haut : logo app + chip véhicule actuel (tap → réglages)
- Bloc "Readout" : résultat net, détail carburant/URSSAF/commission après calcul
- Formulaire : distance course, prix client, montant versé plateforme
- Bouton "Calculer le net"
- Si le profil n'est pas configuré (`DriverProfile.isConfigured == false`), rediriger
  automatiquement vers `SettingsScreen` avant de permettre un calcul.

### 7.2 `SettingsScreen` (réglages, saisis une fois)
- Section "Véhicule" : nom, consommation (L/100km), prix carburant (€/L)
- Section "Statut fiscal" : taux URSSAF (%), pré-rempli à 21,2 % mais modifiable
- Bouton "Enregistrer le profil" → persiste via `StorageService` et retourne à l'accueil

---

## 8. Tests

Prioriser les tests unitaires sur `CalculatorService`, car une erreur de calcul a un impact
financier direct pour l'utilisateur :
- Cas nominal (valeurs positives cohérentes)
- Cas net négatif (course non rentable après charges)
- Cas valeurs à zéro (champs non remplis)
- Vérifier explicitement que `urssafCost` est calculé sur `clientPrice` et non sur
  `platformPayout` (règle métier critique, §5.3)

```bash
flutter test
```

---

## 9. Déploiement

### 9.1 Prérequis communs
```bash
flutter --version   # vérifier Flutter stable installé
flutter pub get     # installer les dépendances
flutter analyze     # vérifier qu'il n'y a pas d'erreurs de lint
flutter test        # lancer les tests unitaires
```

### 9.2 Android
1. Configurer `android/app/build.gradle` : `applicationId`, `versionCode`, `versionName`.
2. Générer une clé de signature :
   ```bash
   keytool -genkey -v -keystore renta-vtc-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias renta_vtc
   ```
3. Référencer la clé dans `android/key.properties` (ne jamais commit ce fichier).
4. Build release :
   ```bash
   flutter build appbundle --release
   ```
5. Publier le `.aab` généré (`build/app/outputs/bundle/release/`) sur la Google Play
   Console → créer une fiche store, remplir la politique de confidentialité (obligatoire
   même sans collecte de données, préciser explicitement "aucune donnée collectée").

### 9.3 iOS
1. Ouvrir `ios/Runner.xcworkspace` dans Xcode.
2. Configurer le Bundle Identifier, l'équipe de signature (compte Apple Developer requis,
   99 $/an).
3. Build release :
   ```bash
   flutter build ipa --release
   ```
4. Publier via Xcode Organizer ou `xcrun altool` vers App Store Connect.
5. Remplir la fiche App Store, y compris la section "Confidentialité des données" en
   précisant qu'aucune donnée n'est collectée ni transmise (l'app fonctionne 100% hors-ligne).

### 9.4 CI/CD (optionnel, recommandé une fois le MVP stable)
GitHub Actions avec deux jobs (`build_android`, `build_ios`) déclenchés sur push vers
`main` : `flutter pub get` → `flutter analyze` → `flutter test` → `flutter build`.
Publier les artefacts de build en pièce jointe du run, sans automatiser la publication
sur les stores dans un premier temps (validation manuelle recommandée pour un MVP).

---

## 10. Monétisation — modèle Freemium

### 10.1 Principe
- **Gratuit** : calcul ponctuel d'une course (fonctionnalité déjà spécifiée §5-7), sans
  friction, sans compte. C'est ce qui fait connaître l'app et construit la confiance.
- **Premium** (abonnement ~3€/mois, avec palier annuel 25€/an) : pilotage de l'activité
  dans la durée. Le calcul ponctuel ne doit jamais passer derrière un mur payant.
- Paiement via **in-app purchase natif** (Google Play Billing / StoreKit), pas de backend
  de paiement custom — cohérent avec la philosophie "pas de serveur" de l'app. Utiliser le
  package `in_app_purchase` (officiel Flutter) pour gérer les deux stores avec une seule API.

### 10.2 Fonctionnalités Premium à implémenter

**a) Historique des courses**
- Chaque calcul (`RideResult`) est persisté avec un horodatage si l'utilisateur est premium
- Nouveau modèle `RideEntry` : `RideResult` + `DateTime date` + `String? platformName`
  (Uber / Bolt / Heetch / Autre, saisi manuellement par le chauffeur)
- Stockage local toujours (`shared_preferences` en JSON list, ou migration vers `sqflite`
  si le volume d'entrées le justifie — à réévaluer si > quelques centaines d'entrées)

**b) Statistiques**
- Net moyen par km, net moyen par heure (nécessite une durée de course, à ajouter comme
  champ optionnel dans le formulaire de saisie)
- Total net cumulé par jour / semaine / mois
- Calculé à la volée à partir de la liste de `RideEntry`, pas de pré-agrégation nécessaire
  vu le volume de données attendu

**c) Export du chiffre d'affaires**
- Export CSV/PDF du CA brut (`clientPrice`) cumulé sur une période (trimestre par défaut,
  aligné sur la fréquence de déclaration URSSAF)
- Note produit : Uber et Bolt fournissent déjà un relevé mensuel de CA — cet export n'est
  **pas** destiné à remplacer ce relevé officiel, mais à permettre au chauffeur de
  **comparer** son propre calcul (basé sur ses saisies dans l'app) avec le relevé de la
  plateforme, et à avoir une vue consolidée si plusieurs plateformes sont utilisées.
  Le préciser explicitement dans l'UI pour éviter toute confusion sur la source de vérité
  fiscale (le relevé plateforme reste la référence officielle).

**d) Multi-véhicules**
- `DriverProfile` devient une liste de profils nommés, avec un profil actif sélectionné
- Utile pour les chauffeurs alternant entre deux véhicules

**e) Comparateur de plateformes**
- Regroupement des `RideEntry` par `platformName`, avec net moyen par plateforme sur une
  période — nécessite le champ `platformName` de 10.2.a

**f) Alerte de seuil auto-entrepreneur**
- Notification locale (pas de push serveur, juste une notification programmée côté app)
  quand le CA cumulé de l'année approche le plafond auto-entrepreneur (83 600€ en 2026,
  seuil à garder configurable car il évolue)

### 10.3 Modélisation du statut d'abonnement
```dart
class SubscriptionStatus {
  final bool isPremium;
  final DateTime? expiresAt; // null si abonnement à vie / achat unique
}
```
Stocké en local après validation du reçu d'achat via `in_app_purchase`. Prévoir une
vérification périodique du statut d'abonnement (à la reprise de l'app) plutôt qu'une
vérification serveur, toujours pour rester sans backend.

### 10.4 Continuité des données (changement de téléphone)
Décision produit : **on reste local-first, pas de backend ni de compte**, même pour gérer
le changement d'appareil. Deux filets de sécurité à implémenter, sans jamais faire
transiter de données par un serveur tiers à toi :

**a) Sauvegarde native OS (activation quasi gratuite)**
- Android : s'assurer que `android:allowBackup="true"` et `android:fullBackupContent` sont
  correctement configurés dans `AndroidManifest.xml` pour que `shared_preferences` soit
  inclus dans l'Android Auto Backup (Google Drive de l'utilisateur, pas un serveur à toi).
- iOS : s'assurer que les données stockées sont bien incluses dans la sauvegarde iCloud du
  téléphone (comportement par défaut pour `shared_preferences`/`NSUserDefaults`, à vérifier
  qu'aucun flag `NSURLIsExcludedFromBackupKey` ne l'exclut).
- Limite à documenter dans l'UI : ne fonctionne qu'en restant sur le même OS (Android→Android
  ou iOS→iOS) et si l'utilisateur a activé les sauvegardes cloud de son téléphone.

**b) Export / Import manuel (filet de sécurité cross-plateforme)**
- Écran "Sauvegarde" dans les réglages (premium) : bouton "Exporter mes données" qui génère
  un fichier JSON unique regroupant `DriverProfile` + tout l'historique `RideEntry`.
- Le fichier est partagé via le système natif (`share_plus`) : e-mail à soi-même, Drive,
  fichiers, etc. — au choix de l'utilisateur, jamais envoyé automatiquement où que ce soit.
- Bouton "Importer mes données" sur le nouvel appareil, qui lit ce fichier JSON et restaure
  l'état local. Fonctionne même en changeant d'OS (Android ↔ iOS).
- Mettre un avertissement clair et visible dans l'app : sans sauvegarde cloud OS activée et
  sans export manuel avant changement d'appareil, les données sont définitivement perdues à
  la désinstallation. Le rappeler explicitement lors de la première configuration du profil.

### 10.5 Publicité (utilisateurs non-premium uniquement)
Revenu d'appoint sur la version gratuite, en complément du modèle freemium — sert aussi
d'incitation indirecte à la conversion premium ("passe premium pour une expérience sans
publicité").

**a) Fournisseur**
- **Google AdMob** via le package Flutter officiel `google_mobile_ads` (fonctionne sur
  Android et iOS avec une seule intégration).

**b) Placement et règles de sécurité**
- Format : **bannière fixe uniquement**, en bas de `HomeScreen`. Pas d'interstitiel
  (pub plein écran), pas de pub vidéo/récompensée — l'app est utilisée en contexte de
  conduite ou entre deux courses, une interruption plein écran est inacceptable pour la
  sécurité et l'expérience utilisateur.
- La bannière ne doit jamais recouvrir ni repousser les champs de saisie du formulaire ou
  le bouton "Calculer le net" hors de la zone visible sans scroll.
- Visible uniquement si `!SubscriptionStatus.isPremium`. Masquée immédiatement et de façon
  permanente dès le passage premium (vérifier le statut à chaque affichage de `HomeScreen`,
  pas seulement au démarrage de l'app).

**c) Conformité et confidentialité**
- AdMob collecte un identifiant publicitaire à des fins de ciblage : mettre à jour la
  politique de confidentialité de l'app pour le mentionner explicitement, en le distinguant
  clairement des données métier (qui, elles, restent 100% locales et non collectées).
  Formulation suggérée : "Aucune donnée relative à ton activité (courses, revenus, véhicule)
  n'est collectée ni transmise. La version gratuite affiche des publicités fournies par
  Google AdMob, qui peut utiliser un identifiant publicitaire à des fins de ciblage."
- Gérer le consentement RGPD via le **Google User Messaging Platform (UMP) SDK**, requis
  pour tout affichage AdMob auprès d'utilisateurs dans l'UE — à intégrer avant toute
  première requête publicitaire.

---

## 11. Roadmap (hors MVP et hors premium §10, à ne pas implémenter sans demande explicite)

- Statuts EURL / SASU avec logique de calcul dédiée
- Lecture automatique des propositions de course via accessibility service (Android
  uniquement, iOS ne le permet pas)
- Mise à jour automatique du taux URSSAF via une source externe

---

## 12. Conventions de code

- Dart/Flutter : suivre `flutter_lints` par défaut, pas de désactivation de règles sans
  justification en commentaire.
- Toute logique de calcul reste dans `services/`, jamais directement dans les widgets
  d'écran (`screens/`), pour rester testable indépendamment de l'UI.
- Les montants sont des `double`, jamais des `String` parsés à la volée dans l'UI sans
  passer par une fonction de parsing centralisée (gestion virgule/point français).
- Pas de dépendance ajoutée sans raison explicite — l'app doit rester légère (pas de
  backend, pas de compte, philosophie "local-first").
