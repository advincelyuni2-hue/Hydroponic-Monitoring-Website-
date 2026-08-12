import 'package:flutter/material.dart';
import '../services/auth_service.dart';
class SignupController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  String? errorMessage;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword = !obscureConfirmPassword;
    notifyListeners();
  }

  Future<bool> createAccount() async {
    errorMessage = null;

    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      errorMessage = 'Please fill in all fields';
      notifyListeners();
      return false;
    }

    if (passwordController.text != confirmPasswordController.text) {
      errorMessage = 'Passwords do not match';
      notifyListeners();
      return false;
    }


    isLoading = true;
    notifyListeners();

   
    final result = await _authService.login(
      email: emailController.text.trim(),
      password: passwordController.text,
    );

    isLoading = false;
    if (!result.success) {
      errorMessage = result.message;
    }
    notifyListeners();

    return result.success;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
