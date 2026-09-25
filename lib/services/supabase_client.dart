import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY'),
);

bool get isSupabaseConfigured =>
    supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

Future<void> initSupabase() async {
  if (!isSupabaseConfigured) return;
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
}

SupabaseClient? get supabaseClient =>
    isSupabaseConfigured ? Supabase.instance.client : null;

SupabaseClient get supabase {
  final client = supabaseClient;
  if (client == null) {
    throw StateError(
      'Supabase is not configured. Run Flutter with '
      '--dart-define-from-file=supabase.json.',
    );
  }
  return client;
}