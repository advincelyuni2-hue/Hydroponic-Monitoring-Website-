import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_state.dart';
import 'supabase_client.dart';
import 'user_service.dart';

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

class AuthService {
  final UserService _userService = UserService();

  /// Real Supabase Email & Password Login
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      return AuthResult(
        success: false,
        message: 'Please fill in all required fields.',
      );
    }

    try {
      final client = supabase;
      final AuthResponse response = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      if (user != null) {
        final profile = await _userService.getProfile(user.id);
        setAppProfile(profile);
        return AuthResult(
          success: true,
          message: 'Login successful.',
        );
      }

      return AuthResult(
        success: false,
        message: 'Unable to verify session.',
      );
    } on AuthException catch (e) {
      return AuthResult(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Supabase User Registration
  Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final client = supabaseClient;
    if (client == null) {
      return AuthResult(
        success: false,
        message: 'Supabase is not configured.',
      );
    }

    try {
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': name.trim()},
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

  /// Verify OTP Token for Registration
  Future<AuthResult> verifySignupOtp({
    required String email,
    required String token,
  }) async {
    final client = supabaseClient;
    if (client == null) {
      return AuthResult(success: false, message: 'Supabase not configured.');
    }

    try {
      final response = await client.auth.verifyOTP(
        type: OtpType.signup,
        email: email.trim(),
        token: token.trim(),
      );

      if (response.user != null) {
        final profile = await _userService.getProfile(response.user!.id);
        setAppProfile(profile);
      }

      return AuthResult(success: true, message: 'Account verified successfully.');
    } on AuthException catch (error) {
      return AuthResult(success: false, message: error.message);
    } catch (_) {
      return AuthResult(
        success: false,
        message: 'Unable to verify the code right now.',
      );
    }
  }

  /// Resend Signup OTP Code
  Future<AuthResult> resendSignupOtp({required String email}) async {
    final client = supabaseClient;
    if (client == null) {
      return AuthResult(success: false, message: 'Supabase not configured.');
    }

    try {
      await client.auth.resend(type: OtpType.signup, email: email.trim());
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

  /// Real Supabase Google OAuth Login
  Future<AuthResult> loginWithGoogle() async {
    try {
      final client = supabase;
      final bool success = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://login-callback',
      );

      return AuthResult(
        success: success,
        message: success ? 'Google login initialized.' : 'Google login failed.',
      );
    } on AuthException catch (e) {
      return AuthResult(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Google auth error: ${e.toString()}',
      );
    }
  }

  /// Real Supabase Password Reset Email
  Future<AuthResult> resetPassword({required String email}) async {
    if (email.trim().isEmpty) {
      return AuthResult(
        success: false,
        message: 'Please enter your email address.',
      );
    }

    try {
      final client = supabase;
      await client.auth.resetPasswordForEmail(email.trim());
      return AuthResult(
        success: true,
        message: 'Password reset link sent! Check your inbox.',
      );
    } on AuthException catch (e) {
      return AuthResult(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Error sending password reset: ${e.toString()}',
      );
    }
  }

  /// Logout and clear active app state
  Future<void> logout() async {
    try {
      final client = supabaseClient;
      await client?.auth.signOut();
    } catch (e) {
      print('Error during logout: $e');
    } finally {
      clearAppProfile();
    }
  }
}