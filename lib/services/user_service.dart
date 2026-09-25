import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_state.dart';
import 'supabase_client.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isActive;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
  });

  bool get isAdmin => role.toLowerCase() == 'admin' && isActive;
  String get roleLabel => isAdmin ? 'Admin' : 'Employee';
}

class UserService {
  Future<UserProfile> getProfile(String userId) async {
    final client = supabaseClient;
    if (client != null && userId != 'mock-user-id') {
      Map<String, dynamic>? row;
      try {
        row = await client
            .from('profiles')
            .select('id, full_name, email, role, is_active')
            .eq('id', userId)
            .maybeSingle();
      } on PostgrestException {
        row = null;
      }

      if (row != null) {
        final profile = UserProfile(
          id: row['id'] as String,
          name: (row['full_name'] as String?)?.trim().isNotEmpty == true
              ? row['full_name'] as String
              : 'User',
          email: row['email'] as String? ?? '',
          role: ((row['role'] as String?) ?? 'employee').toLowerCase(),
          isActive: row['is_active'] as bool? ?? true,
        );
        setAppProfile(profile);
        return profile;
      }
    }

    if (appProfile.value != null && appProfile.value!.id == userId) {
      return appProfile.value!;
    }

    final profile = UserProfile(
      id: userId,
      name: 'Alveus',
      email: 'placeholder@example.com',
      role: 'employee',
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