import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ForgotPasswordController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;
  bool isCodeStep = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  String? errorMessage;
  String? successMessage;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword = !obscureConfirmPassword;
    notifyListeners();
  }

  /// Step 1 (also used by "Resend code"): email the code.
  Future<bool> sendCode() async {
    isLoading = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    final result = await _authService.resetPassword(
      email: emailController.text.trim(),
    );

    isLoading = false;
    if (result.success) {
      isCodeStep = true;
      successMessage = result.message;
    } else {
      errorMessage = result.message;
    }
    notifyListeners();
    return result.success;
  }

  /// Step 2: verify the code and save the new password.
  Future<bool> resetPassword() async {
    errorMessage = null;
    successMessage = null;

    final code = codeController.text.trim();
    final password = newPasswordController.text;

    if (code.length < 6) {
      errorMessage = 'Enter the verification code from your email.';
      notifyListeners();
      return false;
    }
    if (password.length < 8) {
      errorMessage = 'Password must be at least 8 characters.';
      notifyListeners();
      return false;
    }
    if (password != confirmPasswordController.text) {
      errorMessage = 'Passwords do not match.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    notifyListeners();

    final result = await _authService.resetPasswordWithCode(
      email: emailController.text.trim(),
      code: code,
      newPassword: password,
    );

    isLoading = false;
    if (result.success) {
      successMessage = result.message;
    } else {
      errorMessage = result.message;
    }
    notifyListeners();
    return result.success;
  }

  void backToEmailStep() {
    _authService.cancelRecovery();
    isCodeStep = false;
    codeController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authService.cancelRecovery();
    emailController.dispose();
    codeController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}