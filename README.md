# Baseball Score — Application de Marquage de Baseball

Application mobile Flutter cross-platform (iOS & Android) permettant de marquer des parties de baseball en temps réel, gérer des équipes, suivre les statistiques et planifier un calendrier de saison.

---

## Table des matières

1. [Fonctionnalités](#fonctionnalités)
2. [Installation et configuration](#installation-et-configuration)
3. [Structure du projet](#structure-du-projet)
4. [Guide d'utilisation](#guide-dutilisation)
   - [Tableau de bord](#tableau-de-bord)
   - [Créer et gérer des équipes](#créer-et-gérer-des-équipes)
   - [Démarrer une partie](#démarrer-une-partie)
   - [Marquer une partie en direct](#marquer-une-partie-en-direct)
   - [Historique des matchs](#historique-des-matchs)
   - [Statistiques](#statistiques)
   - [Calendrier](#calendrier)
5. [Configuration Google AdMob](#configuration-google-admob)
6. [Publier sur les stores](#publier-sur-les-stores)
7. [Symboles de baseball utilisés](#symboles-de-baseball-utilisés)

---

## Fonctionnalités

| Fonctionnalité | Description |
|---|---|
| **Score en direct** | Marquer chaque présence au bâton en temps réel |
| **Tableau de pointage** | Vue complète manche par manche (R-H-E) |
| **Losange interactif** | Visualiser les coureurs sur les buts |
| **Compteur de balles/prises** | Décompte du compte pour chaque frappeur |
| **Gestion d'équipes** | Créer, modifier et supprimer des équipes |
| **Gestion de joueurs** | Ajouter des joueurs avec numéro et position |
| **Ordre de frappe** | Organiser l'alignement par glisser-déposer |
| **Historique des matchs** | Consulter tous les matchs terminés |
| **Statistiques** | Classement des équipes et stats des frappeurs |
| **Calendrier** | Planifier les matchs de la saison avec vue calendrier |
| **Publicité** | Petite bannière discrète Google AdMob (320×50) |
| **Mode sombre** | Support automatique du thème clair/sombre |
| **Stockage local** | Toutes les données sauvegardées localement (SQLite) |

---

## Installation et configuration

### Prérequis

- [Flutter SDK](https://flutter.dev/docs/get-started/install) — version 3.19+
- [Dart SDK](https://dart.dev) — version 3.3+
- Android Studio ou Xcode (selon la plateforme cible)
- Un compte [Google AdMob](https://admob.google.com) (pour la publicité)

### Étapes d'installation

```bash
# 1. Cloner le dépôt
git clone https://github.com/jogagnon20/baseball_app.git
cd baseball_app

# 2. Installer les dépendances
flutter pub get

# 3. Lancer l'application en mode développement
flutter run
```

### Variables à configurer avant publication

Avant de publier l'application, vous devez remplacer les identifiants de test AdMob par vos vrais identifiants.

**Android** — `android/app/src/main/AndroidManifest.xml` :
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
```

**iOS** — `ios/Runner/Info.plist` :
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>
```

**Bannière** — `lib/widgets/ad_banner_widget.dart` :
```dart
static const String _adUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
```

---

## Structure du projet

```
lib/
├── main.dart                        # Point d'entrée de l'application
├── models/
│   ├── player.dart                  # Modèle Joueur
│   ├── team.dart                    # Modèle Équipe
│   ├── game.dart                    # Modèle Partie (avec InningScore)
│   ├── at_bat.dart                  # Modèle Présence au bâton + résultats
│   ├── schedule_event.dart          # Modèle Événement calendrier
│   └── player_stats.dart            # Modèles Stats joueur et équipe
├── database/
│   └── database_helper.dart         # Gestion SQLite (CRUD)
├── providers/
│   ├── team_provider.dart           # État: équipes et joueurs
│   ├── game_provider.dart           # État: parties en cours et historique
│   ├── schedule_provider.dart       # État: calendrier
│   └── stats_provider.dart          # Calcul des statistiques
├── screens/
│   ├── home_screen.dart             # Tableau de bord principal
│   ├── game/
│   │   ├── new_game_screen.dart     # Création d'une nouvelle partie
│   │   ├── live_scoring_screen.dart # Marquage en temps réel
│   │   ├── game_history_screen.dart # Liste des matchs
│   │   └── game_detail_screen.dart  # Détails d'un match terminé
│   ├── teams/
│   │   ├── teams_screen.dart        # Liste des équipes
│   │   └── team_detail_screen.dart  # Joueurs d'une équipe
│   ├── stats/
│   │   └── stats_screen.dart        # Statistiques (classement + frappeurs)
│   └── schedule/
│       └── schedule_screen.dart     # Calendrier de la saison
└── widgets/
    ├── ad_banner_widget.dart        # Bannière publicitaire AdMob
    ├── scoreboard_widget.dart       # Tableau de pointage par manche
    └── base_diamond_widget.dart     # Losange de baseball avec coureurs
```

---

## Guide d'utilisation

### Tableau de bord

L'écran d'accueil affiche :

- **Parties en cours** — Appuyez sur une carte pour reprendre le marquage
- **Actions rapides** — Accès direct à Nouvelle partie, Historique, Équipes, Calendrier
- **Résumé de la saison** — Nombre de matchs joués et d'équipes enregistrées

La **petite bannière publicitaire** (320×50) apparaît discrètement en bas de l'écran, au-dessus de la barre de navigation. Elle ne bloque jamais l'interface.

---

### Créer et gérer des équipes

#### Créer une équipe

1. Aller dans l'onglet **Équipes** ou appuyer sur "Équipes" depuis l'accueil
2. Appuyer sur le bouton **+** (en haut à droite ou FAB en bas)
3. Remplir :
   - **Ville** (ex: Montréal)
   - **Nom** (ex: Royaux)
   - **Couleur** — choisir parmi les 8 couleurs disponibles
4. Appuyer sur **Créer**

#### Modifier ou supprimer une équipe

- Utiliser le menu **⋮** sur la carte de l'équipe
- Sélectionner **Modifier** ou **Supprimer**

> **Attention** : La suppression d'une équipe supprime également tous ses joueurs.

#### Ajouter des joueurs

1. Appuyer sur une équipe pour voir sa liste de joueurs
2. Appuyer sur **Ajouter joueur** ou le bouton **+**
3. Remplir :
   - **Nom complet**
   - **Numéro de chandail** (0–99)
   - **Position** (P, C, 1B, 2B, 3B, SS, LF, CF, RF, DH, UT)
4. Appuyer sur **Ajouter**

#### Positions disponibles

| Abréviation | Position |
|---|---|
| P | Lanceur |
| C | Receveur |
| 1B | Premier but |
| 2B | Deuxième but |
| 3B | Troisième but |
| SS | Arrêt-court |
| LF | Champ gauche |
| CF | Champ centre |
| RF | Champ droit |
| DH | Frappeur désigné |
| UT | Utilitaire |

---

### Démarrer une partie

1. Appuyer sur **Nouvelle partie** depuis l'accueil
2. Sélectionner l'équipe **Visiteurs** et l'équipe **Locaux**
3. L'ordre de frappe se génère automatiquement selon la liste des joueurs
   - **Réorganiser** l'ordre en glissant les lignes
4. Choisir la **date** et l'**heure** du match
5. Saisir l'**emplacement** (ex: Parc Jarry — Terrain 1)
6. Choisir le nombre de **manches** (7 ou 9)
7. Appuyer sur **Commencer la partie**

---

### Marquer une partie en direct

L'écran de marquage est divisé en plusieurs zones :

#### 1. Tableau de pointage (haut de l'écran)
Affiche le score manche par manche avec les totaux R-H-E pour les deux équipes. La manche active est surlignée en bleu.

#### 2. Carte de situation
Montre :
- La demi-manche en cours (ex: Haut de la 3e manche)
- L'équipe qui frappe
- Le **frappeur actuel** avec son numéro et sa position
- Le score en temps réel

#### 3. Losange et retraits
- **Losange** : les buts en jaune indiquent un coureur présent
- **Retraits** : cercles rouges (0, 1 ou 2 retraits)
- **Boutons de buts** (3B, 2B, 1B) : corriger la position des coureurs manuellement

#### 4. Compteurs (appuyer pour incrémenter, cycle automatique)
- **Balles** (0–4)
- **Prises** (0–3)
- **RBI** — Points produits (0–4)
- **Points marqués** (0–4)

#### 5. Résultats de la présence

| Groupe | Boutons disponibles |
|---|---|
| **Coups sûrs** | 1B, 2B, 3B, HR |
| **Retraits** | K, KL, GO, FO, LO, DP |
| **Sur les buts** | BB, HBP, IBB, FC, E, SAC |

Appuyer sur un résultat **enregistre immédiatement la présence** et passe automatiquement au frappeur suivant.

#### 6. Note optionnelle
Saisir une note textuelle libre pour la présence (ex: "Balle dure en coin droit").

#### Actions avancées (menu ⋮)
- **Erreur — Local** : Ajouter une erreur à l'équipe locale
- **Erreur — Visiteur** : Ajouter une erreur à l'équipe visiteuse
- **Terminer la partie** : Conclure le match manuellement à tout moment

#### Annuler la dernière action
Appuyer sur l'icône **↩** pour annuler la dernière présence enregistrée.

#### Fin automatique de partie
Lorsque toutes les manches prévues sont complétées et qu'une équipe mène, l'application propose de terminer la partie.

---

### Historique des matchs

L'onglet **Matchs** affiche tous les matchs enregistrés.

- **Badge vert "EN COURS"** : Appuyer pour reprendre le marquage
- **Badge gris "TERMINÉ"** : Appuyer pour voir le détail complet
- **Menu ⋮** : Supprimer un match

#### Détail d'un match terminé

Trois onglets :
1. **Résumé** — Score final, tableau manche par manche, comparaison R-H-E
2. **Visiteurs** — Liste de toutes les présences au bâton par manche
3. **Locaux** — Liste de toutes les présences au bâton par manche

---

### Statistiques

L'onglet **Stats** calcule automatiquement les statistiques de tous les matchs **terminés**.

Appuyer sur **↺** pour recalculer après de nouveaux matchs.

#### Classement des équipes

| Colonne | Signification |
|---|---|
| PJ | Parties jouées |
| V | Victoires |
| D | Défaites |
| PCT | Pourcentage de victoires |
| R+ | Points marqués |
| R- | Points accordés |
| DF | Différentiel de points |

#### Statistiques des frappeurs

Triées par moyenne au bâton (décroissant).

| Colonne | Signification |
|---|---|
| PA | Présences totales au bâton |
| AB | Tours au bâton officiels |
| H | Coups sûrs |
| HR | Coups de circuit |
| RBI | Points produits |
| AVG | Moyenne au bâton |
| OBP | Taux de présence sur les buts |

> Les joueurs avec une moyenne de **.300 ou plus** s'affichent en vert.

---

### Calendrier

L'onglet **Calendrier** permet de planifier et visualiser les matchs de toute la saison.

#### Ajouter un match au calendrier

1. Appuyer sur **+** ou sur une date dans le calendrier puis sur "Ajouter un match"
2. Remplir :
   - **Équipes** (visiteurs et locaux)
   - **Date** et **heure**
   - **Emplacement**
   - **Notes** (optionnel — ex: "Saison régulière, match no 5")
3. Appuyer sur **Ajouter**

Les jours avec des matchs planifiés affichent un **point jaune** sous la date dans le calendrier.

Appuyer sur une date pour voir les matchs de ce jour-là dans la liste en dessous.

#### Modifier ou supprimer un événement
Utiliser le menu **⋮** sur la carte de l'événement.

Les matchs passés apparaissent légèrement estompés pour distinguer l'historique des prochains matchs.

---

## Configuration Google AdMob

### Étape 1 : Créer un compte AdMob

1. Aller sur [admob.google.com](https://admob.google.com)
2. Se connecter avec un compte Google
3. Créer une **nouvelle application** (une fois pour Android, une fois pour iOS)

### Étape 2 : Obtenir vos identifiants

Pour chaque plateforme :
- **App ID** : Format `ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX`
- **Ad Unit ID** (pour la bannière) : Format `ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX`

### Étape 3 : Remplacer les IDs de test

Les identifiants actuels sont des **IDs de test Google** qui ne génèrent aucun revenu. Les remplacer avant publication :

| Fichier | Clé à modifier |
|---|---|
| `android/app/src/main/AndroidManifest.xml` | `android:value` dans `APPLICATION_ID` |
| `ios/Runner/Info.plist` | `GADApplicationIdentifier` |
| `lib/widgets/ad_banner_widget.dart` | `_adUnitId` |

> **Important** : Conservez les IDs de test pendant le développement pour éviter toute violation des politiques AdMob.

### Type de publicité

La bannière **320×50** (`AdSize.banner`) est le format le plus discret d'AdMob :
- Positionnée en bas de chaque écran
- Au-dessus de la barre de navigation
- Ne bloque jamais l'interface
- Aucune vidéo, aucun popup
- Disparaît si la publicité ne charge pas (pas de rectangle vide)

---

## Publier sur les stores

### Google Play Store (Android)

```bash
# Générer le bundle Android signé
flutter build appbundle --release

# Fichier généré:
# build/app/outputs/bundle/release/app-release.aab
```

Étapes :
1. Créer un compte [Google Play Console](https://play.google.com/console) (25$ unique)
2. Créer une nouvelle application
3. Téléverser le fichier `.aab`
4. Remplir les métadonnées (description, captures d'écran, icône)
5. Configurer la **politique de confidentialité** (obligatoire avec des pubs)
6. Soumettre pour révision (généralement 1–3 jours)

### Apple App Store (iOS)

```bash
# Compiler pour iOS (nécessite macOS + Xcode)
flutter build ios --release

# Ouvrir dans Xcode
open ios/Runner.xcworkspace
```

Étapes :
1. Créer un compte [Apple Developer Program](https://developer.apple.com) (99$/an)
2. Configurer le Bundle Identifier et les certificats de signature dans Xcode
3. Archiver l'application (Product > Archive)
4. Uploader via Xcode Organizer ou Transporter
5. Soumettre via [App Store Connect](https://appstoreconnect.apple.com)
6. Attendre la révision d'Apple (1–7 jours)

---

## Symboles de baseball utilisés

| Symbole | Signification |
|---|---|
| 1B | Coup sûr simple |
| 2B | Double |
| 3B | Triple |
| HR | Coup de circuit (Home Run) |
| K | Retrait sur prises (Strikeout swinging) |
| KL | Retrait sur prises regardé (Strikeout looking) |
| BB | But sur balles (Walk) |
| HBP | Frappé par le lancer (Hit By Pitch) |
| IBB | But sur balles intentionnel |
| SAC | Coup sacrifice |
| FC | Choix du défenseur (Fielder's Choice) |
| GO | Retrait au sol (Ground Out) |
| FO | Retrait en chandelle (Fly Out) |
| LO | Retrait en flèche (Line Out) |
| DP | Double jeu (Double Play) |
| E | Erreur |
| R | Points (Runs) |
| H | Coups sûrs (Hits) |
| RBI | Points produits (Runs Batted In) |
| AVG | Moyenne au bâton |
| OBP | Taux de présence sur les buts (On-Base Percentage) |
| SLG | Pourcentage de puissance (Slugging Percentage) |
| OPS | OBP + SLG |
| ▲ | Haut de la manche (visiteurs au bâton) |
| ▼ | Bas de la manche (locaux au bâton) |

---

## Technologies utilisées

| Package | Version | Usage |
|---|---|---|
| `flutter` | SDK 3.19+ | Framework UI cross-platform |
| `sqflite` | ^2.3.2 | Base de données SQLite locale |
| `provider` | ^6.1.2 | Gestion d'état réactive |
| `google_mobile_ads` | ^5.1.0 | Bannières publicitaires AdMob |
| `table_calendar` | ^3.1.2 | Vue calendrier mensuelle |
| `intl` | ^0.19.0 | Formatage des dates en français |
| `uuid` | ^4.4.0 | Génération d'identifiants uniques |
| `path` | ^1.9.0 | Gestion des chemins de fichiers |

---

## Licence

Ce projet est développé à des fins personnelles et pour une ligue amateur. Tous droits réservés.
