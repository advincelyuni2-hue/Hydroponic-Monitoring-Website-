import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_mode_controller.dart';
import '../services/app_state.dart';
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
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;

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
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isMobile ? 16 : 28),
                decoration: AppDecorations.card(
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile Management',
                      style: AppTextStyles.sectionTitle.copyWith(color: textColor),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.iconCircle,
                          child: Icon(Icons.person, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Manage the account details used throughout the monitoring app.',
                            style: AppTextStyles.body.copyWith(color: textColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _label('Full name'),
                    const SizedBox(height: 8),
                    _field(_nameController),
                    const SizedBox(height: 16),
                    _label('Email address'),
                    const SizedBox(height: 8),
                    _field(_emailController, enabled: false),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: isMobile ? double.infinity : 180,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryButton,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 24),
                    Text(
                      'Preferences',
                      style: AppTextStyles.sectionTitle.copyWith(color: textColor),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Notifications',
                        style: AppTextStyles.bodyBold.copyWith(color: textColor),
                      ),
                      subtitle: Text(
                        'Receive alerts when sensor readings need attention.',
                        style: AppTextStyles.cardMeta.copyWith(color: mutedColor),
                      ),
                      value: appNotificationsEnabled.value,
                      activeThumbColor: AppColors.primaryButton,
                      onChanged: (value) {
                        appNotificationsEnabled.value = value;
                        setState(() {});
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Measurement Units',
                        style: AppTextStyles.bodyBold.copyWith(color: textColor),
                      ),
                      subtitle: Text(
                        'Choose how readings are displayed.',
                        style: AppTextStyles.cardMeta.copyWith(color: mutedColor),
                      ),
                      trailing: DropdownButton<String>(
                        value: appMeasurementUnits.value,
                        isDense: true,
                        dropdownColor: Theme.of(context).colorScheme.surface,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                        ),
                        iconEnabledColor: Theme.of(context).colorScheme.onSurface,
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
                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: appThemeMode,
                      builder: (context, mode, _) {
                        final isDark = mode == ThemeMode.dark;
                        return SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Light/Dark Mode',
                            style: AppTextStyles.bodyBold.copyWith(color: textColor),
                          ),
                          subtitle: Text(
                            isDark ? 'Dark mode is active.' : 'Light mode is active.',
                            style: AppTextStyles.cardMeta.copyWith(color: mutedColor),
                          ),
                          value: isDark,
                          activeThumbColor: AppColors.primaryButton,
                          onChanged: (value) {
                            appThemeMode.value =
                                value ? ThemeMode.dark : ThemeMode.light;
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: AppTextStyles.label.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );

  Widget _field(TextEditingController controller, {bool enabled = true}) {
    return TextField(
      controller: controller,
      enabled: enabled,
      style: AppTextStyles.input.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: enabled
            ? Theme.of(context).inputDecorationTheme.fillColor
            : Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
    ));

    if (mounted) _showMessage('Profile changes saved.');
  }
}