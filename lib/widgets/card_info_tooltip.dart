import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Uses the same hover/tap tooltip behavior as Predicted vs actual.
class CardInfoTooltip extends StatefulWidget {
  const CardInfoTooltip({super.key, required this.description});
  final String description;

  @override
  State<CardInfoTooltip> createState() => _CardInfoTooltipState();
}

class _CardInfoTooltipState extends State<CardInfoTooltip> {
  final _tooltipKey = GlobalKey<TooltipState>();

  @override
  Widget build(BuildContext context) => Tooltip(
    key: _tooltipKey,
    message: widget.description,
    triggerMode: TooltipTriggerMode.tap,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    child: InkWell(
      onTap: () => _tooltipKey.currentState?.ensureTooltipVisible(),
      borderRadius: BorderRadius.circular(8),
      child: Icon(Icons.info_outline, size: 16, color: AppColors.accentGreen),
    ),
  );
}

/// An inline icon keeps the title's existing line height and text style.
class CardInfoTitle extends StatelessWidget {
  const CardInfoTitle(this.title, {
    super.key, required this.description, this.style,
  });
  final String title;
  final String? description;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => description == null
      ? Text(title, style: style)
      : Text.rich(
    TextSpan(children: [
      TextSpan(text: title),
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: CardInfoTooltip(description: description!),
        ),
      ),
    ]),
    style: style,
  );
}
