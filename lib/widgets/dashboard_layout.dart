import 'app_footer.dart';
import 'package:flutter/material.dart';

/// Presentation-only shell; the header is measured before allocating the body.
class DashboardLayout extends StatelessWidget {
  const DashboardLayout({
    super.key,
    required this.header,
    required this.realtime,
    required this.insight,
    required this.overview,
  });

  final Widget header;
  final Widget realtime;
  final Widget insight;
  final Widget overview;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, viewport) {
      final desktop = viewport.maxWidth >= 1150;
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      return Padding(
        padding: EdgeInsets.all(viewport.maxWidth < 600 ? 16 : 24),
        child: Column(
          children: [
            header,
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(builder: (context, body) {
                if (!desktop || scale > 1.2) {
                  return AppFooterScrollView(
                    child: Column(
                      children: [
                        realtime,
                        const SizedBox(height: 16),
                        insight,
                        const SizedBox(height: 16),
                        overview,
                      ],
                    ),
                  );
                }
                // Short windows scroll instead of compressing readable cards.
                final height = (body.maxHeight -
                        AppFooter.heightFor(context, body.maxWidth))
                    .clamp(640.0 * scale, double.infinity);
                return AppFooterScrollView(
                  child: SizedBox(
                    height: height,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 3, child: realtime),
                        const SizedBox(width: 18),
                        Expanded(
                          flex: 7,
                          child: Column(
                            children: [
                              insight,
                              const SizedBox(height: 16),
                              Expanded(child: overview),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    });
  }
}
