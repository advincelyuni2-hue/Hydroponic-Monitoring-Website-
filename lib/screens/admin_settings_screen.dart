import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../services/supabase_client.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _phMin = TextEditingController(text: '5.5');
  final _phMax = TextEditingController(text: '6.5');
  final _ecMin = TextEditingController(text: '1.2');
  final _ecMax = TextEditingController(text: '1.8');
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in [_phMin, _phMax, _ecMin, _ecMax]) {
      controller.dispose();
    }
    super.dispose();
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
        _phMin.text = '${config['ph_min']}';
        _phMax.text = '${config['ph_max']}';
        _ecMin.text = '${config['ec_min']}';
        _ecMax.text = '${config['ec_max']}';
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
      if (mounted) _message('Parameter configuration saved.');
    } catch (_) {
      if (mounted) _message('Unable to save parameter configuration.');
    }
  }

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
    }
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
                _buildConfiguration(),
                const SizedBox(height: 24),
                _buildUsers(),
              ],
            ],
          ),
        ),
      ),
    );
  }

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
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('User Management', style: AppTextStyles.sectionTitle),
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
        ],
      ),
    );
  }
}
