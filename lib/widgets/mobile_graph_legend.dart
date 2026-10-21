import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';

/// Compact, aligned legend rows for the mobile graph details cards.
class MobileGraphLegendRows extends StatelessWidget {
  const MobileGraphLegendRows({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(children: [
    for (var i = 0; i < children.length; i++) ...[
      if (i > 0) const Divider(height: 1, color: Color(0xFFEEEEDF)),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: children[i]),
    ],
  ]);
}

class MobileLegendMark extends StatelessWidget {
  const MobileLegendMark({super.key, required this.color, this.dashed = false,
    this.dot = false});
  final Color color;
  final bool dashed;
  final bool dot;

  @override
  Widget build(BuildContext context) => SizedBox(width: 30, height: 14,
    child: Center(child: dot
      ? Container(width: 12, height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle))
      : dashed
        ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (var i = 0; i < 4; i++)
              Container(width: 6, height: 3, color: color),
          ])
        : Container(height: 3, color: color)));
}

class MobileForecastLegend extends StatelessWidget {
  const MobileForecastLegend({super.key, required this.parameter,
    required this.phColor, required this.ecColor, this.estimated = false});
  final String parameter;
  final Color phColor;
  final Color ecColor;
  final bool estimated;

  @override
  Widget build(BuildContext context) => MobileGraphLegendRows(children: [
    if (parameter != 'EC') _row('pH', phColor),
    if (parameter != 'pH') _row('EC', ecColor),
  ]);

  Widget _row(String label, Color color) => Row(children: [
    Container(width: 10, height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 7),
    SizedBox(width: 30, child: Text(label,
      style: AppTextStyles.cardMeta.copyWith(fontWeight: FontWeight.w700))),
    Expanded(child: _entry(color, estimated ? 'Estimated' : 'Measured', false)),
    const SizedBox(width: 8),
    Expanded(child: _entry(color, 'Forecast', true)),
  ]);

  Widget _entry(Color color, String label, bool dashed) => Row(children: [
    MobileLegendMark(color: color, dashed: dashed),
    const SizedBox(width: 6),
    Expanded(child: Text(label, style: AppTextStyles.cardMeta.copyWith(fontSize: 12))),
  ]);
}
