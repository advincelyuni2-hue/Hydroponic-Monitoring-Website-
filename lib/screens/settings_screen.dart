import 'package:flutter/material.dart';
import '../utils/email_mask.dart';
import '../screens/login_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_mode_controller.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../utils/responsive.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final profile = appProfile.value;
    _nameController = TextEditingController(text: profile?.name ?? 'Alveus');
    _emailController = TextEditingController(
      text: maskEmail(profile?.email ?? 'placeholder@example.com'),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppDrawer(selectedIndex: -1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppHeader(title: 'Settings'),
              const SizedBox(height: 24),
              _buildProfileCard(isMobile),
              const SizedBox(height: 16),
              _buildPreferencesCard(),
              const SizedBox(height: 16),
              _buildLogoutCard(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Cards
  // ---------------------------------------------------------------------

  Widget _buildProfileCard(bool isMobile) {
    return _SettingsCard(
      title: 'Profile Management',
      description:
          'Manage the account details used throughout the monitoring app.',
      children: [
        const SizedBox(height: 16),
        _label('Full name'),
        const SizedBox(height: 8),
        _field(_nameController),
        const SizedBox(height: 16),
        _label('Email address'),
        const SizedBox(height: 8),
        _field(_emailController, enabled: false),
        const SizedBox(height: 12),
        if (AuthService().hasPasswordLogin)
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _openCredentialDialog(_CredentialMode.email),
                icon: const Icon(Icons.alternate_email_rounded, size: 16),
                label: const Text('Change email'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    _openCredentialDialog(_CredentialMode.password),
                icon: const Icon(Icons.lock_outline_rounded, size: 16),
                label: const Text('Change password'),
              ),
            ],
          )
        else
          Text(
            'Signed in with Google. Manage your email and password in your Google account.',
            style: AppTextStyles.cardMeta,
          ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: isMobile ? double.infinity : 160,
            height: 38,
            child: ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryButton,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text('Save profile',
                  style: AppTextStyles.button.copyWith(fontSize: 13)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesCard() {
    return _SettingsCard(
      title: 'Preferences',
      description: 'Control alerts, units, and how the app looks.',
      children: [
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text('Notifications', style: AppTextStyles.bodyBold),
          subtitle: Text(
            'Receive alerts when sensor readings need attention.',
            style: AppTextStyles.cardMeta,
          ),
          value: appNotificationsEnabled.value,
          activeThumbColor: AppColors.primaryButton,
          onChanged: (value) {
            appNotificationsEnabled.value = value;
            setState(() {});
          },
        ),
        Divider(color: AppColors.cardBorder, height: 1),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Measurement Units', style: AppTextStyles.bodyBold),
          subtitle: Text(
            'Choose how readings are displayed.',
            style: AppTextStyles.cardMeta,
          ),
          trailing: DropdownButton<String>(
            value: appMeasurementUnits.value,
            isDense: true,
            dropdownColor: AppColors.cardBackground,
            style: AppTextStyles.body.copyWith(fontSize: 15),
            iconEnabledColor: AppColors.textPrimary,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'Metric', child: Text('Metric')),
              DropdownMenuItem(value: 'Imperial', child: Text('Imperial')),
            ],
            onChanged: (value) {
              if (value != null) {
                appMeasurementUnits.value = value;
                setState(() {});
              }
            },
          ),
        ),
        Divider(color: AppColors.cardBorder, height: 1),
        ValueListenableBuilder<ThemeMode>(
          valueListenable: appThemeMode,
          builder: (context, mode, _) {
            final isDark = mode == ThemeMode.dark;
            return SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text('Light/Dark Mode', style: AppTextStyles.bodyBold),
              subtitle: Text(
                isDark ? 'Dark mode is active.' : 'Light mode is active.',
                style: AppTextStyles.cardMeta,
              ),
              value: isDark,
              activeThumbColor: AppColors.primaryButton,
              onChanged: (value) {
                appThemeMode.value = value ? ThemeMode.dark : ThemeMode.light;
              },
            );
          },
        ),
      ],
    );
  }

  /// Same layout as ReportIssueCard: text on the left, pill button on the right.
  Widget _buildLogoutCard(bool isMobile) {
    final button = SizedBox(
      height: 38,
      child: OutlinedButton(
        onPressed: _confirmLogout,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.alertBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          'Log out',
          style: AppTextStyles.button.copyWith(
            fontSize: 13,
            color: AppColors.alertText,
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Log out',
                    style: AppTextStyles.sectionTitle.copyWith(fontSize: 18)),
                const SizedBox(height: 6),
                Text(
                  'Sign out of your account on this device.',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          button,
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Fields
  // ---------------------------------------------------------------------

  Widget _label(String text) => Text(text, style: AppTextStyles.label);

  Widget _field(TextEditingController controller, {bool enabled = true}) {
    return TextField(
      controller: controller,
      enabled: enabled,
      style: AppTextStyles.input,
      decoration: InputDecoration(
        filled: true,
        fillColor: enabled
            ? Theme.of(context).inputDecorationTheme.fillColor
            : AppColors.calloutBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.cardBorder),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
   Future<void> _openCredentialDialog(_CredentialMode mode) async {
    final message = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ChangeCredentialDialog(mode: mode),
    );
    if (message != null && mounted) _showMessage(message);
  }
  Future<void> _saveProfile() async {
    final existing = appProfile.value ??
        UserProfile(
          id: 'local-user',
          name: 'Alveus',
          email: '',
          role: 'Employee',
        );
    await UserService().updateProfile(UserProfile(
      id: existing.id,
      name: _nameController.text.trim(),
      email: existing.email,
      role: existing.role,
      isActive: existing.isActive,
    ));
    if (mounted) _showMessage('Profile changes saved.');
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: AppDecorations.card(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Log out?',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 12),
              Text(
                'You will need to sign in again to access the monitoring app.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryButton),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      'No',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.primaryButton,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.alertText, // Red for logout
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      'Log out',
                      style: AppTextStyles.button.copyWith(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) await _logout();
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final String? description;
  final List<Widget> children;

  const _SettingsCard({
    required this.title,
    this.description,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 18)),
          if (description != null) ...[
            const SizedBox(height: 6),
            Text(description!,
                style: AppTextStyles.bodySmall.copyWith(fontSize: 12)),
          ],
          ...children,
        ],
      ),
    );
  }
}

enum _CredentialMode { password, email }

class _ChangeCredentialDialog extends StatefulWidget {
  final _CredentialMode mode;
  const _ChangeCredentialDialog({required this.mode});

  @override
  State<_ChangeCredentialDialog> createState() =>
      _ChangeCredentialDialogState();
}

class _ChangeCredentialDialogState extends State<_ChangeCredentialDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _busy = false;
  bool _showPasswords = false;
  String? _error;

  bool get _isPassword => widget.mode == _CredentialMode.password;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validate() {
    final current = _currentController.text;
    final next =
        _isPassword ? _newController.text : _newController.text.trim();

    if (current.isEmpty) return 'Enter your current password.';
    if (_isPassword) {
      if (next.length < 8) {
        return 'New password must be at least 8 characters.';
      }
      if (next != _confirmController.text) {
        return 'New passwords do not match.';
      }
      if (next == current) {
        return 'New password must be different from the current one.';
      }
    } else {
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(next)) {
        return 'Enter a valid email address.';
      }
      if (next.toLowerCase() == appProfile.value?.email.toLowerCase()) {
        return 'That is already your email address.';
      }
    }
    return null;
  }

  Future<void> _submit() async {
    final problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    final auth = AuthService();
    final result = _isPassword
        ? await auth.changePassword(
            currentPassword: _currentController.text,
            newPassword: _newController.text,
          )
        : await auth.changeEmail(
            currentPassword: _currentController.text,
            newEmail: _newController.text.trim(),
          );

    if (!mounted) return;
    if (result.success) {
      Navigator.of(context).pop(result.message);
    } else {
      setState(() {
        _busy = false;
        _error = result.message;
      });
    }
  }

  Widget _input(TextEditingController controller, String label,
      {bool secret = false, TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: secret && !_showPasswords,
        keyboardType: type,
        enabled: !_busy,
        style: AppTextStyles.input,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.background,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: AppDecorations.card(),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isPassword ? 'Change password' : 'Change email',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 16),
              _input(_currentController, 'Current password', secret: true),
              if (_isPassword) ...[
                _input(_newController, 'New password', secret: true),
                _input(_confirmController, 'Confirm new password',
                    secret: true),
              ] else
                _input(_newController, 'New email address',
                    type: TextInputType.emailAddress),
              if (_isPassword)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _showPasswords,
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _showPasswords = v ?? false),
                  title:
                      Text('Show passwords', style: AppTextStyles.bodySmall),
                ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(_error!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.alertText)),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _busy ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryButton,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isPassword ? 'Update password' : 'Send link'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}