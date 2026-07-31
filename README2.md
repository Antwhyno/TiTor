# Organizer App

Application Flutter d'organisation par **boîtes** colorées, regroupables en
**groupes**, chacune disposant d'un **chronomètre/alarme** dont la durée
dépend de sa couleur.

## Fonctionnalités

1. Création de boîtes représentées par une icône (choisie dans un catalogue).
2. Changement de couleur (Rouge / Vert / Jaune) et modification d'une boîte
   existante (nom, icône, groupe).
3. Création de groupes de boîtes.
4. Chaque boîte possède un chronomètre dont la durée dépend de sa couleur :
   - 🔴 Rouge : 1 jour
   - 🟡 Jaune : 7 jours
   - 🟢 Vert : 14 jours
5. Gestion des cas limites et erreurs (réseau absent, données nulles ou
   corrompues, éléments introuvables, suppression sans perte de données).

## Installation

Ce dépôt contient uniquement le dossier `lib/` et le `pubspec.yaml`. Pour
l'exécuter :

```bash
flutter create organizer_app_shell
cd organizer_app_shell
rm -rf lib
cp -r /chemin/vers/organizer_app/lib .
cp /chemin/vers/organizer_app/pubspec.yaml .
flutter pub get
flutter run --no-tree-shake-icons
```

> ⚠️ Le drapeau `--no-tree-shake-icons` est nécessaire car les icônes des
> boîtes sont stockées par `codePoint` et reconstruites dynamiquement à
> l'exécution (voir section "Choix techniques notables" ci-dessous).

## Architecture générale

L'application suit une architecture en couches strictement séparées,
combinant le pattern **BLoC** (gestion d'état), une couche **Repository**
(accès aux données) et une **programmation orientée objet classique**
(modèles immuables, exceptions typées).

```
lib/
├── models/         Modèles métier (POO), immuables
├── data/           Accès aux données (Repository + SQLite) et exceptions
├── blocs/          Gestion d'état (BLoC) : events / states / bloc
├── screens/        Écrans (pages complètes)
├── widgets/        Composants UI réutilisables
├── utils/          Utilitaires transverses (réseau, catalogue d'icônes)
└── main.dart       Point d'entrée et injection des BlocProvider
```

### 1. Couche `models/`

- `BoxColorType` : énumération Rouge/Vert/Jaune. Une *extension* associe à
  chaque couleur sa durée de chronomètre, sa couleur d'affichage et son
  libellé. Centraliser cette correspondance dans le modèle évite de
  dupliquer la règle métier "couleur → durée" dans l'UI.
- `BoxModel` : entité immuable (`@immutable`, tous les champs `final`).
  Fournit `copyWith`, `toMap`/`fromMap` (persistance) et une méthode
  `withColor` qui recalcule automatiquement la date d'expiration.
- `BoxGroupModel` : entité immuable représentant un groupe.

### 2. Couche `data/` (accès aux données)

- `DatabaseHelper` : encapsule l'ouverture et la structure de la base
  SQLite (deux tables : `boxes` et `groups`, avec une clé étrangère
  `ON DELETE SET NULL` pour ne jamais perdre une boîte si son groupe
  disparaît).
- `BoxRepository` / `GroupRepository` : exposent des méthodes métier
  (`fetchAll`, `insert`, `update`, `delete`, `changeColor`,
  `detachFromGroup`...) et **traduisent systématiquement** les exceptions
  techniques (`DatabaseException`, `FormatException`) en exceptions métier
  explicites (`app_exceptions.dart`), afin que les couches supérieures ne
  manipulent jamais d'erreurs bas-niveau.
- `NetworkInfo` : abstraction simple de la connectivité (via `dart:io`,
  sans dépendance supplémentaire), utilisée par
  `BoxRepository.syncWithRemote` pour illustrer la gestion du cas
  "absence de réseau" (l'application fonctionne entièrement hors-ligne ;
  ce point d'entrée est prêt pour une future synchronisation via `http`).

### 3. Couche `blocs/` (BLoC)

Deux BLoC indépendants, chacun avec son triptyque `event` / `state` / `bloc` :

- **`BoxBloc`** : `LoadBoxes`, `AddBoxRequested`, `UpdateBoxRequested`,
  `ChangeBoxColorRequested`, `DeleteBoxRequested` → états `BoxInitial`,
  `BoxLoading`, `BoxLoaded`, `BoxError`.
- **`GroupBloc`** : `LoadGroups`, `AddGroupRequested`,
  `UpdateGroupRequested`, `DeleteGroupRequested` → états `GroupInitial`,
  `GroupLoading`, `GroupLoaded`, `GroupError`.

Chaque état d'erreur conserve la **dernière liste connue** (`previousBoxes`
/ `previousGroups`) : en cas d'erreur, l'utilisateur voit toujours ses
données précédentes à l'écran, accompagnées d'un message d'erreur (snackbar),
plutôt qu'un écran vidé brutalement.

La suppression d'un groupe déclenche d'abord `detachFromGroup` (les boîtes
deviennent "sans groupe") **avant** la suppression du groupe : aucune boîte
n'est jamais supprimée involontairement.

### 4. Couches `screens/` et `widgets/`

- `HomeScreen` : deux onglets (Boîtes sans groupe / Groupes), écoute les
  deux BLoC via `BlocListener` imbriqués pour afficher les erreurs.
- `AddEditBoxScreen` : formulaire unique pour créer **et** modifier une
  boîte (mode déterminé par la présence de `existingBox`).
- `BoxDetailScreen` / `GroupDetailScreen` : détail et actions
  (modifier/supprimer une boîte, changer sa couleur en direct).
- Les `widgets/` (cartes, sélecteurs, dialogues, état vide) sont purement
  présentatifs et ne connaissent aucun BLoC directement : ils reçoivent des
  callbacks, ce qui les rend testables et réutilisables indépendamment.

Chaque BLoC est fourni une seule fois à la racine (`main.dart`) et
transmis explicitement (`BlocProvider.value`) aux écrans poussés par
`Navigator`, afin de conserver une **source unique de vérité** pour les
données pendant toute la navigation.

### 5. Gestion des erreurs et cas limites

- **Données nulles/corrompues** : `BoxModel.fromMap` / `BoxGroupModel.fromMap`
  vérifient les champs obligatoires et lèvent une `FormatException` claire ;
  les champs secondaires (icône, dates) reçoivent des valeurs par défaut
  sûres plutôt que de faire planter l'application.
- **Absence de réseau** : `NetworkInfo` + `NoNetworkException`.
- **Éléments introuvables** : `NotFoundException` (ex : modifier une boîte
  supprimée entre-temps depuis un autre écran).
- **Formulaires** : validation systématique des noms (vide, longueur
  maximale) avant tout appel réseau/BDD.
- **Cohérence UI/données** : `GroupSelectorField` vérifie que le groupe
  sélectionné existe toujours avant de l'afficher, pour éviter une valeur
  orpheline dans un menu déroulant.

## Choix techniques notables

- **Icônes** : un catalogue fermé (`IconCatalog`) est proposé plutôt qu'un
  choix libre, afin de garder une expérience cohérente. Les icônes sont
  stockées par `codePoint`/`fontFamily` en base et reconstruites à
  l'affichage, ce qui impose de compiler avec `--no-tree-shake-icons`.
- **Recalcul du chronomètre à la création vs au changement de couleur** :
  à la création, l'expiration est calculée depuis la date de création.
  Lors d'un **changement manuel de couleur**, l'expiration est recalculée
  à partir de l'instant du changement (et non de la création initiale),
  ce qui correspond au comportement attendu (ex : faire passer une boîte
  au rouge redémarre bien un délai de 1 jour à partir de maintenant).
- **`http` dans les dépendances** : présent mais non utilisé pour
  l'instant ; réservé à une future synchronisation distante
  (`BoxRepository.syncWithRemote`), l'application étant conçue pour
  fonctionner entièrement hors-ligne via `sqflite`.
- **Cible de la persistance** : `sqflite` cible Android/iOS. Pour un
  déploiement desktop ou web, il faudrait substituer respectivement
  `sqflite_common_ffi` ou `sqflite_common_ffi_web` dans
  `DatabaseHelper`.

## Évolutions futures possibles

- Notifications système (via `flutter_local_notifications`) lorsqu'une
  boîte expire, en complément du compte à rebours visuel actuel.
- Synchronisation distante réelle via `http` (le point d'entrée
  `syncWithRemote` est déjà prêt).
- Tri/filtrage des boîtes par couleur ou par échéance.
