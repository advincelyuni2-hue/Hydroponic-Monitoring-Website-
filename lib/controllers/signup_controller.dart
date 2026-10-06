import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignupController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController otpController = TextEditingController();

  bool isLoading = false;
  bool isOtpStep = false;
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

  bool _isAllowedSignupName(String name) {
    return RegExp(
      r"^[A-Za-zÀ-ÖØ-öø-ÿ]+(?:['’ -][A-Za-zÀ-ÖØ-öø-ÿ]+)*$",
    ).hasMatch(name.trim());
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
  }

  Future<bool> createAccount() async {
    errorMessage = null;

    final name = nameController.text.trim();
    final email = emailController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      errorMessage = 'Please fill in all fields';
      notifyListeners();
      return false;
    }

    if (!_isAllowedSignupName(name)) {
      errorMessage =
          'Name can use letters, spaces, apostrophes, and hyphens only.';
      notifyListeners();
      return false;
    }

    if (!_isValidEmail(email)) {
      errorMessage = 'Enter a valid email address.';
      notifyListeners();
      return false;
    }

    if (passwordController.text.length < 8) {
      errorMessage = 'Password must be at least 8 characters.';
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

    final result = await _authService.signUp(
      name: name,
      email: email,
      password: passwordController.text,
    );

    isLoading = false;
    if (result.success && result.requiresOtp) {
      isOtpStep = true;
    } else if (!result.success) {
      errorMessage = result.message;
    }
    notifyListeners();

    return result.success;
  }

  Future<bool> verifyOtp() async {
    errorMessage = null;
    final token = otpController.text.trim();
    if (token.length != 6) {
      errorMessage = 'Enter the 6-digit verification code';
      notifyListeners();
      return false;
    }

    isLoading = true;
    notifyListeners();

    final result = await _authService.verifySignupOtp(
      email: emailController.text.trim(),
      token: token,
    );

    isLoading = false;
    if (!result.success) errorMessage = result.message;
    notifyListeners();
    return result.success;
  }

  Future<bool> resendOtp() async {
    errorMessage = null;

    final email = emailController.text.trim();
    if (email.isEmpty) {
      errorMessage = 'Enter your email address first';
      notifyListeners();
      return false;
    }

    isLoading = true;
    notifyListeners();

    final result = await _authService.resendSignupOtp(email: email);

    isLoading = false;
    if (result.success) {
      isOtpStep = true;
    } else {
      errorMessage = result.message;
    }

    notifyListeners();
    return result.success;
  }

  Future<bool> signUpWithGoogle() async {
    errorMessage = null;
    isLoading = true;
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
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    otpController.dispose();
    super.dispose();
  }
}
