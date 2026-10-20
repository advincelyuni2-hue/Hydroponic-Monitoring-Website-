import 'package:flutter/material.dart';
import '../../theme/public_page_styles.dart';

/// Consistent content width and responsive spacing for the landing page.
class PublicSection extends StatelessWidget {
  const PublicSection(
      {super.key, required this.child, this.color, this.verticalPadding = 64});

  final Widget child;
  final Color? color;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: color ?? PublicPageStyles.background,
        child: LayoutBuilder(builder: (context, space) {
          final small = space.maxWidth < 700;
          return Padding(
            padding: EdgeInsets.symmetric(
                horizontal: small ? 20 : 48,
                vertical: small ? verticalPadding * .6 : verticalPadding),
            child: Center(
                child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: SizedBox(width: double.infinity, child: child),
            )),
          );
        }),
      );
}

class PublicSectionHeading extends StatelessWidget {
  const PublicSectionHeading(
      {super.key,
      required this.eyebrow,
      required this.title,
      this.description});
  final String eyebrow;
  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow,
              style: PublicPageStyles.label.copyWith(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  color: PublicPageStyles.green)),
          const SizedBox(height: 12),
          Text(title,
              style: PublicPageStyles.heading.copyWith(
                  fontSize: MediaQuery.sizeOf(context).width < 700 ? 28 : 36,
                  height: 1.2,
                  letterSpacing: -.8)),
          if (description != null) ...[
            const SizedBox(height: 18),
            Text(description!, style: PublicPageStyles.body),
          ],
        ],
      );
}

/// A wrapping grid with natural card heights, including enlarged text.
class PublicCardGrid extends StatelessWidget {
  const PublicCardGrid(
      {super.key,
      required this.children,
      this.columns = 3,
      this.minimumCardWidth = 230,
      this.spacing = 20});
  final List<Widget> children;
  final int columns;
  final double minimumCardWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, space) {
        final count =
            ((space.maxWidth + spacing) / (minimumCardWidth + spacing))
                .floor()
                .clamp(1, columns);
        final width = (space.maxWidth - spacing * (count - 1)) / count;
        return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: children
                .map((child) => SizedBox(width: width, child: child))
                .toList());
      });
}
