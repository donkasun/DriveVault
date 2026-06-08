# DriveVault Mobile (Flutter)

Flutter app for DriveVault. See `../docs/01-tech-spec.md` for architecture and
`../docs/03-api-contract.md` for the backend API.

## Requirements
- Flutter 3.44.x (Dart 3.12.x)
- Xcode (iOS) and/or Android Studio + `cmdline-tools` (Android)

## Run

```bash
cd mobile
flutter pub get

# API base URL is injected at build time (never hard-coded).
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

## Test / analyze
```bash
flutter test
flutter analyze
```

## Structure (per docs/01-tech-spec.md §3)
```
lib/
  main.dart                 # ProviderScope + MaterialApp.router
  core/
    config/                 # AppConfig (API base URL via --dart-define)
    theme/                  # AppTheme
    router/                 # go_router (auth gate added in C2)
    network/                # API client (added in C3)
  features/<feature>/
    data/                   # repository + api (only layer that calls the API)
    domain/                 # models
    presentation/           # screens, providers, widgets
  shared/                   # reusable widgets, models, utils
```

## Build status
- ✅ C1 — scaffold: feature folders, deps, theme, go_router, dashboard shell (analyze clean, test passing)
- ⬜ next: C2 (Firebase init + Auth), C3 (API client) … see `../docs/04-phase1-tasks.md`

> Firebase is **not** initialized yet — Task C2 runs `flutterfire configure` to generate
> `firebase_options.dart` (gitignored) and wires `Firebase.initializeApp()`.
