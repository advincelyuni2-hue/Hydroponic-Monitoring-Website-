import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/email_mask.dart';
import '../services/app_state.dart';
import '../services/supabase_client.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
import '../widgets/parameter_config_card.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => AdminSettingsScreenState();
}

class AdminSettingsScreenState extends State<AdminSettingsScreen> {
  RangeValues _phRange = const RangeValues(5.5, 6.5);
  RangeValues _ecRange = const RangeValues(1.2, 1.8);

  RangeValues _initialPhRange = const RangeValues(5.5, 6.5);
  RangeValues _initialEcRange = const RangeValues(1.2, 1.8);

  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (appProfile.value?.isAdmin != true) {
      setState(() {
        _loading = false;
        _error = 'Administrator access is required.';
      });
      return;
    }

    final client = supabaseClient;
    if (client == null) {
      setState(() {
        _loading = false;
        _error = 'Supabase is not configured.';
      });
      return;
    }

    try {
      final results = await Future.wait([
        client
            .from('profiles')
            .select('id, email, role, is_active')
            .order('email'),
        client
            .from('parameter_configurations')
            .select()
            .eq('id', 1)
            .maybeSingle(),
      ]);

      final config = results[1] as Map<String, dynamic>?;
      if (config != null) {
        final phMin = (config['ph_min'] as num?)?.toDouble() ?? 5.5;
        final phMax = (config['ph_max'] as num?)?.toDouble() ?? 6.5;
        final ecMin = (config['ec_min'] as num?)?.toDouble() ?? 1.2;
        final ecMax = (config['ec_max'] as num?)?.toDouble() ?? 1.8;

        _phRange = RangeValues(phMin, phMax);
        _ecRange = RangeValues(ecMin, ecMax);
        _initialPhRange = _phRange;
        _initialEcRange = _ecRange;
      }

      if (mounted) {
        setState(() {
          _users = (results[0] as List).cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to load administrator settings.';
        });
      }
    }
  }

    Future<void> _saveConfiguration() async {
    final client = supabaseClient;
    if (client == null) return;

    final phMin = double.parse(_phRange.start.toStringAsFixed(1));
    final phMax = double.parse(_phRange.end.toStringAsFixed(1));
    final ecMin = double.parse(_ecRange.start.toStringAsFixed(1));
    final ecMax = double.parse(_ecRange.end.toStringAsFixed(1));

    if (phMin >= phMax || ecMin >= ecMax) {
      _message('Minimum must be lower than maximum.');
      return;
    }

    try {
      final saved = await client.from('parameter_configurations').upsert({
        'id': 1,
        'ph_min': phMin,
        'ph_max': phMax,
        'ec_min': ecMin,
        'ec_max': ecMax,
        'updated_by': client.auth.currentUser?.id,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).select();

      if (saved.isEmpty) {
        throw StateError('The database did not save the configuration.');
      }

      _initialPhRange = _phRange;
      _initialEcRange = _ecRange;

      // Tell every other screen right away (see Step 3).
      appParameterRanges.value = ParameterRangeConfig(
        phMin: phMin,
        phMax: phMax,
        ecMin: ecMin,
        ecMax: ecMax,
      );

      if (mounted) _message('Parameter configuration saved.');
    } on PostgrestException catch (e) {
      debugPrint('Save config failed: ${e.code} ${e.message}');
      if (mounted) _message('Unable to save: ${e.message}');
    } catch (e) {
      debugPrint('Save config failed: $e');
      if (mounted) _message('Unable to save: $e');
    }
  }

  void _revertConfiguration() {
    setState(() {
      _phRange = _initialPhRange;
      _ecRange = _initialEcRange;
    });
    _message('Configuration reverted to saved values.');
  }

  Future<void> _changeRole(Map<String, dynamic> user, String role) async {
    final client = supabaseClient;
    if (client == null) return;

    try {
      await client
          .from('profiles')
          .update({'role': role})
          .eq('id', user['id']);
      setState(() => user['role'] = role);
      _message('Role updated to ${role.toUpperCase()}.');
    } catch (_) {
      if (mounted) _message('Unable to update user role.');
    }
  }

  Future<void> _toggleUserActive(
      Map<String, dynamic> user, bool active) async {
        if (_isSelf(user)) {
      _message('You cannot deactivate your own account.');
      return;
    }
    final client = supabaseClient;
    if (client == null) return;

    try {
      await client
          .from('profiles')
          .update({'is_active': active})
          .eq('id', user['id']);
      setState(() => user['is_active'] = active);
      _message(active ? 'User activated.' : 'User deactivated.');
    } catch (_) {
      if (mounted) _message('Unable to update user status.');
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final email = maskEmail(user['email'] as String? ?? 'this user');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              Text('Delete User Account?',
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 18)),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to permanently delete $email? This action cannot be undone.',
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
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryButton),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    child: Text('Cancel',
                        style: AppTextStyles.button.copyWith(
                            color: AppColors.primaryButton, fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.alertText,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                    ),
                    child: Text('Delete',
                        style: AppTextStyles.button
                            .copyWith(color: Colors.white, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    final client = supabaseClient;
    if (client == null) return;

    try {
      await client.from('profiles').delete().eq('id', user['id']);
      setState(() {
        _users.removeWhere((u) => u['id'] == user['id']);
      });
      _message('User account deleted.');
    } catch (_) {
      _message('Unable to delete this user.');
    }
  }
    bool _isSelf(Map<String, dynamic> user) {
    final currentId =
        supabaseClient?.auth.currentUser?.id ?? appProfile.value?.id;
    return currentId != null && user['id'] == currentId;
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = appProfile.value?.isAdmin == true;

    return Scaffold(
      drawer: const AppDrawer(selectedIndex: 6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(Responsive.isMobile(context) ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeader(
                  title: 'Admin settings', profile: appProfile.value),
              const SizedBox(height: 24),
              if (!isAdmin || _loading)
                Center(
                    child: Text(_error ?? 'Loading...',
                        style: AppTextStyles.body))
              else if (_error != null)
                Text(_error!, style: AppTextStyles.body)
              else ...[
                ParameterConfigCard(
                  phRange: _phRange,
                  ecRange: _ecRange,
                  onPhChanged: (range) => setState(() => _phRange = range),
                  onEcChanged: (range) => setState(() => _ecRange = range),
                  onSave: _saveConfiguration,
                  onRevert: _revertConfiguration,
                ),
                const SizedBox(height: 24),
                _buildUsers(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsers() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('User Management', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 16),
          Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: 8),
          for (final user in _users) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.calloutBackground,
                    child: Text(
                      (user['email'] as String? ?? 'U')[0].toUpperCase(),
                      style: AppTextStyles.bodyBold
                          .copyWith(color: AppColors.primaryButton),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          maskEmail(user['email'] as String? ?? 'Unknown user'),
                          style: AppTextStyles.bodyBold.copyWith(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (user['is_active'] as bool? ?? false)
                              ? 'Active'
                              : 'Disabled',
                          style: AppTextStyles.cardMeta.copyWith(
                            color: (user['is_active'] as bool? ?? false)
                                ? const Color(0xFF16A34A)
                                : AppColors.alertText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.calloutBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: DropdownButton<String>(
                      value: user['role'] as String? ?? 'employee',
                      underline: const SizedBox.shrink(),
                      isDense: true,
                      style: AppTextStyles.bodySmall
                          .copyWith(fontWeight: FontWeight.w600),
                      items: const [
                        DropdownMenuItem(
                            value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(
                            value: 'employee', child: Text('Employee')),
                      ],
                        onChanged: _isSelf(user)
                          ? null
                          : (role) {
                              if (role != null) _changeRole(user, role);
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Switch.adaptive(
                    value: user['is_active'] as bool? ?? false,
                    activeColor: AppColors.primaryButton,
                    onChanged: _isSelf(user)
                        ? null
                        : (active) => _toggleUserActive(user, active),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Delete user account',
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.alertText, size: 20),
                     onPressed: _isSelf(user) ? null : () => _deleteUser(user),
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.cardBorder, height: 1),
          ],
        ],
      ),
    );
  }
}