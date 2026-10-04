import 'dart:math' as math;

import 'package:flutter/material.dart';

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
      builder: (context, units, child) => _buildCard(),
    );
  }

  Widget _buildCard() {
    final value = _displayNumber;
    final scale = _displayScale;
    final status = _displayStatus(data.status);
    final statusColor = _statusColor(data.status);

    return Container(
      width: compact ? 190 : double.infinity,
      padding: EdgeInsets.all(dense ? 10 : (compact ? 12 : 16)),
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
                child: Text(
                  _shortLabel(data.label),
                  style: AppTextStyles.sectionTitle.copyWith(
                    fontSize: dense ? 14 : (compact ? 15 : 17),
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
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: dense ? 5 : (compact ? 6 : 10)),
          if (dense)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 11,
                  child: _buildGauge(
                    value: value,
                    scale: scale,
                    statusColor: statusColor,
                    height: 140,
                    valueFontSize: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 9,
                  child: _buildMetadata(vertical: true, condensed: false),
                ),
              ],
            )
          else ...[
            _buildGauge(
              value: value,
              scale: scale,
              statusColor: statusColor,
              height: compact ? 120 : 155,
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
    required double value,
    required _GaugeScale scale,
    required Color statusColor,
    required double height,
    required double valueFontSize,
  }) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _GaugePainter(
                value: value,
                minimum: scale.minimum,
                maximum: scale.maximum,
                color: statusColor,
                backgroundColor: AppColors.cardBorder,
                textColor: AppColors.textSecondary,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                data.currentValue,
                style: AppTextStyles.title.copyWith(fontSize: valueFontSize),
              ),
              if (data.unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    data.unit,
                    style: AppTextStyles.cardMeta.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
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
        Text('Ideal range', style: AppTextStyles.cardMeta),
        const SizedBox(height: 2),
        Text(
          _rangeText,
          style: AppTextStyles.bodyBold.copyWith(
            fontSize: condensed ? 12 : 13,
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
              child: Text('Last updated', style: AppTextStyles.cardMeta),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          data.lastUpdated,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.cardMeta.copyWith(
            fontSize: condensed ? 10 : 11,
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
            padding: const EdgeInsets.symmetric(vertical: 10),
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
    return _GaugeScale(toDisplayTemp(base.minimum), toDisplayTemp(base.maximum));
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

  const _GaugePainter({
    required this.value,
    required this.minimum,
    required this.maximum,
    required this.color,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.62);
    final radius = math.min(size.width * 0.38, size.height * 0.50);
    const startAngle = math.pi;
    const sweepAngle = math.pi;
    final normalized = ((value - minimum) / (maximum - minimum)).clamp(0, 1);

    final trackPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.14
      ..strokeCap = StrokeCap.butt;
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.14
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
      size.height * 0.075,
      Paint()..color = AppColors.textPrimary,
    );

    final minimumText = minimum.toStringAsFixed(0);
    final minimumPainter = _textPainter(minimumText);
    minimumPainter.paint(
      canvas,
      Offset(
        center.dx - radius - (minimumPainter.width / 2),
        center.dy + 8,
      ),
    );
    final maximumText = maximum.toStringAsFixed(0);
    final painter = _textPainter(maximumText);
    painter.paint(
      canvas,
      Offset(
        center.dx + radius - (painter.width / 2),
        center.dy + 8,
      ),
    );
  }

  TextPainter _textPainter(String text) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: textColor, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.minimum != minimum ||
        oldDelegate.maximum != maximum ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
