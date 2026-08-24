// Handles user profile data (name, email, avatar, settings, etc).
// Currently MOCKED - no real backend call happens yet.

class UserService {
  Future<UserProfile> getProfile(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: replace with a real Supabase query
    return UserProfile(
      id: userId,
      name: 'Alveus',
      email: 'placeholder@example.com',
      role: 'Employee',
    );
  }

  Future<bool> updateProfile(UserProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: replace with a real Supabase update
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
