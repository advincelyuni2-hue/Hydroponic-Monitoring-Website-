import 'package:flutter/material.dart';
import '../models/notification_models.dart';
import '../services/app_state.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_mode_controller.dart';
import '../utils/responsive.dart';
import '../utils/manila_time.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
import 'notifications_screen.dart';

class AddLogScreen extends StatelessWidget {
  final AppNotificationItem? notification;

  const AddLogScreen({super.key, this.notification});

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
              AppHeader(
                title: 'Add a log',
                profile: appProfile.value,
              ),
              const SizedBox(height: 24),
              RecordFixCard(
                notification: notification,
                onCancel: () => Navigator.of(context).maybePop(),
                onSubmit: (entry) async {
                  final notificationService = NotificationService();
                  bool saved;
                  if (notification != null) {
                    saved = await notificationService.recordFixAndResolve(
                      notificationId: notification!.id,
                      parameter: entry.parameter,
                      currentValue: entry.currentValue,
                      currentStatus: notification!.currentStatus,
                      actionType: entry.actionType,
                      amount: entry.amount,
                      notes: entry.notes,
                      reservoirVolumeL: entry.reservoirVolumeL,
                    );
                  } else {
                    saved = await notificationService.recordManualIntervention(
                      parameter: entry.parameter,
                      currentValue: entry.currentValue,
                      actionType: entry.actionType,
                      amount: entry.amount,
                      notes: entry.notes,
                      reservoirVolumeL: entry.reservoirVolumeL,
                    );
                  }
                  if (!saved) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(notificationService
                                  .lastInterventionError ??
                              'Unable to save the intervention. The alert remains active.'),
                        ),
                      );
                    }
                    return false;
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Fix recorded successfully.')),
                    );
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  }
                  return true;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FixEntry {
  final String parameter;
  final double currentValue;
  final String actionType;
  final double? amount;
  final double? reservoirVolumeL;
  final String notes;

  const FixEntry({
    required this.parameter,
    required this.currentValue,
    required this.actionType,
    required this.amount,
    this.reservoirVolumeL,
    required this.notes,
  });
}

class RecordFixCard extends StatefulWidget {
  final AppNotificationItem? notification;
  final VoidCallback onCancel;
  final Future<bool> Function(FixEntry) onSubmit;
  final String? Function()? submissionError;

  const RecordFixCard({
    super.key,
    this.notification,
    required this.onCancel,
    required this.onSubmit,
    this.submissionError,
  });

  @override
  State<RecordFixCard> createState() => RecordFixCardState();
}

class RecordFixCardState extends State<RecordFixCard> {
  static const parameters = ['pH', 'EC', 'Temperature'];
  static const units = {'pH': 'pH', 'EC': 'mS/cm', 'Temperature': '°C'};
  static const actions = {
    'pH': ['pH Up', 'pH Down', 'Other'],
    'EC': ['Add Nutrient', 'Add Water', 'Other'],
    'Temperature': ['Add Water', 'Other'],
  };

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _currentValueController;
  final _amountController = TextEditingController();
  final _reservoirVolumeController = TextEditingController();
  late final TextEditingController _notesController;

  String? parameter;
  String? actionType;
  late final String dateTimestamp;
  bool _submitting = false;
  String? _submissionError;

  @override
  void initState() {
    super.initState();
    dateTimestamp = formatManilaDateTime(manilaNow());

    String prefilledParam = 'pH';
    if (widget.notification != null) {
      final title = widget.notification!.title.toLowerCase();
      if (title.contains('ec')) {
        prefilledParam = 'EC';
      } else if (title.contains('temp')) {
        prefilledParam = 'Temperature';
      }
    }
    parameter = prefilledParam;

    final rawVal =
        widget.notification?.currentValue.replaceAll(RegExp(r'[^0-9.]'), '') ??
            '';
    _currentValueController = TextEditingController(text: rawVal);
    _notesController = TextEditingController(
      text: widget.notification?.recommendation ?? '',
    );
  }

  @override
  void dispose() {
    _currentValueController.dispose();
    _amountController.dispose();
    _reservoirVolumeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _submissionError = null;
    });
    try {
      final saved = await widget.onSubmit(FixEntry(
        parameter: parameter!,
        currentValue: parameter == 'Temperature'
            ? fromDisplayTemp(double.parse(_currentValueController.text))
            : double.parse(_currentValueController.text),
        actionType: actionType ?? 'Other',
        amount: double.tryParse(_amountController.text.trim()),
        reservoirVolumeL:
            double.tryParse(_reservoirVolumeController.text.trim()),
        notes: _notesController.text.trim(),
      ));
      if (!saved && mounted) {
        setState(() => _submissionError = widget.submissionError?.call() ??
            'Unable to save the intervention. Please try again.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _submissionError = 'Unable to save: $error');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    final timestampField = _labeled(
      'Logged Date & Time (Read-only)',
      TextFormField(
        initialValue: dateTimestamp,
        enabled: false,
        style: AppTextStyles.input.copyWith(color: AppColors.textSecondary),
        decoration: _decoration(hint: dateTimestamp),
      ),
    );

    final parameterField = _labeled(
      'Parameter',
      _dropdown(
        hint: 'Select parameter',
        value: parameter,
        items: parameters,
        onChanged: (v) => setState(() {
          parameter = v;
          actionType = null;
        }),
      ),
    );

    final currentValueField = _labeled(
      'Current value',
      _textField(
        controller: _currentValueController,
        hint: '7.2',
        suffix:
            parameter == 'Temperature' ? tempUnit : (units[parameter] ?? ''),
        numeric: true,
      ),
    );

    final actionField = _labeled(
      'Type of action',
      _dropdown(
        hint: 'Select action',
        value: actionType,
        items: actions[parameter] ?? const [],
        onChanged: (v) => setState(() => actionType = v),
      ),
    );

    final amountField = _labeled(
      'Amount / volume (optional)',
      _textField(
        controller: _amountController,
        hint: '250',
        suffix: 'mL',
        numeric: true,
        required: false,
      ),
    );

    final reservoirVolumeField = _labeled(
      'Reservoir volume (optional)',
      _textField(
        controller: _reservoirVolumeController,
        hint: '100',
        suffix: 'L',
        numeric: true,
        required: false,
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Record a fix',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 18)),
            const SizedBox(height: 6),
            Text(
              'Log an action you took so your history and forecasts stay accurate.',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 14),
            Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 16),
            timestampField,
            const SizedBox(height: 16),
            if (isMobile) ...[
              parameterField,
              const SizedBox(height: 16),
              currentValueField,
              const SizedBox(height: 16),
              actionField,
              const SizedBox(height: 16),
              amountField,
              const SizedBox(height: 16),
              reservoirVolumeField,
            ] else ...[
              _twoColumns(parameterField, currentValueField),
              const SizedBox(height: 16),
              _twoColumns(actionField, amountField),
              const SizedBox(height: 16),
              reservoirVolumeField,
            ],
            const SizedBox(height: 16),
            _labeled(
              'Notes / Intervention Details',
              _textField(
                controller: _notesController,
                hint: 'Describe the action performed...',
                maxLines: 4,
                required: false,
              ),
            ),
            const SizedBox(height: 20),
            if (_submissionError != null) ...[
              Text(
                _submissionError!,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.criticalRed),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryButton),
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.button.copyWith(
                        fontSize: 13,
                        color: AppColors.primaryButton,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryButton,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      _submitting ? 'Saving...' : 'Record fix',
                      style: AppTextStyles.button.copyWith(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _twoColumns(Widget left, Widget right) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 24),
          Expanded(child: right),
        ],
      );

  Widget _labeled(String label, Widget field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 8),
          field,
        ],
      );

  Color get _fill => appThemeMode.value == ThemeMode.dark
      ? const Color(0xFF252D25)
      : AppColors.inputFill;

  InputDecoration _decoration({String? hint, String? suffix}) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.input.copyWith(color: AppColors.textSecondary),
      suffixText: (suffix == null || suffix.isEmpty) ? null : suffix,
      suffixStyle: AppTextStyles.cardMeta,
      filled: true,
      fillColor: _fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: border(AppColors.inputBorder),
      enabledBorder: border(AppColors.inputBorder),
      focusedBorder: border(AppColors.primaryButton),
      errorBorder: border(AppColors.alertBorder),
      focusedErrorBorder: border(AppColors.alertBorder),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    String? hint,
    String? suffix,
    bool numeric = false,
    bool required = true,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: AppTextStyles.input,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.multiline,
      decoration: _decoration(hint: hint, suffix: suffix),
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) return required ? 'Required' : null;
        if (numeric) {
          final number = double.tryParse(trimmed);
          if (number == null) return 'Enter a number';
          if (number < 0) return 'Cannot be negative';
        }
        return null;
      },
    );
  }

  Widget _dropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      key: ValueKey('$hint-$value-${items.length}'),
      initialValue: value,
      isExpanded: true,
      hint: Text(
        hint,
        style: AppTextStyles.input.copyWith(color: AppColors.textSecondary),
      ),
      style: AppTextStyles.input,
      dropdownColor: AppColors.cardBackground,
      iconEnabledColor: AppColors.textPrimary,
      decoration: _decoration(),
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Required' : null,
    );
  }
}

Future<void> showRecordFixDialog(
  BuildContext context, {
  AppNotificationItem? notification,
  required Future<bool> Function(FixEntry) onSubmit,
  String? Function()? submissionError,
  bool barrierDismissible = true,
}) {
  return showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: RecordFixCard(
          notification: notification,
          submissionError: submissionError,
          onCancel: () => Navigator.of(dialogContext).pop(),
          onSubmit: (entry) async {
            final saved = await onSubmit(entry);
            if (saved && dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
            return saved;
          },
        ),
      ),
    ),
  );
}
