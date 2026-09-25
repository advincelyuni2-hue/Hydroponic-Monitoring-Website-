# Monitoring App - Login Frontend

A Flutter login and signup frontend for the hydroponic monitoring application.
Authentication is wired for Supabase, including email OTP verification during
new account registration.

## Realtime monitoring and history

The dashboard reads the latest `is_average = false` rows from `ph_readings`,
`ec_readings`, and `temp_readings`, and refreshes when the ESP32 inserts its
five-minute readings. History Logs uses `is_average = true`: daily views keep
each ten-minute summary, weekly views aggregate into eight-hour windows, and
monthly views aggregate by calendar day.

Copy `supabase.example.json` to the ignored `supabase.json`, fill in the project
URL and publishable key, then run both `supabase/realtime_setup.sql` and
`supabase/rbac_setup.sql` once in Supabase. The first script enables the sensor
tables used by the realtime dashboard and history views; the second adds user
profiles, roles, notifications, calibration logs, and administrator-managed
parameter ranges. Then launch with:

```powershell
flutter run -d chrome --dart-define-from-file=supabase.json
```

## Folder structure

```
lib/
  main.dart                     -> app entry point, stays tiny forever
  theme/
    app_colors.dart             -> every color used in the app
    app_text_styles.dart        -> Manrope (titles) + Work Sans (everything else)
    app_theme.dart               -> combines colors/fonts into a Flutter theme
  screens/
    login_screen.dart           -> login UI
    signup_screen.dart          -> signup and email OTP UI
  widgets/
    custom_text_field.dart      -> reusable input box
    custom_button.dart          -> reusable pill button
  controllers/
    login_controller.dart       -> login form state and loading
    signup_controller.dart      -> signup and OTP state
  services/
    auth_service.dart           -> Supabase auth and OTP operations
    supabase_client.dart        -> one shared Supabase client
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

Without Supabase environment values, the app remains runnable as a frontend
prototype. In that mode, login is simulated and any six-digit OTP verifies the
account. With Supabase values supplied, all auth calls use the real backend.

## Next steps (when you're ready)

1. Create or open the Supabase project.
2. In Authentication > Providers > Email, enable email authentication and keep
  email confirmation enabled so signup sends a verification code.
3. Run the app with the project URL and publishable key. Do not commit these
  values to source control:

  ```
  flutter run -d windows --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
  ```

  `SUPABASE_ANON_KEY` is also accepted for compatibility with older projects.
4. The signup form creates the account, shows the OTP form, verifies the code,
  and then opens the dashboard.
