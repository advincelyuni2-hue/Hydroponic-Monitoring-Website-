import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'supabase_client.dart';
import 'app_state.dart';
import 'user_service.dart';
import 'remember_me_service.dart';

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

    const duplicateMessage =
        'An account with this email already exists. Please log in instead.';

    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );

      final user = response.user;
      // Supabase hides duplicates: an already-registered email comes back
      // as a user with an EMPTY identities list instead of an error.
      if (user != null && (user.identities?.isEmpty ?? false)) {
        return AuthResult(success: false, message: duplicateMessage);
      }

      return AuthResult(
        success: user != null,
        message: 'Verification code sent to your email.',
        requiresOtp: user != null,
      );
    } on AuthException catch (error) {
      final text = error.message.toLowerCase();
      if (text.contains('already') && text.contains('registered')) {
        return AuthResult(success: false, message: duplicateMessage);
      }
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
      await RememberMeService().save(remember: true);
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

  /// False for Google-only accounts, which have no password to change.
  bool get hasPasswordLogin {
    final user = supabaseClient?.auth.currentUser;
    if (user == null) return true;
    final identities = user.identities;
    if (identities == null || identities.isEmpty) return true;
    return identities.any((i) => i.provider == 'email');
  }

  Future<AuthResult> _reauthenticate(String currentPassword) async {
    final client = supabaseClient!;
    final email = client.auth.currentUser?.email;
    if (email == null) {
      return AuthResult(success: false, message: 'No signed-in user found.');
    }
    try {
      await client.auth
          .signInWithPassword(email: email, password: currentPassword);
      return AuthResult(success: true, message: 'ok');
    } on AuthException {
      return AuthResult(
          success: false, message: 'Current password is incorrect.');
    }
  }

  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final client = supabaseClient;
    if (client == null) {
      await Future.delayed(const Duration(milliseconds: 500));
      return AuthResult(success: true, message: 'Password updated.');
    }
    try {
      final check = await _reauthenticate(currentPassword);
      if (!check.success) return check;
      await client.auth.updateUser(UserAttributes(password: newPassword));
      return AuthResult(success: true, message: 'Password updated.');
    } on AuthException catch (error) {
      return AuthResult(success: false, message: error.message);
    } catch (_) {
      return AuthResult(
          success: false, message: 'Unable to change password right now.');
    }
  }

  Future<AuthResult> changeEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    final client = supabaseClient;
    if (client == null) {
      await Future.delayed(const Duration(milliseconds: 500));
      return AuthResult(
          success: true, message: 'Confirmation sent to $newEmail.');
    }
    try {
      final check = await _reauthenticate(currentPassword);
      if (!check.success) return check;
      await client.auth.updateUser(
        UserAttributes(email: newEmail),
        emailRedirectTo: kIsWeb ? Uri.base.origin : null,
      );
      return AuthResult(
        success: true,
        message: 'Confirmation sent. Check your inbox to finish the change.',
      );
    } on AuthException catch (error) {
      return AuthResult(success: false, message: error.message);
    } catch (_) {
      return AuthResult(
          success: false, message: 'Unable to change email right now.');
    }
  }

  /// Called on app start. Returns true if the user should skip the login screen.
  Future<bool> restoreSession() async {
    final client = supabaseClient;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return false;

    if (!await RememberMeService().isEnabled()) {
      await client.auth.signOut();
      return false;
    }

    await _setAuthenticatedProfile(user.email ?? '');
    if (appProfile.value?.isActive == false) {
      await client.auth.signOut();
      appProfile.value = null;
      return false;
    }
    return true;
  }

  Future<void> logout() async {
    if (supabaseClient != null) await supabaseClient!.auth.signOut();
    appProfile.value = null;
  }

  bool _recoveryVerified = false;

  /// Step 1 of "forgot password": emails a one-time code.
  Future<AuthResult> resetPassword({required String email}) async {
    final value = email.trim();

    if (value.isEmpty) {
      return AuthResult(
        success: false,
        message: 'Please enter your email address',
      );
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
      return AuthResult(
        success: false,
        message: 'Please enter a valid email address',
      );
    }

    final client = supabaseClient;
    if (client == null) {
      return AuthResult(
        success: false,
        message: 'Password reset is unavailable right now.',
      );
    }

    try {
      final check = await client.functions.invoke(
        'check-reset-email',
        body: {'email': value},
      );

      final data = check.data;
      final accountExists = data is Map && data['exists'] == true;

      if (!accountExists) {
        return AuthResult(
          success: false,
          message: 'No account found with this email.',
        );
      }

      await client.auth.resetPasswordForEmail(value);

      return AuthResult(
        success: true,
        message: 'Verification code sent! Check your inbox.',
      );
    } on AuthException {
      return AuthResult(
        success: false,
        message: 'Unable to send the reset code right now.',
      );
    } catch (_) {
      return AuthResult(
        success: false,
        message: 'Unable to verify this email right now. Please try again.',
      );
    }
  }

  /// Step 2: checks the code, then sets the new password.
  Future<AuthResult> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final client = supabaseClient;
    if (client == null) {
      await Future.delayed(const Duration(milliseconds: 500));
      return AuthResult(
          success: true, message: 'Password updated. Please log in.');
    }

    // The code can only be used once, so skip it if it already worked and
    // only the password update failed (for example a weak password).
    if (!_recoveryVerified || client.auth.currentSession == null) {
      try {
        await client.auth.verifyOTP(
          type: OtpType.recovery,
          email: email.trim(),
          token: code.trim(),
        );
        _recoveryVerified = true;
      } on AuthException {
        return AuthResult(
          success: false,
          message: 'Invalid or expired code. Please try again.',
        );
      } catch (_) {
        return AuthResult(
          success: false,
          message: 'Unable to verify the code right now.',
        );
      }
    }

    try {
      await client.auth.updateUser(UserAttributes(password: newPassword));
      await client.auth.signOut();
      _recoveryVerified = false;
      appProfile.value = null;
      return AuthResult(
        success: true,
        message: 'Password updated. Please log in with your new password.',
      );
    } on AuthException catch (error) {
      return AuthResult(success: false, message: error.message);
    } catch (_) {
      return AuthResult(
        success: false,
        message: 'Unable to update the password right now.',
      );
    }
  }

  /// Signs out the temporary session if the user leaves mid-reset.
  Future<void> cancelRecovery() async {
    if (!_recoveryVerified) return;
    _recoveryVerified = false;
    await supabaseClient?.auth.signOut();
    appProfile.value = null;
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
