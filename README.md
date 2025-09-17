
# 5M Stress Relief (Flutter + Firebase) — Prototype

A hackathon-ready prototype for your **5M framework**:
- **Mood**: Emoji-based mood + AI-styled chat
- **Match**: Tinder-like swipe to find peers with similar mood
- **Material**: Roadmap/timeline to reduce stress
- **Maps**: Nearby doctors, yoga teachers, psychologists
- **Mission**: Mini tasks (yoga, walk, diet) with progress

> ⚠️ This ZIP ships without the heavy `android/` and `ios/` folders.
> Generate them once with Flutter:

```bash
flutter create .
flutter pub get
flutter run
```

## Firebase Setup (quick)
1. Create a Firebase project.
2. Enable **Authentication** (Email/Password + Anonymous).
3. Enable **Cloud Firestore** (test mode for demo).
4. Download `google-services.json` → place at `android/app/`.
5. Download `GoogleService-Info.plist` → place at `ios/Runner/`.
6. Update your `applicationId`/`bundleId` in the Firebase console if needed.

This app **will still run without Firebase** in *mock mode*. When Firebase init fails, it uses local in-memory data for demo.

## Maps
- Add an Android Maps API key in `AndroidManifest.xml` after running `flutter create .`.
- iOS requires adding the key in `AppDelegate` Info.plist.

## Structure
```
lib/
  main.dart
  theme.dart
  services/
    firebase_service.dart
  screens/
    login_screen.dart
    details_screen.dart
    home_screen.dart
    mood_screen.dart
    match_screen.dart
    material_screen.dart
    maps_screen.dart
    mission_screen.dart
    chat_screen.dart
  widgets/
    mood_emoji_picker.dart
    mission_task_tile.dart
```
