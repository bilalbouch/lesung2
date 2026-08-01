# Lesung — archive complète du projet

Deux packages :

- `lesung/` — moteur pur Dart (recherche, sources, téléchargements,
  bibliothèque, lecteur). Tests : `dart test` (185 tests).
- `lesung_app/` — application Flutter (design system, écrans).
  Analyse : `flutter analyze`. Dépendance locale `../lesung`.

## Restauration

```bash
cd lesung && dart pub get && dart test
cd ../lesung_app && flutter pub get && flutter analyze
```

Aucune dépendance secrète, aucune clé embarquée.
