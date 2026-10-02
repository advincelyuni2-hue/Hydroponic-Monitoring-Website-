import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_mode_controller.dart';
import '../utils/responsive.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';

// ---------------------------------------------------------------------
// Screen (desktop / web page)
// ---------------------------------------------------------------------

class AddLogScreen extends StatelessWidget {
  const AddLogScreen({super.key});

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
                onCancel: () => Navigator.of(context).maybePop(),
                onSubmit: (entry) {
                  // TODO: save with your service, e.g. LogService().addFix(entry)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fix recorded.')),
                  );
                  Navigator.of(context).maybePop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------

class FixEntry {
  final String parameter;
  final double currentValue;
  final String actionType;
  final double amount;
  final String notes;

  const FixEntry({
    required this.parameter,
    required this.currentValue,
    required this.actionType,
    required this.amount,
    required this.notes,
  });
}

// ---------------------------------------------------------------------
// Reusable form card (used by the page AND the mobile dialog)
// ---------------------------------------------------------------------

class RecordFixCard extends StatefulWidget {
  final VoidCallback onCancel;
  final ValueChanged<FixEntry> onSubmit;

  const RecordFixCard({
    super.key,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  State<RecordFixCard> createState() => _RecordFixCardState();
}

class _RecordFixCardState extends State<RecordFixCard> {
  static const _parameters = ['pH', 'EC', 'Temperature'];
  static const _units = {'pH': 'pH', 'EC': 'mS/cm', 'Temperature': '°C'};
  static const _actions = {
    'pH': ['pH Up', 'pH Down', 'Other'],
    'EC': ['Add Nutrient', 'Add Water', 'Other'],
    'Temperature': ['Add Water', 'Other'],
  };

  final _formKey = GlobalKey<FormState>();
  final _currentValueController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String? _parameter;
  String? _actionType;

  @override
  void dispose() {
    _currentValueController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(FixEntry(
      parameter: _parameter!,
      currentValue: double.parse(_currentValueController.text),
      actionType: _actionType!,
      amount: double.parse(_amountController.text),
      notes: _notesController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    final parameterField = _labeled(
      'Parameter',
      _dropdown(
        hint: 'Select parameter',
        value: _parameter,
        items: _parameters,
        onChanged: (v) => setState(() {
          _parameter = v;
          _actionType = null; // actions depend on the parameter
        }),
      ),
    );

    final currentValueField = _labeled(
      'Current value',
      _textField(
        controller: _currentValueController,
        hint: '7.2',
        suffix: _units[_parameter] ?? '',
        numeric: true,
      ),
    );

    final actionField = _labeled(
      'Type of action',
      _dropdown(
        hint: 'Select action',
        value: _actionType,
        items: _actions[_parameter] ?? const [],
        onChanged: (v) => setState(() => _actionType = v),
      ),
    );

    final amountField = _labeled(
      'Amount / volume',
      _textField(
        controller: _amountController,
        hint: '250',
        suffix: 'mL',
        numeric: true,
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

            if (isMobile) ...[
              parameterField,
              const SizedBox(height: 16),
              currentValueField,
              const SizedBox(height: 16),
              actionField,
              const SizedBox(height: 16),
              amountField,
            ] else ...[
              _twoColumns(parameterField, currentValueField),
              const SizedBox(height: 16),
              _twoColumns(actionField, amountField),
            ],

            const SizedBox(height: 16),
            _labeled(
              'Notes',
              _textField(
                controller: _notesController,
                hint: 'Added after the 8:00 AM reading',
                maxLines: 4,
                required: false,
              ),
            ),
            const SizedBox(height: 20),

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
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryButton,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text('Record fix',
                        style: AppTextStyles.button.copyWith(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Layout helpers
  // ---------------------------------------------------------------------

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

  // ---------------------------------------------------------------------
  // Field builders (theme-aware: correct in light AND dark mode)
  // ---------------------------------------------------------------------

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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        if (!required) return null;
        if (value == null || value.trim().isEmpty) return 'Required';
        if (numeric && double.tryParse(value) == null) return 'Enter a number';
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
      hint: Text(hint,
          style:
              AppTextStyles.input.copyWith(color: AppColors.textSecondary)),
      style: AppTextStyles.input,
      dropdownColor: AppColors.cardBackground,
      iconEnabledColor: AppColors.textPrimary,
      decoration: _decoration(),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Required' : null,
    );
  }
}

// ---------------------------------------------------------------------
// Mobile: same form shown as a dialog (your second screenshot)
// ---------------------------------------------------------------------

Future<void> showRecordFixDialog(
  BuildContext context, {
  required ValueChanged<FixEntry> onSubmit,
}) {
  return showDialog(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: RecordFixCard(
          onCancel: () => Navigator.of(dialogContext).pop(),
          onSubmit: (entry) {
            Navigator.of(dialogContext).pop();
            onSubmit(entry);
          },
        ),
      ),
    ),
  );
}