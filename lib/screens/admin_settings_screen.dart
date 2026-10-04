import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../services/supabase_client.dart';
<<<<<<< HEAD
=======
import '../theme/app_colors.dart';
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
<<<<<<< HEAD
=======
import '../widgets/parameter_config_card.dart';
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
<<<<<<< HEAD
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _phMin = TextEditingController(text: '5.5');
  final _phMax = TextEditingController(text: '6.5');
  final _ecMin = TextEditingController(text: '1.2');
  final _ecMax = TextEditingController(text: '1.8');
=======
  State<AdminSettingsScreen> createState() => AdminSettingsScreenState();
}

class AdminSettingsScreenState extends State<AdminSettingsScreen> {
  RangeValues _phRange = const RangeValues(5.5, 6.5);
  RangeValues _ecRange = const RangeValues(1.2, 1.8);

  RangeValues _initialPhRange = const RangeValues(5.5, 6.5);
  RangeValues _initialEcRange = const RangeValues(1.2, 1.8);

>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

<<<<<<< HEAD
  @override
  void dispose() {
    for (final controller in [_phMin, _phMax, _ecMin, _ecMax]) {
      controller.dispose();
    }
    super.dispose();
  }

=======
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
  Future<void> _load() async {
    if (appProfile.value?.isAdmin != true) {
      setState(() {
        _loading = false;
        _error = 'Administrator access is required.';
      });
      return;
    }
<<<<<<< HEAD
=======

>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
    final client = supabaseClient;
    if (client == null) {
      setState(() {
        _loading = false;
        _error = 'Supabase is not configured.';
      });
      return;
    }
<<<<<<< HEAD
=======

>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
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
<<<<<<< HEAD
      final config = results[1] as Map<String, dynamic>?;
      if (config != null) {
        _phMin.text = '${config['ph_min']}';
        _phMax.text = '${config['ph_max']}';
        _ecMin.text = '${config['ec_min']}';
        _ecMax.text = '${config['ec_max']}';
      }
=======

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

>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
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
<<<<<<< HEAD
    try {
      await client.from('parameter_configurations').upsert({
        'id': 1,
        'ph_min': double.parse(_phMin.text),
        'ph_max': double.parse(_phMax.text),
        'ec_min': double.parse(_ecMin.text),
        'ec_max': double.parse(_ecMax.text),
        'updated_by': client.auth.currentUser?.id,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
=======

    try {
      await client.from('parameter_configurations').upsert({
        'id': 1,
        'ph_min': double.parse(_phRange.start.toStringAsFixed(1)),
        'ph_max': double.parse(_phRange.end.toStringAsFixed(1)),
        'ec_min': double.parse(_ecRange.start.toStringAsFixed(1)),
        'ec_max': double.parse(_ecRange.end.toStringAsFixed(1)),
        'updated_by': client.auth.currentUser?.id,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      _initialPhRange = _phRange;
      _initialEcRange = _ecRange;

>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
      if (mounted) _message('Parameter configuration saved.');
    } catch (_) {
      if (mounted) _message('Unable to save parameter configuration.');
    }
  }

<<<<<<< HEAD
  Future<void> _changeRole(Map<String, dynamic> user, String role) async {
    final client = supabaseClient;
    if (client == null) return;
    try {
      await client.from('profiles').update({'role': role}).eq('id', user['id']);
      setState(() => user['role'] = role);
    } catch (_) {
      if (mounted) _message('Unable to update this user.');
    }
  }

  Future<void> _deactivateUser(Map<String, dynamic> user) async {
    final email = user['email'] as String? ?? 'this user';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate user?'),
        content: Text(
          'This will prevent $email from accessing the application. '
          'Their account and history will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final client = supabaseClient;
    if (client == null) return;
    try {
      await client
          .from('profiles')
          .update({'is_active': false}).eq('id', user['id']);
      setState(() => user['is_active'] = false);
      _message('User deactivated.');
    } catch (_) {
      _message('Unable to deactivate this user.');
=======
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
    final email = user['email'] as String? ?? 'this user';
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
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
    }
  }

  void _message(String text) {
<<<<<<< HEAD
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
=======
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = appProfile.value?.isAdmin == true;
<<<<<<< HEAD
=======

>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
    return Scaffold(
      drawer: const AppDrawer(selectedIndex: 6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(Responsive.isMobile(context) ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
<<<<<<< HEAD
              AppHeader(title: 'Admin settings', profile: appProfile.value),
              const SizedBox(height: 24),
              if (!isAdmin || _loading)
                Center(
                    child:
                        Text(_error ?? 'Loading...', style: AppTextStyles.body))
              else if (_error != null)
                Text(_error!, style: AppTextStyles.body)
              else ...[
                _buildConfiguration(),
=======
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
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
                const SizedBox(height: 24),
                _buildUsers(),
              ],
            ],
          ),
        ),
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildConfiguration() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('pH/EC Parameter Configuration',
              style: AppTextStyles.sectionTitle),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _field('pH minimum', _phMin),
              _field('pH maximum', _phMax),
              _field('EC minimum', _ecMin),
              _field('EC maximum', _ecMax),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveConfiguration,
            child: const Text('Save configuration'),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return SizedBox(
      width: 180,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _buildUsers() {
    return Container(
=======
  Widget _buildUsers() {
    return Container(
      width: double.infinity,
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('User Management', style: AppTextStyles.sectionTitle),
<<<<<<< HEAD
          const SizedBox(height: 12),
          for (final user in _users)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(user['email'] as String? ?? 'Unknown user'),
              subtitle: Text(
                  (user['is_active'] as bool? ?? false) ? 'Active' : 'Revoked'),
              trailing: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DropdownButton<String>(
                    value: user['role'] as String? ?? 'employee',
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(
                          value: 'employee', child: Text('Employee')),
                    ],
                    onChanged: (role) {
                      if (role != null) _changeRole(user, role);
                    },
                  ),
                  if (user['is_active'] as bool? ?? false)
                    IconButton(
                      tooltip: 'Deactivate user',
                      icon: const Icon(Icons.person_off_outlined),
                      onPressed: () => _deactivateUser(user),
                    ),
                ],
              ),
            ),
=======
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
                          user['email'] as String? ?? 'Unknown user',
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
                      onChanged: (role) {
                        if (role != null) _changeRole(user, role);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Switch.adaptive(
                    value: user['is_active'] as bool? ?? false,
                    activeColor: AppColors.primaryButton,
                    onChanged: (active) => _toggleUserActive(user, active),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Delete user account',
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.alertText, size: 20),
                    onPressed: () => _deleteUser(user),
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.cardBorder, height: 1),
          ],
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
        ],
      ),
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
