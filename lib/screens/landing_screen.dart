import 'package:flutter/material.dart';
import '../config/public_page_content.dart';
import '../theme/public_page_styles.dart';
import '../utils/responsive.dart';
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
  bool _mobileMenuExpanded = false;
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
        if (space.maxWidth < Responsive.mobileMaxWidth) {
          return _mobileNavigation();
        }
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

  Widget _mobileNavigation() => Container(
        constraints: BoxConstraints(
          maxHeight: (MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).vertical) *
              0.85,
        ),
        decoration: BoxDecoration(
          color: PublicPageStyles.background,
          borderRadius: _mobileMenuExpanded
              ? const BorderRadius.vertical(bottom: Radius.circular(24))
              : null,
          boxShadow: _mobileMenuExpanded
              ? const [BoxShadow(color: Color(0x18000000), blurRadius: 12,
                  offset: Offset(0, 4))]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                const Expanded(child: PublicBrand(size: 28, nameSize: 16)),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: _mobileMenuExpanded
                      ? 'Close navigation'
                      : PublicPageContent.navigationMenu,
                  style: IconButton.styleFrom(
                    backgroundColor: PublicPageStyles.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => setState(
                      () => _mobileMenuExpanded = !_mobileMenuExpanded),
                  icon: Icon(_mobileMenuExpanded ? Icons.close : Icons.menu),
                ),
              ]),
            ),
            if (_mobileMenuExpanded)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        child: Text('EXPLORE', style: PublicPageStyles.label.copyWith(
                          color: PublicPageStyles.green, fontSize: 10,
                          letterSpacing: 1.5)),
                      ),
                      for (final item in PublicPageContent.landingNavigation)
                        DecoratedBox(
                          decoration: const BoxDecoration(border: Border(
                            bottom: BorderSide(color: Color(0xFFECECEC)))),
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: PublicPageStyles.ink,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                              alignment: Alignment.centerLeft,
                              shape: const RoundedRectangleBorder(),
                            ),
                            onPressed: () {
                              setState(() => _mobileMenuExpanded = false);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) _scrollTo(item.id);
                              });
                            },
                            child: Row(children: [
                              Expanded(child: Text(item.label)),
                              const Icon(Icons.chevron_right, size: 18,
                                color: Color(0xFF8A9383)),
                            ]),
                          ),
                        ),
                      const SizedBox(height: 16),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: PublicPageStyles.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: widget.onLogin,
                        child: const Text(PublicPageContent.loginButton),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
}
