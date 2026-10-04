import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/remember_me_service.dart';

class LoginController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool rememberMe = false;
  bool isLoading = false;
  bool obscurePassword = true;
  String? errorMessage;

    LoginController() {
    _loadRemembered();
  }

  Future<void> _loadRemembered() async {
    final service = RememberMeService();
    rememberMe = await service.isEnabled();
    final email = await service.savedEmail();
    if (email != null) emailController.text = email;
    notifyListeners();
  }

  void toggleRememberMe(bool? value) {
    rememberMe = value ?? false;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  Future<bool> login() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _authService.login(
      email: emailController.text.trim(),
      password: passwordController.text,
    );

    isLoading = false;
    if (!result.success) {
      errorMessage = result.message;
    } else {
      await RememberMeService().save(
        remember: rememberMe,
        email: emailController.text.trim(),
      );
    }
    notifyListeners();

    return result.success;
  }

  Future<bool> loginWithGoogle() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _authService.loginWithGoogle();

    isLoading = false;
    if (!result.success) {
      errorMessage = result.message;
    }
    notifyListeners();

    return result.success;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
