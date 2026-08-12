# Monitoring App — Login Frontend

A fully functioning (mocked) login screen, built to match your Figma design,
structured so the backend (Supabase) can be dropped in later without
touching the UI.

## Folder structure

```
lib/
  main.dart                     -> app entry point, stays tiny forever
  theme/
    app_colors.dart             -> every color used in the app
    app_text_styles.dart        -> Manrope (titles) + Work Sans (everything else)
    app_theme.dart               -> combines colors/fonts into a Flutter theme
  screens/
    login_screen.dart           -> pure UI, no logic
  widgets/
    custom_text_field.dart      -> reusable input box
    custom_button.dart          -> reusable pill button
  controllers/
    login_controller.dart       -> "frontend logic": form state, validation, loading
  services/
    auth_service.dart           -> "backend logic": currently MOCKED, will call Supabase later
```

**Why split it like this?**
- `screens/` only ever answers "what does it look like?"
- `controllers/` only ever answers "what should happen when the user does X?"
- `services/` only ever answers "how do I talk to the backend?"

When you're ready to connect Supabase, you will **only** edit `auth_service.dart`.
Nothing in `login_screen.dart` or `login_controller.dart` needs to change.

## How to run this in VS Code

1. Install the **Flutter** and **Dart** extensions in VS Code (Extensions panel, search "Flutter").
2. Make sure the Flutter SDK is installed on your machine. Check with:
   ```
   flutter doctor
   ```
   If it's not installed, follow: https://docs.flutter.dev/get-started/install
3. Copy this whole `monitoring_app` folder wherever you keep your projects, then open that folder in VS Code (`File > Open Folder`).
4. Open a terminal in VS Code (`Terminal > New Terminal`) and run:
   ```
   flutter pub get
   ```
   This downloads the `google_fonts` package listed in `pubspec.yaml`.
5. Run the app:
   - Press `F5`, or
   - In the terminal: `flutter run -d chrome` (fastest way to preview a "website" build), or
   - `flutter run` to pick a connected device/emulator from a list.

## What's mocked right now

`auth_service.dart` doesn't call any real backend yet — it just waits 1 second
and returns a fake success/failure so you can see the loading spinner and
error messages working. Look for the `TODO` comments in that file; that's
exactly where the Supabase calls will go later.

## Next steps (when you're ready)

1. Add `supabase_flutter` to `pubspec.yaml` (already commented out, just uncomment it).
2. Initialize Supabase in `main.dart`.
3. Replace the mock logic inside `auth_service.dart` with real
   `Supabase.instance.client.auth.signInWithPassword(...)` calls.
4. Everything else in the app stays the same.
