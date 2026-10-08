import 'package:flutter/material.dart';
import '../screens/notifications_screen.dart';
import '../models/forecasting_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_mode_controller.dart';
import 'apply_fix_dialog.dart';

class SeverityStyle {
  final Color accent;
  final Color _lightTint, _darkTint;
  final Color _lightText, _darkText;
  final Color _lightBadge, _darkBadge;
  final IconData icon;

  const SeverityStyle({
    required this.accent,
    required Color lightTint,
    required Color darkTint,
    required Color lightText,
    required Color darkText,
    required Color lightBadge,
    required Color darkBadge,
    required this.icon,
  })  : _lightTint = lightTint,
        _darkTint = darkTint,
        _lightText = lightText,
        _darkText = darkText,
        _lightBadge = lightBadge,
        _darkBadge = darkBadge;

  static bool get _dark => appThemeMode.value == ThemeMode.dark;

  Color get tint => _dark ? _darkTint : _lightTint;
  Color get text => _dark ? _darkText : _lightText;
  Color get badgeFill => _dark ? _darkBadge : _lightBadge;

  bool get isAlert => icon != Icons.check_circle_rounded;

  static const critical = SeverityStyle(
    accent: Color(0xFFDC2626),
    lightTint: Color(0xFFFEF2F2),
    darkTint: Color(0xFF3B1F1F),
    lightText: Color(0xFFB91C1C),
    darkText: Color(0xFFFCA5A5),
    lightBadge: Color(0xFFFECACA),
    darkBadge: Color(0xFF5C2323),
    icon: Icons.error_rounded,
  );

  static const warning = SeverityStyle(
    accent: Color(0xFFD97706),
    lightTint: Color(0xFFFFFBEB),
    darkTint: Color(0xFF3A2F14),
    lightText: Color(0xFFB45309),
    darkText: Color(0xFFFCD34D),
    lightBadge: Color(0xFFFDE68A),
    darkBadge: Color(0xFF5A4410),
    icon: Icons.warning_amber_rounded,
  );

  static const normal = SeverityStyle(
    accent: Color(0xFF16A34A),
    lightTint: Color(0xFFF0FDF4),
    darkTint: Color(0xFF17301F),
    lightText: Color(0xFF15803D),
    darkText: Color(0xFF86EFAC),
    lightBadge: Color(0xFFBBF7D0),
    darkBadge: Color(0xFF1F4A2B),
    icon: Icons.check_circle_rounded,
  );

  static SeverityStyle fromBadge(String badge) {
    switch (badge.toLowerCase()) {
      case 'critical':
        return critical;
      case 'normal':
      case 'stable':
        return normal;
      case 'warning':
      default:
        return warning;
    }
  }
}

class PredictionInsightsCard extends StatelessWidget {
  final PredictionInsightDetail detail;
  final Future<void> Function() onApplyFix;
  final Future<void> Function() onDismiss;
  final bool showParamSelector;
  final String? selectedInsightParam;
  final ValueChanged<String>? onInsightParamChanged;

  const PredictionInsightsCard({
    super.key,
    required this.detail,
    required this.onApplyFix,
    required this.onDismiss,
    this.showParamSelector = false,
    this.selectedInsightParam,
    this.onInsightParamChanged,
  });

  List<InlineSpan> _highlightSpans(
    String text,
    String highlight,
    TextStyle base,
    TextStyle emphasis,
  ) {
    if (highlight.isEmpty || !text.contains(highlight)) {
      return [TextSpan(text: text, style: base)];
    }

    final parts = text.split(highlight);
    final spans = <InlineSpan>[];

    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        spans.add(TextSpan(text: parts[i], style: base));
      }
      if (i < parts.length - 1) {
        spans.add(TextSpan(text: highlight, style: emphasis));
      }
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final severity = SeverityStyle.fromBadge(detail.statusBadge);
    bool isPhTab = detail.statusLabel.contains('pH');
    String mainUnit = isPhTab ? '' : ' mS/cm';

    bool isNoRecommendation = detail.suggestedFixes.isEmpty ||
        (detail.suggestedFixes.length == 1 &&
            (detail.suggestedFixes.first.contains('No recommendation') ||
                detail.suggestedFixes.first.contains('No fix')));

    String secondaryLabel = isPhTab ? 'EC Level:' : 'pH Level:';
    IconData secondaryIcon = isPhTab ? Icons.bolt : Icons.science;

    const tolerance = 0.05;
    final delta = detail.currentPh - detail.targetPh;
    final IconData? directionIcon = delta > tolerance
        ? Icons.arrow_upward_rounded
        : (delta < -tolerance ? Icons.arrow_downward_rounded : null);

    final directionLabel = delta > tolerance
        ? 'above target'
        : (delta < -tolerance ? 'below target' : 'on target');

    final calloutBase = AppTextStyles.bodySmall.copyWith(
      color: AppColors.textPrimary,
      fontSize: 12.5,
    );

    final calloutEmphasis = calloutBase.copyWith(
      fontWeight: FontWeight.w700,
      color: severity.isAlert ? severity.text : AppColors.textPrimary,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Prediction Insights', style: AppTextStyles.sectionTitle),
              if (showParamSelector && onInsightParamChanged != null)
                _buildParamPill(),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 5, color: severity.accent),
                  Expanded(
                    child: Container(
                      color: severity.tint,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(severity.icon,
                                  size: 20, color: severity.text),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  detail.statusLabel,
                                  style: AppTextStyles.bodyBold
                                      .copyWith(fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: severity.badgeFill,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  detail.statusBadge,
                                  style: AppTextStyles.cardMeta.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: severity.text,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            detail.warningText,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: 16),
          Text('Contributing factors',
              style: AppTextStyles.bodyBold.copyWith(fontSize: 15)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.thermostat,
                      size: 18, color: AppColors.textPrimary),
                  const SizedBox(width: 6),
                  Text('Temperature:', style: AppTextStyles.body),
                ],
              ),
              Text(detail.temperature, style: AppTextStyles.bodyBold),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(secondaryIcon, size: 18, color: AppColors.textPrimary),
                  const SizedBox(width: 6),
                  Text(secondaryLabel, style: AppTextStyles.body),
                ],
              ),
              Text(detail.ecLevel, style: AppTextStyles.bodyBold),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.calloutBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text.rich(
              TextSpan(
                children: _highlightSpans(
                  detail.calloutText,
                  detail.temperature,
                  calloutBase,
                  calloutEmphasis,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Container(
                        color: severity.isAlert ? severity.tint : null,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current ${isPhTab ? 'pH' : 'EC'}',
                              style:
                                  AppTextStyles.cardMeta.copyWith(fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (directionIcon != null) ...[
                                  Semantics(
                                    label: directionLabel,
                                    child: Icon(
                                      directionIcon,
                                      size: 18,
                                      color: severity.isAlert
                                          ? severity.text
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                ],
                                Flexible(
                                  child: Text(
                                    '${detail.currentPh.toStringAsFixed(6)}$mainUnit',
                                    style: AppTextStyles.sectionTitle.copyWith(
                                      fontSize: 18,
                                      color: severity.isAlert
                                          ? severity.text
                                          : AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(width: 1, color: AppColors.cardBorder),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Target ${isPhTab ? 'pH' : 'EC'}',
                              style:
                                  AppTextStyles.cardMeta.copyWith(fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${detail.targetPh.toStringAsFixed(6)}$mainUnit',
                              style: AppTextStyles.sectionTitle.copyWith(
                                fontSize: 18,
                                color: AppColors.accentGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Suggested fix',
              style: AppTextStyles.bodyBold.copyWith(fontSize: 14)),
          const SizedBox(height: 6),
          if (isNoRecommendation)
            Text(
              'No recommendation for now',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            )
          else ...[
            for (final fix in detail.suggestedFixes)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        fix,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () => ActionConfirmationDialog.showApplyFix(
                        context,
                        onConfirm: onApplyFix,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryButton,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Apply fix',
                        style: AppTextStyles.button.copyWith(fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () => ActionConfirmationDialog.showDismissFix(
                        context,
                        onConfirm: onDismiss,
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryButton),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Dismiss',
                        style: AppTextStyles.button.copyWith(
                          fontSize: 14,
                          color: AppColors.primaryButton,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_outlined, size: 18),
                label: Text(
                  'See alerts',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.primaryButton,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParamPill() {
    final options = ['pH', 'EC'];
    final activeParam = selectedInsightParam ?? 'pH';

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.pillBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((p) {
          final isSelected = activeParam == p;
          return GestureDetector(
            onTap: () => onInsightParamChanged?.call(p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color:
                    isSelected ? AppColors.primaryButton : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                p,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.pillText,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
