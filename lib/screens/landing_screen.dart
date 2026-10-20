import 'package:flutter/material.dart';
import '../config/public_page_content.dart';
import '../theme/public_page_styles.dart';
import '../widgets/public_pages/landing_sections.dart';
import '../widgets/public_pages/public_brand.dart';

/// Public study information. No authenticated data or backend requests.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key, required this.onLogin});
  final VoidCallback onLogin;

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _scrollController = ScrollController();
  final _sectionKeys = <String, GlobalKey>{
    for (final item in PublicPageContent.landingNavigation)
      item.id: GlobalKey(),
  };

  void _scrollTo(String section) {
    final target = _sectionKeys[section]?.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: MediaQuery.of(context).disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
        data: PublicPageStyles.theme(context),
        child: Scaffold(
          backgroundColor: PublicPageStyles.background,
          body: SafeArea(
              child: Column(children: [
            _navigation(),
            Expanded(
                child: Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LandingHero(
                        onLogin: widget.onLogin, onHow: () => _scrollTo('how')),
                    LandingWhy(key: _sectionKeys['why']),
                    LandingHow(key: _sectionKeys['how']),
                    LandingFeatures(key: _sectionKeys['features']),
                    LandingExperiment(key: _sectionKeys['experiment']),
                    LandingPartnership(key: _sectionKeys['partnership']),
                    LandingResearch(key: _sectionKeys['research']),
                    const LandingFooter(),
                  ],
                ),
              ),
            )),
          ])),
        ),
      );

  Widget _navigation() => LayoutBuilder(builder: (context, space) {
        final fullNavigation = space.maxWidth >= 1160 &&
            MediaQuery.textScalerOf(context).scale(16) <= 20;
        return Container(
          color: PublicPageStyles.background,
          padding: EdgeInsets.symmetric(
              horizontal: space.maxWidth < 700 ? 20 : 48, vertical: 12),
          child: Center(
              child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Row(children: [
              Expanded(
                  child: PublicBrand(
                      size: 36, nameSize: 22, showName: space.maxWidth >= 450)),
              if (fullNavigation)
                for (final item in PublicPageContent.landingNavigation)
                  TextButton(
                      onPressed: () => _scrollTo(item.id),
                      style: TextButton.styleFrom(
                          foregroundColor: PublicPageStyles.ink,
                          textStyle:
                              PublicPageStyles.label.copyWith(fontSize: 13)),
                      child: Text(item.label)),
              if (!fullNavigation)
                PopupMenuButton<String>(
                  tooltip: PublicPageContent.navigationMenu,
                  icon: const Icon(Icons.menu, color: PublicPageStyles.green),
                  onSelected: _scrollTo,
                  itemBuilder: (_) => [
                    for (final item in PublicPageContent.landingNavigation)
                      PopupMenuItem(value: item.id, child: Text(item.label)),
                  ],
                ),
              const SizedBox(width: 12),
              OutlinedButton(
                  onPressed: widget.onLogin,
                  style: OutlinedButton.styleFrom(
                      foregroundColor: PublicPageStyles.green,
                      side: const BorderSide(color: PublicPageStyles.green),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 16)),
                  child: const Text(PublicPageContent.loginButton)),
            ]),
          )),
        );
      });
}
