import 'package:flutter/material.dart';

/// The single source of truth for the application's copyright and styling.
class AppFooter extends StatelessWidget {
  const AppFooter({super.key, this.text = copyrightText});

  /// Public pages may override the copy; all existing callers keep the default.
  final String text;

  static const year = 2026;
  static const copyrightText =
      '© $year Smart Decision Support System for Precision Hydroponics. All rights reserved.';
  static const _padding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);

  static TextStyle _style(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall!.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          );

  /// Space reserved by layouts whose cards normally fill the viewport.
  static double heightFor(BuildContext context, double width) {
    final painter = TextPainter(
      text: TextSpan(text: copyrightText, style: _style(context)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(
        maxWidth: (width - _padding.horizontal).clamp(1.0, double.infinity));
    final height = painter.height +
        _padding.vertical +
        MediaQuery.paddingOf(context).bottom;
    painter.dispose();
    return height;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        left: false,
        right: false,
        child: Padding(
          padding: _padding,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: _style(context),
          ),
        ),
      );
}

/// Keeps the footer in normal scrolling, filling unused viewport space.
/// Padding surrounds the whole page, including clearance for page FABs.
class AppFooterScrollView extends StatelessWidget {
  const AppFooterScrollView({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.centerContent = false,
    this.showFooter = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool centerContent;

  /// Set from the page's loading state when loading UI shares this layout.
  final bool showFooter;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final contentHeight = (constraints.maxHeight -
                  padding.vertical -
                  (showFooter
                      ? AppFooter.heightFor(
                          context, constraints.maxWidth - padding.horizontal)
                      : 0))
              .clamp(0.0, double.infinity);
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    padding.left, padding.top, padding.right,
                    showFooter ? 0 : padding.bottom),
                sliver: SliverToBoxAdapter(
                  child: centerContent
                      ? ConstrainedBox(
                          constraints: BoxConstraints(minHeight: contentHeight),
                          child: Center(child: child),
                        )
                      : child,
                ),
              ),
              if (showFooter) SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      padding.left, 0, padding.right, padding.bottom),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [AppFooter()],
                  ),
                ),
              ),
            ],
          );
        },
      );
}
