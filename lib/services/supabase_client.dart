/// Placeholder for the shared Supabase client.
/// Every other service will import THIS file instead of creating
/// its own connection, so there's only ever one client in the whole app.
///
/// LATER, once you add the `supabase_flutter` package and create a project:
///
///   import 'package:supabase_flutter/supabase_flutter.dart';
///
///   Future<void> initSupabase() async {
///     await Supabase.initialize(
///       url: 'YOUR_SUPABASE_URL',
///       anonKey: 'YOUR_SUPABASE_ANON_KEY',
///     );
///   }
///
///   final supabase = Supabase.instance.client;
///
/// And call `initSupabase()` once inside `main()` before `runApp()`.
///
/// For now this file does nothing — it's just a placeholder so the
/// folder structure is ready.
class SupabaseClientPlaceholder {
  // Intentionally empty for now.
}
