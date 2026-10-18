import '../widgets/app_footer.dart';
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
import '../widgets/custom_button.dart';
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
        child: AppFooterScrollView(
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
                      performedAtManila: entry.performedAtManila!,
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
  final DateTime? performedAtManila;

  const FixEntry({
    required this.parameter,
    required this.currentValue,
    required this.actionType,
    required this.amount,
    this.reservoirVolumeL,
    required this.notes,
    this.performedAtManila,
  });
}

class RecordFixCard extends StatefulWidget {
  final AppNotificationItem? notification;
  final VoidCallback onCancel;
  final Future<bool> Function(FixEntry) onSubmit;
  final String? Function()? submissionError;

  /// Dialog look: a bit more padding and a close (✕) button in the corner.
  /// The full-page version (AddLogScreen) leaves this off.
  final bool dialogStyle;

  const RecordFixCard({
    super.key,
    this.notification,
    required this.onCancel,
    required this.onSubmit,
    this.submissionError,
    this.dialogStyle = false,
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
  late DateTime _performedAtManila;
  bool _submitting = false;
  String? _submissionError;

  // ---------------------------------------------------------------------------
  // LOGIC (unchanged)
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _performedAtManila = manilaNow();

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
        widget.notification?.currentValue.replaceAll(RegExp(r'[^0-9.\-]'), '') ??
            '';
    final numericValue = double.tryParse(rawVal);
    final displayValue = parameter == 'Temperature' && numericValue != null
        ? toDisplayTemp(numericValue).toStringAsFixed(1)
        : rawVal;
    _currentValueController = TextEditingController(text: displayValue);
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

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _performedAtManila,
      firstDate: DateTime(2020),
      lastDate: manilaNow(),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _performedAtManila = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _performedAtManila.hour,
        _performedAtManila.minute,
      );
      _submissionError = null;
    });
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_performedAtManila),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _performedAtManila = DateTime(
        _performedAtManila.year,
        _performedAtManila.month,
        _performedAtManila.day,
        selected.hour,
        selected.minute,
      );
      _submissionError = null;
    });
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    if (widget.notification == null &&
        manilaWallTimeToUtc(_performedAtManila)
            .isAfter(DateTime.now().toUtc())) {
      setState(() => _submissionError =
          'The intervention date and time cannot be in the future.');
      return;
    }
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
        performedAtManila:
            widget.notification == null ? _performedAtManila : null,
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

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;

    final timestampField = notification != null
        ? _loggedRow()
        : _labeled(
            'Action date & time (Manila)',
            Wrap(spacing: 12, runSpacing: 8, children: [
              OutlinedButton.icon(
                onPressed: _submitting ? null : _pickDate,
                style: _pickerButtonStyle(),
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(
                    '${_performedAtManila.year}-${_performedAtManila.month.toString().padLeft(2, '0')}-${_performedAtManila.day.toString().padLeft(2, '0')}'),
              ),
              OutlinedButton.icon(
                onPressed: _submitting ? null : _pickTime,
                style: _pickerButtonStyle(),
                icon: const Icon(Icons.access_time_outlined, size: 18),
                label: Text(formatManilaClockTime(_performedAtManila)),
              ),
            ]),
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
      'Amount / volume',
      _textField(
        controller: _amountController,
        hint: '250',
        suffix: 'mL',
        numeric: true,
        required: false,
      ),
    );

    final reservoirVolumeField = _labeled(
      'Reservoir volume',
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
      padding: EdgeInsets.all(widget.dialogStyle ? 24 : 20),
      decoration: AppDecorations.card(radius: widget.dialogStyle ? 22 : 16),
      child: Form(
        key: _formKey,
        // Two columns only when the card is wide enough; otherwise stacked.
        child: LayoutBuilder(builder: (context, constraints) {
          final twoCol = constraints.maxWidth >= 420;
          Widget pair(Widget a, Widget b) => twoCol
              ? _twoColumns(a, b)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [a, const SizedBox(height: 16), b],
                );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Record a fix',
                            style: AppTextStyles.sectionTitle
                                .copyWith(fontSize: 20)),
                        const SizedBox(height: 4),
                        Text(
                          'Log an action you took so your history and forecasts stay accurate.',
                          style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (widget.dialogStyle) ...[
                    const SizedBox(width: 12),
                    _closeButton(),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              if (notification != null) ...[
                _alertStrip(notification),
                const SizedBox(height: 12),
              ],
              timestampField,
              const SizedBox(height: 16),
              Divider(color: AppColors.cardBorder, height: 1),
              const SizedBox(height: 16),
              pair(parameterField, currentValueField),
              const SizedBox(height: 16),
              actionField,
              const SizedBox(height: 18),
              _sectionLabel('OPTIONAL DETAILS'),
              const SizedBox(height: 8),
              pair(amountField, reservoirVolumeField),
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
                _errorBanner(_submissionError!),
                const SizedBox(height: 12),
              ],
              if (actionType == null && !_submitting)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('Choose an action to continue',
                        style: AppTextStyles.cardMeta),
                  ),
                ),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 8,
                children: [
                  CustomButton(
                    text: 'Cancel',
                    backgroundColor: AppColors.primaryButton,
                    textStyle: AppTextStyles.button.copyWith(
                      fontSize: 13,
                      color: AppColors.primaryButton,
                    ),
                    onPressed: _submitting ? null : widget.onCancel,
                    outlined: true,
                    width: 116,
                    height: 40,
                  ),
                  CustomButton(
                    text: 'Record fix',
                    backgroundColor: AppColors.primaryButton,
                    textStyle: AppTextStyles.button.copyWith(
                      fontSize: 13,
                      color: Colors.white,
                    ),
                    // The action type was already a required field; the
                    // button now just waits for it instead of showing an error.
                    onPressed:
                        (_submitting || actionType == null) ? null : _submit,
                    isLoading: _submitting,
                    width: 136,
                    height: 40,
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  // ---- header pieces --------------------------------------------------------

  Widget _closeButton() {
    return InkWell(
      onTap: _submitting ? null : widget.onCancel,
      customBorder: const CircleBorder(),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.pillBackground,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.close_rounded, size: 18, color: AppColors.textPrimary),
      ),
    );
  }

  Color _alertColor(NotificationType type) => type == NotificationType.critical
      ? AppColors.criticalRed
      : type == NotificationType.warning
          ? AppColors.warningYellow
          : AppColors.textSecondary;

  Color _alertTint(NotificationType type) => type == NotificationType.critical
      ? AppColors.alertBackground
      : type == NotificationType.warning
          ? AppColors.statusCardYellow
          : AppColors.surfaceMuted;

  /// Which alert this fix is for (only shown when opened from a notification).
  Widget _alertStrip(AppNotificationItem item) {
    final color = _alertColor(item.type);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _alertTint(item.type),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.type == NotificationType.critical
                ? Icons.error_outline
                : item.type == NotificationType.warning
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: 'For alert: ',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 12.5),
                ),
                TextSpan(
                  text: item.title,
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 12.5),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// Read-only timestamp (notification flow), shown as a small line instead of
  /// a full-width disabled input.
  Widget _loggedRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(Icons.calendar_today_outlined,
            size: 15, color: AppColors.textSecondary),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: 'Logged ', style: AppTextStyles.bodySmall),
            TextSpan(
              text: formatManilaDateTime(_performedAtManila),
              style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
            ),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.pillBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Read-only',
            style: AppTextStyles.cardMeta
                .copyWith(fontSize: 10.5, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: AppTextStyles.cardMeta.copyWith(
          fontSize: 10.5,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
        ),
      );

  Widget _errorBanner(String message) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.alertBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.alertBorder),
        ),
        child: Text(
          message,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.criticalRed),
        ),
      );

  ButtonStyle _pickerButtonStyle() => OutlinedButton.styleFrom(
        foregroundColor: AppColors.accentGreen,
        side: BorderSide(color: AppColors.inputBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  // ---- layout + field helpers ----------------------------------------------

  Widget _twoColumns(Widget left, Widget right) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 16),
          Expanded(child: right),
        ],
      );

  Widget _labeled(String label, Widget field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label.copyWith(fontSize: 13)),
          const SizedBox(height: 6),
          field,
        ],
      );

  Color get _fill => appThemeMode.value == ThemeMode.dark
      ? const Color(0xFF252D25)
      : AppColors.inputFill;

  InputDecoration _decoration({String? hint, String? suffix}) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
      borderRadius: BorderRadius.circular(14),
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
      // Fixed max width so the dialog sits in the middle instead of stretching
      // across the whole screen. On a phone it still uses the full width.
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: RecordFixCard(
            notification: notification,
            submissionError: submissionError,
            dialogStyle: true,
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
    ),
  );
}