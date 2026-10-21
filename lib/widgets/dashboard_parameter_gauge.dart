import '../utils/manila_time.dart';
import 'sensor_offline_state.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'card_info_tooltip.dart';

import '../models/monitoring_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../services/app_state.dart';

class DashboardParameterGauge extends StatelessWidget {
  final ParameterStatus data;
  final bool compact;
  final bool dense;

  const DashboardParameterGauge({
    super.key,
    required this.data,
    this.compact = false,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appMeasurementUnits,
      builder: (context, units, child) => _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    if (data.isOffline) {
      final body = SensorOfflineBody(title: 'Sensor offline',
        message: data.latestRecordedAt == null ? data.lastUpdated
            : 'Last updated ${formatManilaDateTime(toManilaTime(data.latestRecordedAt!))}',
        detail: 'Ideal range $_rangeText', compact: dense);
      return Container(
        width: compact ? (MediaQuery.sizeOf(context).width - 88).clamp(240.0, 300.0) : double.infinity,
        padding: EdgeInsets.all(dense ? 10 : 14),
        decoration: BoxDecoration(color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          OfflineHeader(label: 'Offline', child: Text(_shortLabel(data.label),
            style: AppTextStyles.sectionTitle.copyWith(fontSize: dense ? 14 : 16))),
          const SizedBox(height: 6),
          if (dense) Expanded(child: LayoutBuilder(builder: (context, space) =>
            SingleChildScrollView(child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: space.maxHeight), child: body))))
          else SizedBox(height: 235 * (MediaQuery.textScalerOf(context).scale(14) / 14), child: body),
        ]));
    }
    final value = _displayNumber;
    final scale = _displayScale;
    final status = _displayStatus(data.status);
    final statusColor = _statusColor(data.status);

    return Container(
      width: compact
          ? (MediaQuery.sizeOf(context).width - 88).clamp(240.0, 300.0)
          : double.infinity,
      padding: EdgeInsets.all(dense ? 8 : (compact ? 12 : 16)),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CardInfoTitle(
                  _shortLabel(data.label),
                  description: 'Shows the latest ${_shortLabel(data.label)} reading and its condition relative to the configured range.',
                  style: AppTextStyles.sectionTitle.copyWith(
                    fontSize: dense ? 14 : (compact ? 15 : 17),
                    height: 1.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      status,
                      style: AppTextStyles.cardMeta.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: dense ? 5 : (compact ? 6 : 10)),
          if (dense)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 11,
                    child: _buildGauge(
                      context: context,
                      value: value,
                      scale: scale,
                      statusColor: statusColor,
                      valueFontSize: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 9,
                    child: Center(
                        child:
                            _buildMetadata(vertical: true, condensed: false)),
                  ),
                ],
              ),
            )
          else ...[
            _buildGauge(
              context: context,
              value: value,
              scale: scale,
              statusColor: statusColor,
              height: (compact ? 190 : 205) *
                  (MediaQuery.textScalerOf(context).scale(14) / 14),
              valueFontSize: compact ? 25 : 30,
            ),
            SizedBox(height: compact ? 10 : 14),
            Divider(height: 1, color: AppColors.cardBorder),
            const SizedBox(height: 10),
            _buildMetadata(vertical: false, condensed: compact),
          ],
        ],
      ),
    );
  }

  Widget _buildGauge({
    required BuildContext context,
    required double value,
    required _GaugeScale scale,
    required Color statusColor,
    double? height,
    required double valueFontSize,
  }) {
    if (data.isOffline) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sensors_off, color: AppColors.textSecondary, size: 34),
              const SizedBox(height: 8),
              Text('No data',
                  style: AppTextStyles.title
                      .copyWith(fontSize: valueFontSize, height: 1.1)),
              const SizedBox(height: 4),
              Text('Sensor offline', style: AppTextStyles.cardMeta),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Column(
        children: [
          // The painter owns only the arc and ticks. Text below never shares
          // its canvas, so full-precision EC values cannot collide with ticks.
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: CustomPaint(
                key: ValueKey('gauge-dial-${_shortLabel(data.label)}'),
                painter: _GaugePainter(
                  value: value,
                  minimum: scale.minimum,
                  maximum: scale.maximum,
                  color: statusColor,
                  backgroundColor: AppColors.cardBorder,
                  textColor: AppColors.textSecondary,
                  decimals: 0,
                  textScaler: MediaQuery.textScalerOf(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _valueText,
            key: ValueKey('gauge-reading-${_shortLabel(data.label)}'),
            textAlign: TextAlign.center,
            style: AppTextStyles.title
                .copyWith(fontSize: valueFontSize, height: 1.1),
          ),
          const SizedBox(height: 2),
          // Reserve the same unit line for pH as EC and temperature, keeping
          // all three dials aligned and equally sized.
          Text(
            _unitText.isEmpty ? ' ' : _unitText,
            key: ValueKey('gauge-unit-${_shortLabel(data.label)}'),
            textAlign: TextAlign.center,
            style: AppTextStyles.cardMeta
                .copyWith(fontWeight: FontWeight.w600, height: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata({
    required bool vertical,
    required bool condensed,
  }) {
    final range = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ideal range',
            style: AppTextStyles.cardMeta.copyWith(height: 1.2)),
        const SizedBox(height: 2),
        Text(
          _rangeText,
          style: AppTextStyles.bodyBold.copyWith(
            fontSize: 12,
            height: 1.2,
          ),
        ),
      ],
    );
    final updated = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.primaryButton,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text('Last updated',
                  style: AppTextStyles.cardMeta
                      .copyWith(fontSize: 11, height: 1.2)),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          data.lastUpdated,
          style: AppTextStyles.cardMeta.copyWith(
            fontSize: 11,
            height: 1.2,
          ),
        ),
      ],
    );

    if (vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          range,
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1, color: AppColors.cardBorder),
          ),
          updated,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: range),
        const SizedBox(width: 8),
        Expanded(child: updated),
      ],
    );
  }

  bool get _isTemp => _shortLabel(data.label) == 'Temperature';
  double get _rawValue => double.tryParse(data.currentValue) ?? 0;
  double get _displayNumber => _isTemp ? toDisplayTemp(_rawValue) : _rawValue;
  String get _valueText =>
      _isTemp ? toDisplayTemp(_rawValue).toStringAsFixed(1) : data.currentValue;
  String get _unitText => _isTemp ? tempUnit : data.unit;

  _GaugeScale get _displayScale {
    final base = _scaleFor(data.label, _rawValue);
    if (!_isTemp) return base;
    return _GaugeScale(
        toDisplayTemp(base.minimum), toDisplayTemp(base.maximum));
  }

  String get _rangeText {
    if (_isTemp) {
      final parts = data.idealRange.split(' - ');
      final lo = double.tryParse(parts.first);
      final hi = parts.length > 1 ? double.tryParse(parts[1]) : null;
      if (lo != null && hi != null) return formatTempRange(lo, hi);
    }
    return '${data.idealRange}${data.unit.isEmpty ? '' : ' ${data.unit}'}';
  }

  String _shortLabel(String label) {
    if (label.toLowerCase().contains('ph')) return 'pH';
    if (label.toLowerCase().contains('ec')) return 'EC';
    return 'Temperature';
  }

  String _displayStatus(String status) {
    return status.toLowerCase() == 'normal' ? 'Stable' : status;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'offline':
        return AppColors.textSecondary;
      case 'critical':
        return AppColors.alertText;
      case 'warning':
        return const Color(0xFFE79A08);
      default:
        return AppColors.primaryButton;
    }
  }

  _GaugeScale _scaleFor(String label, double value) {
    final lower = label.toLowerCase();
    if (lower.contains('ph')) return const _GaugeScale(0, 14);
    if (lower.contains('ec')) return const _GaugeScale(0, 3);
    return _GaugeScale(10, math.max(35, value.ceilToDouble() + 5));
  }
}

class _GaugeScale {
  final double minimum;
  final double maximum;

  const _GaugeScale(this.minimum, this.maximum);
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double minimum;
  final double maximum;
  final Color color;
  final Color backgroundColor;
  final Color textColor;
  final int decimals;
  final TextScaler textScaler;

  const _GaugePainter({
    required this.value,
    required this.minimum,
    required this.maximum,
    required this.color,
    required this.backgroundColor,
    required this.textColor,
    required this.decimals,
    required this.textScaler,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final minimumPainter = _textPainter(minimum.toStringAsFixed(decimals));
    final maximumPainter = _textPainter(maximum.toStringAsFixed(decimals));
    final tickHeight = math.max(minimumPainter.height, maximumPainter.height);
    // Fill the available semicircle area, reserving a complete tick-label row.
    // Unlike the former 0.36 * height radius, readings do not shrink the arc
    // twice: their space has already been allocated by the parent Column.
    final stroke = (size.width * 0.085).clamp(10.0, 18.0);
    final tickGap = stroke / 2 + 3;
    final radius = math.max(
        0.0,
        math.min(
          (size.width - stroke) / 2,
          size.height - tickHeight - tickGap - stroke / 2,
        ));
    final center = Offset(size.width / 2, radius + stroke / 2);
    const startAngle = math.pi;
    const sweepAngle = math.pi;
    final normalized = ((value - minimum) / (maximum - minimum)).clamp(0, 1);

    final trackPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    final arcRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(arcRect, startAngle, sweepAngle, false, trackPaint);
    canvas.drawArc(
      arcRect,
      startAngle,
      sweepAngle * normalized,
      false,
      valuePaint,
    );

    final needleAngle = startAngle + (sweepAngle * normalized);
    final needleEnd = Offset(
      center.dx + math.cos(needleAngle) * radius * 0.82,
      center.dy + math.sin(needleAngle) * radius * 0.82,
    );
    canvas.drawLine(
      center,
      needleEnd,
      Paint()
        ..color = AppColors.textPrimary
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      center,
      stroke * 0.5,
      Paint()..color = AppColors.textPrimary,
    );

    minimumPainter.paint(
      canvas,
      Offset(
        (center.dx - radius - (minimumPainter.width / 2))
            .clamp(0.0, math.max(0.0, size.width - minimumPainter.width)),
        center.dy + tickGap,
      ),
    );
    maximumPainter.paint(
      canvas,
      Offset(
        (center.dx + radius - (maximumPainter.width / 2))
            .clamp(0.0, math.max(0.0, size.width - maximumPainter.width)),
        center.dy + tickGap,
      ),
    );
  }

  TextPainter _textPainter(String text) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: AppTextStyles.cardMeta.copyWith(
          color: textColor,
          fontSize: 11,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.minimum != minimum ||
        oldDelegate.maximum != maximum ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.textScaler != textScaler ||
        oldDelegate.textColor != textColor;
  }
}
