import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'supabase_client.dart';
import 'app_state.dart';
import 'user_service.dart';

class AuthService {
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      return AuthResult(success: false, message: 'Please fill in all fields');
    }
    if (!email.contains('@')) {
      return AuthResult(success: false, message: 'Enter a valid email');
    }
    final client = supabaseClient;
    if (client == null) {
      await Future.delayed(const Duration(seconds: 1));
      setAppProfile(UserProfile(
        id: 'prototype-user',
        name: 'User',
        email: email,
        role: 'Employee',
      ));
      return AuthResult(success: true, message: 'Login successful');
    }

    try {
      await client.auth.signInWithPassword(email: email, password: password);
      await _setAuthenticatedProfile(email);
      if (appProfile.value?.isActive == false) {
        await client.auth.signOut();
        appProfile.value = null;
        return AuthResult(
          success: false,
          message: 'Unable to log in with those credentials. Please try again.',
        );
      }
      return AuthResult(success: true, message: 'Login successful');
    } on AuthException catch (error) {
      debugPrint('Login failed: ${error.message}');
      return AuthResult(
        success: false,
        message: 'Unable to log in with those credentials. Please try again.',
      );
    } catch (_) {
      return AuthResult(
        success: false,
        message: 'Unable to log in right now. Please try again.',
      );
    }
  }

  Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final client = supabaseClient;
    if (client == null) {
      await Future.delayed(const Duration(seconds: 1));
      return AuthResult(
        success: true,
        message: 'Verification code sent to your email.',
        requiresOtp: true,
      );
    }

    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );
      return AuthResult(
        success: response.user != null,
        message: 'Verification code sent to your email.',
        requiresOtp: response.user != null,
      );
    } on AuthException catch (error) {
      return AuthResult(success: false, message: error.message);
    } catch (_) {
      return AuthResult(
        success: false,
        message: 'Unable to create your account right now.',
      );
    }
  }

  Future<AuthResult> verifySignupOtp({
    required String email,
    required String token,
  }) async {
    final client = supabaseClient;
    if (client == null) {
      await Future.delayed(const Duration(milliseconds: 500));
      return AuthResult(
          success: token.length == 6, message: 'Account verified');
    }

    try {
      await client.auth.verifyOTP(
        type: OtpType.signup,
        email: email,
        token: token,
      );
      await _setAuthenticatedProfile(email);
      return AuthResult(success: true, message: 'Account verified');
    } on AuthException catch (error) {
      return AuthResult(success: false, message: error.message);
    } catch (_) {
      return AuthResult(
        success: false,
        message: 'Unable to verify the code right now.',
      );
    }
  }

  Future<AuthResult> resendSignupOtp({required String email}) async {
    final client = supabaseClient;
    if (client == null) {
      await Future.delayed(const Duration(milliseconds: 500));
      return AuthResult(success: true, message: 'A new code was sent.');
    }

    try {
      await client.auth.resend(type: OtpType.signup, email: email);
      return AuthResult(success: true, message: 'A new code was sent.');
    } on AuthException catch (error) {
      return AuthResult(success: false, message: error.message);
    } catch (_) {
      return AuthResult(
        success: false,
        message: 'Unable to resend the code right now.',
      );
    }
  }

  Future<void> _setAuthenticatedProfile(String email) async {
    final user = supabaseClient?.auth.currentUser;
    final profile = UserProfile(
      id: user?.id ?? 'authenticated-user',
      name: user?.userMetadata?['full_name'] as String? ?? 'User',
      email: user?.email ?? email,
      role: 'employee',
    );
    if (user != null) {
      setAppProfile(await UserService().getProfile(user.id));
    } else {
      setAppProfile(profile);
    }
  }

  Future<AuthResult> loginWithGoogle() async {
    final client = supabaseClient;
    if (client == null) {
      return AuthResult(
        success: false,
        message: 'Google login requires Supabase configuration.',
      );
    }

    try {
      final started = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? Uri.base.origin : null,
      );
      return AuthResult(
        success: started,
        message: started
            ? 'Redirecting to Google...'
            : 'Unable to start Google login.',
      );
    } on AuthException catch (error) {
      return AuthResult(success: false, message: error.message);
    } catch (_) {
      return AuthResult(
        success: false,
        message: 'Unable to start Google login. Please try again.',
      );
    }
  }

  Future<void> logout() async {
    if (supabaseClient != null) await supabaseClient!.auth.signOut();
    appProfile.value = null;
  }
  // Append this method inside your AuthService class in auth_service.dart

  Future<AuthResult> resetPassword({required String email}) async {
    if (email.trim().isEmpty) {
      return AuthResult(
          success: false, message: 'Please enter your email address');
    }
    if (!email.contains('@')) {
      return AuthResult(
          success: false, message: 'Please enter a valid email address');
    }

    final client = supabaseClient;
    if (client != null) {
      try {
        await client.auth.resetPasswordForEmail(email);
      } on AuthException catch (error) {
        return AuthResult(success: false, message: error.message);
      }
    } else {
      await Future.delayed(const Duration(seconds: 1));
    }

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
  final bool requiresOtp;

  AuthResult({
    required this.success,
    required this.message,
    this.requiresOtp = false,
  });
}
