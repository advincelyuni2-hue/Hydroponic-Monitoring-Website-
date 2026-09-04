// Handles user profile data (name, email, avatar, settings, etc).
// Currently uses local state until profile tables are added to Supabase.
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_state.dart';
import 'supabase_client.dart';

class UserService {
  Future<UserProfile> getProfile(String userId) async {
    if (appProfile.value != null) return appProfile.value!;
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: replace with a real Supabase query
    final profile = UserProfile(
      id: userId,
      name: 'Alveus',
      email: 'placeholder@example.com',
      role: 'Employee',
    );
    setAppProfile(profile);
    return profile;
  }

  Future<bool> updateProfile(UserProfile profile) async {
    final client = supabaseClient;
    if (client != null) {
      await client.auth.updateUser(
        UserAttributes(data: {'full_name': profile.name}),
      );
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    setAppProfile(profile);
    return true;
  }
}

/// Simple placeholder model for a user's profile.
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String role;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });
}
