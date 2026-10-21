import 'package:flutter/material.dart';
import '../../config/public_page_content.dart';
import '../../theme/public_page_styles.dart';
import '../../utils/responsive.dart';
import '../app_footer.dart';
import 'login_brand_panel.dart';
import 'public_brand.dart';

/// Shared viewport-fitting desktop layout and scrollable mobile auth layout.
/// Navigation is opt-in so verification/recovery steps remain focused.
class PublicAuthLayout extends StatelessWidget {
  const PublicAuthLayout(
      {super.key, required this.formBuilder, this.navigation, this.loginBenefits = false});

  final Widget Function(BuildContext context, bool compact, bool dense)
      formBuilder;
  final Widget? navigation;
  final bool loginBenefits;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: PublicPageStyles.theme(context),
      child: Builder(builder: (context) {
        return Scaffold(
          backgroundColor: PublicPageStyles.background,
          body: SafeArea(
            child: LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth < Responsive.mobileMaxWidth) {
                final nav = navigation is Align ? (navigation as Align).child : navigation;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 22, 12, 16),
                  child: Center(child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Row(children: [
                        const Expanded(
                          child: PublicBrand(size: 36, nameSize: 20, mobileAuth: true)),
                        if (nav != null) ...[
                          const SizedBox(width: 12),
                          nav,
                        ],
                      ]),
                      const SizedBox(height: 26),
                      MobileAuthPresentation(
                        minimumFormHeight: (constraints.maxHeight - (nav == null ? 100 : 112))
                            .clamp(0.0, double.infinity),
                        child: formBuilder(context, true, true)),
                    ]),
                  )),
                );
              }
              final desktop = constraints.maxWidth >= Responsive.tabletMaxWidth;
              final padding = constraints.maxWidth < Responsive.mobileMaxWidth
                  ? 16.0
                  : 20.0;
              final pageWidth = (constraints.maxWidth - padding * 2)
                  .clamp(0.0, 1800.0)
                  .toDouble();
              final fitDesktop = desktop &&
                  constraints.maxHeight >= 560 &&
                  MediaQuery.textScalerOf(context).scale(16) <= 21;
              if (fitDesktop) {
                // Both columns are bounded by the browser's available height.
                return Padding(
                  padding: EdgeInsets.all(padding),
                  child: Center(
                    child: SizedBox(
                      width: pageWidth,
                      height: double.infinity,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 45,
                            child: LoginBrandPanel(fitViewport: true, showBenefits: loginBenefits),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 55,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (navigation != null) navigation!,
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                    child: LayoutBuilder(
                                      builder: (context, space) => Center(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: SizedBox(
                                            width: space.maxWidth
                                                .clamp(
                                                    0.0,
                                                    PublicPageStyles
                                                        .contentWidth)
                                                .toDouble(),
                                            child: formBuilder(context, false,
                                                space.maxHeight < 650),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const AppFooter(
                                    text: PublicPageContent.copyright),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              // Keep keyboard access and enlarged text usable on small windows.
              return SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const LoginBrandPanel(compact: true),
                        const SizedBox(height: 12),
                        if (navigation != null) navigation!,
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child:
                              Center(child: formBuilder(context, true, false)),
                        ),
                        const AppFooter(text: PublicPageContent.copyright),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

/// Scoped to phone auth pages so tablet and desktop presentation is unchanged.
class MobileAuthPresentation extends InheritedWidget {
  const MobileAuthPresentation({super.key, required this.minimumFormHeight, required super.child});
  final double minimumFormHeight;
  static MobileAuthPresentation? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MobileAuthPresentation>();
  @override
  bool updateShouldNotify(MobileAuthPresentation oldWidget) =>
      minimumFormHeight != oldWidget.minimumFormHeight;
}
