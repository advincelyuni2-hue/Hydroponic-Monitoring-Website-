import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ForgotPasswordController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  final TextEditingController emailController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  Future<bool> sendResetLink() async {
    isLoading = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    final result = await _authService.resetPassword(
      email: emailController.text.trim(),
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

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}