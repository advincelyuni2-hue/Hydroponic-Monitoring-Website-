import 'package:flutter/material.dart';
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
      text: profile?.email ?? 'placeholder@example.com',
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

  Future<void> _saveProfile() async {
    final existing = appProfile.value ??
        UserProfile(
          id: 'local-user',
          name: 'Alveus',
          email: _emailController.text,
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
      builder: (dialogContext) => AlertDialog(
        title: Text('Log out?', style: AppTextStyles.sectionTitle),
        content: Text(
          'You will need to sign in again to access the monitoring app.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel',
                style: AppTextStyles.bodyBold
                    .copyWith(color: AppColors.primaryButton)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Log out',
                style: AppTextStyles.bodyBold
                    .copyWith(color: AppColors.alertText)),
          ),
        ],
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