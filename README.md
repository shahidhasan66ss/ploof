# ChatPop

**ChatPop** is an offline-first Flutter app for making playful, clearly fictional chat stories, reactions and prank-style creative content. It is an original product implementation—not a clone of any messaging or sticker product.

> Created for fictional entertainment and creative content. Do not use generated conversations to mislead, impersonate, defraud, or harm others.

## What is included

- Material 3 light, dark and system themes
- Bottom navigation: Home, Templates, My Creations and Settings, with a central Create action
- 25 original, local-only starter templates across Funny, Prank, Friends, Family, School, Relationship, Group Chat, Awkward, Roast and Chaos
- Instant local template search and category filters
- Fictional participant editor (name, initials, avatar color)
- Chat editor with text messages, incoming/outgoing sides, timestamp/status editing, typing indicators, locally selected image messages, reactions, sticker shelf, styles, drag reordering, move controls, undo and redo
- Ten original chat visual styles
- Shared `ChatRenderer` visual components for the editor, preview, gallery thumbnails, and exports
- PNG and JPG export at square (1080×1080), portrait (1080×1350), and story (1080×1920) sizes
- Platform share sheet via `share_plus`
- File-per-project local JSON gallery—no database, authentication, server, Firebase, Supabase, cloud sync, or AI
- Original ChatPop launcher icon concept and Android 12 splash treatment
- Unit and widget coverage for serialization, template filtering, history behavior, and chat rendering

## Run locally

Install a current stable Flutter SDK (Dart SDK `>=3.4.0`) and then run:

```bash
flutter pub get
flutter run
```

This repository was assembled in an environment where the Flutter SDK was not installed, so runtime validation must be run from a Flutter-equipped machine or CI. The sandbox also did not contain Gradle's binary wrapper JAR; if your Flutter install does not restore it during setup, run the following once before building to regenerate platform wrapper files (it preserves `lib/`):

```bash
flutter create --platforms=android,ios .
flutter pub get
flutter analyze
flutter test
flutter build apk --release
# On macOS with Xcode configured:
flutter build ios --release
```

## Architecture

The app follows a feature-oriented structure under `lib/`:

```text
lib/
  app/                    # MaterialApp, GoRouter, global design theme
  core/                   # central constants and platform-safe services
  features/
    home/                 # first-use dashboard
    templates/            # typed local catalog and local filters
    editor/               # project models, snapshot history, renderer, editor UI
    stickers/             # typed local sticker catalog
    creations/            # JSON/file storage and gallery state
    export/               # capture, local file output and share service
    settings/             # lightweight preference state
    about/                # safety, privacy and terms copy
```

### State and routing

- **Riverpod** separates catalog, editor, settings, and local creations state.
- **GoRouter** supports `/`, `/templates`, `/templates/:id`, `/create`, `/create/:templateId`, `/preview`, `/creations`, `/creations/:id`, `/settings`, and `/about`.
- The editor uses capped immutable project snapshots for undo/redo. It is intentionally isolated from the gallery and app settings providers.

### Storage and privacy

`CreationStorageService` writes one JSON document per project to the app documents directory:

```text
<application documents>/chatpop_creations/<project-id>.json
<application documents>/chatpop_exports/chatpop-<timestamp>-<uuid>.png|jpg
```

Large image bytes are never embedded in project JSON. Image messages reference local paths. Exports remain in app storage and are passed to the platform share sheet only when the user chooses Share. Nothing is uploaded.

## Extend content safely

### Add a template

1. Add a typed `ChatTemplate` entry to `lib/features/templates/data/built_in_templates.dart`.
2. Use fictional, harmless prompt text; avoid financial, legal, emergency, medical or real-person evidence scenarios.
3. Provide a category, original description, theme ID, fictional participants and `TemplateMessageSeed` list.
4. The catalog, search, preview and editor will pick it up automatically.

### Add a sticker

Add a `StickerItem` in `lib/features/stickers/data/sticker_catalog.dart`. The starter shelf uses compact emoji-led, original labels so it works fully offline. The typed `StickerItem` model can later gain an optional local SVG/PNG asset field without changing editor state.

### Add a chat style

Add a `ChatThemeStyle` to `lib/features/editor/models/chat_theme.dart`. Supply every visual token: background, surface, incoming/outgoing bubbles, text colors, header, timestamps and reaction surface. `ChatRenderer` applies new styles consistently in editing and export.

### Change the app name

Change the single `AppConstants.appName` value in `lib/core/constants/app_constants.dart`, then update the platform labels in:

- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

## Icons and platform release setup

- The Android vector launcher icon lives in `android/app/src/main/res/drawable/ic_launcher.xml` and is paired with a small original splash.
- iOS app icon files live in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`.
- Before store submission, replace the debug signing configuration in `android/app/build.gradle` with your signed release configuration and set the iOS Team/bundle identifier in Xcode.

## Future integrations (not enabled)

`core/services/monetization_services.dart` provides `SubscriptionService` and `AdsService` interfaces with disabled implementations. A future RevenueCat or AdMob adapter can be wired behind those interfaces without coupling ads/purchases to editing, templates, or offline creation. No fake purchase state is used in this app.

## Permissions

ChatPop does not ask for permissions on launch. The system photo picker is invoked only when a user presses **Media**. iOS includes a focused photo-library explanation. Android uses modern scoped storage behavior; exported files are saved app-locally and shared through the system sheet without broad storage permissions.
