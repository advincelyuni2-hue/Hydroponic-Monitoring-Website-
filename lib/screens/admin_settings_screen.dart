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
            .select('id, email, role, is_active, deactivated_at')
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

  Future<void> _revertConfiguration() async {
    setState(() {
      _phRange = const RangeValues(5.5, 6.5);
      _ecRange = const RangeValues(1.2, 1.8);
    });

    await _saveConfiguration();
  }

  Future<void> _changeRole(Map<String, dynamic> user, String role) async {
    final client = supabaseClient;
    if (client == null) return;

    try {
      await client.from('profiles').update({'role': role}).eq('id', user['id']);
      setState(() => user['role'] = role);
      _message('Role updated to ${role.toUpperCase()}.');
    } catch (_) {
      if (mounted) _message('Unable to update user role.');
    }
  }

  Future<void> _toggleUserActive(
    Map<String, dynamic> user,
    bool active,
  ) async {
    if (_isSelf(user)) {
      _message('You cannot deactivate your own account.');
      return;
    }

    if (active && !_canReactivate(user)) {
      _message('The 7-day reactivation window has expired.');
      return;
    }

    final client = supabaseClient;
    if (client == null) return;

    final deactivatedAt =
        active ? null : DateTime.now().toUtc().toIso8601String();

    try {
      final updatedRows = await client
          .from('profiles')
          .update({
            'is_active': active,
            'deactivated_at': deactivatedAt,
          })
          .eq('id', user['id'])
          .select('id');

      if (updatedRows.isEmpty) {
        throw StateError('The user status was not saved.');
      }

      if (!mounted) return;

      setState(() {
        user['is_active'] = active;
        user['deactivated_at'] = deactivatedAt;
      });

      _message(active ? 'User reactivated.' : 'User deactivated.');
    } catch (_) {
      if (mounted) {
        _message('Unable to update user status.');
      }
    }
  }

  DateTime? _getDeactivatedAt(Map<String, dynamic> user) {
    final value = user['deactivated_at'];
    if (value == null) return null;

    return DateTime.tryParse(value.toString())?.toUtc();
  }

  bool _canReactivate(Map<String, dynamic> user) {
    final isActive = user['is_active'] as bool? ?? false;
    if (isActive) return true;

    final rawTimestamp = user['deactivated_at'];

    // Older inactive profiles with no timestamp remain reactivatable.
    if (rawTimestamp == null) return true;

    final deactivatedAt = _getDeactivatedAt(user);
    if (deactivatedAt == null) return false;

    final deadline = deactivatedAt.add(const Duration(days: 7));
    return DateTime.now().toUtc().isBefore(deadline);
  }

  String _statusLabel(Map<String, dynamic> user) {
    final isActive = user['is_active'] as bool? ?? false;
    if (isActive) return 'Active';

    final rawTimestamp = user['deactivated_at'];
    if (rawTimestamp == null) return 'Deactivated';

    final deactivatedAt = _getDeactivatedAt(user);
    if (deactivatedAt == null) return 'Deactivation date unavailable';

    final deadline = deactivatedAt.add(const Duration(days: 7));

    if (DateTime.now().toUtc().isBefore(deadline)) {
      return 'Reactivate by ${deadline.toLocal()}';
    }

    return 'Reactivation window expired';
  }

  bool _isSelf(Map<String, dynamic> user) {
    final currentId =
        supabaseClient?.auth.currentUser?.id ?? appProfile.value?.id;
    return currentId != null && user['id'] == currentId;
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
              AppHeader(title: 'Admin settings', profile: appProfile.value),
              const SizedBox(height: 24),
              if (!isAdmin || _loading)
                Center(
                    child:
                        Text(_error ?? 'Loading...', style: AppTextStyles.body))
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
                          _statusLabel(user),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
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
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
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
                    activeThumbColor: AppColors.primaryButton,
                    onChanged: _isSelf(user) || !_canReactivate(user)
                        ? null
                        : (active) => _toggleUserActive(user, active),
                  ),
                  const SizedBox(width: 8),
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
