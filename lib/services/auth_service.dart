
class AuthService {
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    // Simulate a network request
    await Future.delayed(const Duration(seconds: 1));

    // --- MOCK validation, remove once Supabase is connected ---
    if (email.isEmpty || password.isEmpty) {
      return AuthResult(success: false, message: 'Please fill in all fields');
    }
    if (!email.contains('@')) {
      return AuthResult(success: false, message: 'Enter a valid email');
    }
    // --- end mock validation ---

    // Pretend the login always succeeds for now
    return AuthResult(success: true, message: 'Login successful');
  }

  Future<AuthResult> loginWithGoogle() async {
    await Future.delayed(const Duration(seconds: 1));
    // TODO: replace with Supabase Google OAuth sign-in
    return AuthResult(success: true, message: 'Google login successful');
  }
  // Append this method inside your AuthService class in auth_service.dart

Future<AuthResult> resetPassword({required String email}) async {
  await Future.delayed(const Duration(seconds: 1));

  if (email.trim().isEmpty) {
    return AuthResult(success: false, message: 'Please enter your email address');
  }
  if (!email.contains('@')) {
    return AuthResult(success: false, message: 'Please enter a valid email address');
  }

  // TODO: Replace with Supabase password reset call:
  // await Supabase.instance.client.auth.resetPasswordForEmail(email);

  return AuthResult(
    success: true,
    message: 'Password reset link sent! Check your inbox.',
  );
}
  
}

/// A simple wrapper so the UI always knows: did it work, and if not, why.
class AuthResult {
  final bool success;
  final String message;

  AuthResult({required this.success, required this.message});
}


