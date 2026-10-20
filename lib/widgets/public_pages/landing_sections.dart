import 'package:flutter/material.dart';
import '../../config/public_page_content.dart';
import '../../theme/public_page_styles.dart';
import '../app_footer.dart';
import 'public_image_placeholder.dart';
import 'public_section.dart';

class LandingHero extends StatelessWidget {
  const LandingHero({super.key, required this.onLogin, required this.onHow});
  final VoidCallback onLogin;
  final VoidCallback onHow;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
          colors: [PublicPageStyles.forest, PublicPageStyles.green],
        )),
        child: PublicSection(
          color: Colors.transparent,
          child: _Split(
            first:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.white30),
                    borderRadius: BorderRadius.circular(24)),
                child: Text(PublicPageContent.landingBadge,
                    style: PublicPageStyles.meta.copyWith(color: Colors.white)),
              ),
              const SizedBox(height: 26),
              // EDIT TEXT HERE: Landing heading and description.
              Text.rich(
                  const TextSpan(children: [
                    TextSpan(text: PublicPageContent.loginHeroHeading),
                    TextSpan(
                        text: PublicPageContent.loginHeroHighlight,
                        style: TextStyle(color: PublicPageStyles.lime)),
                  ]),
                  style: PublicPageStyles.heading.copyWith(
                      fontSize:
                          MediaQuery.sizeOf(context).width < 700 ? 38 : 58,
                      height: 1.1,
                      letterSpacing: -1.8,
                      color: Colors.white)),
              const SizedBox(height: 26),
              Text(PublicPageContent.landingDescription,
                  style: PublicPageStyles.body
                      .copyWith(color: PublicPageStyles.placeholder)),
              const SizedBox(height: 24),
              Wrap(spacing: 12, runSpacing: 12, children: [
                FilledButton(
                    onPressed: onLogin,
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: PublicPageStyles.ink,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 26, vertical: 20)),
                    child: const Text(PublicPageContent.loginButton)),
                OutlinedButton(
                    onPressed: onHow,
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 26, vertical: 20)),
                    child: const Text(PublicPageContent.seeHowItWorks)),
              ]),
              const SizedBox(height: 28),
              Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: PublicPageContent.heroFacts
                      .map((fact) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.white24),
                                borderRadius: BorderRadius.circular(10)),
                            child: Text(fact,
                                style: PublicPageStyles.meta
                                    .copyWith(color: Colors.white)),
                          ))
                      .toList()),
            ]),
            // REPLACE IMAGE HERE: Local dashboard and alert screenshots.
            // REPLACE IMAGE HERE: Local dashboard and alert screenshots (2x2 grid).
second: SizedBox(
  height: MediaQuery.sizeOf(context).width < 800 ? 320 : 440,
  child: const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: PublicImagePlaceholder(
                label: PublicPageContent.alertScreenshotLabel,
                assetPath: PublicPageContent.alertScreenshotAsset,
                aspectRatio: 1.4,
                icon: null,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: PublicImagePlaceholder(
                label: PublicPageContent.dashboardScreenshotLabel,
                assetPath: PublicPageContent.dashboardScreenshotAsset,
                aspectRatio: 1.4,
                icon: null,
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 16),
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                        Expanded(
              child: PublicImagePlaceholder(
                label: PublicPageContent.extraScreenshotLabel1,
                assetPath: PublicPageContent.extraScreenshotAsset1,
                aspectRatio: 1.4,
                icon: null,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: PublicImagePlaceholder(
                label: PublicPageContent.extraScreenshotLabel2,
                assetPath: PublicPageContent.extraScreenshotAsset2,
                aspectRatio: 1.4,
                icon: null,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
),
          ),
        ),
      );
}

class LandingWhy extends StatelessWidget {
  const LandingWhy({super.key});
  @override
  Widget build(BuildContext context) => const PublicSection(
          child: _Split(
        first: PublicImagePlaceholder(
            label: PublicPageContent.farmLabel,
            assetPath: PublicPageContent.farmAsset,
            aspectRatio: 1.55),
        second: PublicSectionHeading(
            eyebrow: PublicPageContent.whyEyebrow,
            title: PublicPageContent.whyHeading,
            description: PublicPageContent.whyDescription),
      ));
}

class LandingHow extends StatelessWidget {
  const LandingHow({super.key});
  @override
  Widget build(BuildContext context) => PublicSection(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PublicSectionHeading(
              eyebrow: PublicPageContent.howEyebrow,
              title: PublicPageContent.howHeading),
          const SizedBox(height: 32),
          PublicCardGrid(children: [
            for (var i = 0; i < PublicPageContent.steps.length; i++)
              _InfoCard(
                leading: Text('${i + 1}',
                    style: PublicPageStyles.heading
                        .copyWith(fontSize: 32, color: PublicPageStyles.green)),
                title: PublicPageContent.steps[i].title,
                description: PublicPageContent.steps[i].description,
              ),
          ]),
        ],
      ));
}

class LandingFeatures extends StatelessWidget {
  const LandingFeatures({super.key});
  static const _icons = [
    Icons.monitor_heart_outlined,
    Icons.trending_up,
    Icons.notifications_none,
    Icons.schedule
  ];
  @override
  Widget build(BuildContext context) => PublicSection(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PublicSectionHeading(
              eyebrow: PublicPageContent.featuresEyebrow,
              title: PublicPageContent.featuresHeading),
          const SizedBox(height: 32),
          PublicCardGrid(columns: 4, children: [
            for (var i = 0; i < PublicPageContent.features.length; i++)
              _InfoCard(
                leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: PublicPageStyles.placeholder,
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(_icons[i % _icons.length],
                        color: PublicPageStyles.green)),
                title: PublicPageContent.features[i].title,
                description: PublicPageContent.features[i].description,
              ),
          ]),
        ],
      ));
}

class LandingExperiment extends StatelessWidget {
  const LandingExperiment({super.key});
  @override
  Widget build(BuildContext context) => PublicSection(
        color: const Color(0xFFF0F5E2),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const PublicSectionHeading(
              eyebrow: PublicPageContent.experimentEyebrow,
              title: PublicPageContent.experimentHeading,
              description: PublicPageContent.experimentDescription),
          const SizedBox(height: 32),
          // REPLACE IMAGE HERE: Full setup and experiment progress photographs.
          _Split(
            gap: 16,
            first: const PublicImagePlaceholder(
                label: PublicPageContent.experimentMainLabel,
                assetPath: PublicPageContent.experimentMainAsset,
                aspectRatio: 1.16),
            second: PublicCardGrid(
              columns: 2,
              minimumCardWidth: 150,
              spacing: 16,
              children: [
                for (final photo in PublicPageContent.experimentPhotos)
                  PublicImagePlaceholder(
                      label: photo.label,
                      assetPath: photo.assetPath,
                      aspectRatio: 1.16)
              ],
            ),
          ),
        ]),
      );
}

class LandingPartnership extends StatelessWidget {
  const LandingPartnership({super.key});
  @override
  Widget build(BuildContext context) => PublicSection(
        verticalPadding: 48,
        child: Container(
          padding:
              EdgeInsets.all(MediaQuery.sizeOf(context).width < 700 ? 24 : 40),
          decoration: BoxDecoration(
              color: PublicPageStyles.placeholder,
              borderRadius: BorderRadius.circular(24)),
          child: LayoutBuilder(builder: (context, space) {
            // EDIT HERE: Partner office information and endorsement.
            final description =
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const PublicSectionHeading(
                  eyebrow: PublicPageContent.partnerEyebrow,
                  title: PublicPageContent.partnerHeading,
                  description: PublicPageContent.partnerDescription),
              const SizedBox(height: 12),
              Text(PublicPageContent.partnerQuote,
                  style: PublicPageStyles.body
                      .copyWith(fontStyle: FontStyle.italic)),
            ]);
            const logo = SizedBox(
                width: 96,
                height: 96,
                child: PublicImagePlaceholder(
                    label: PublicPageContent.partnerLogoLabel,
                    assetPath: PublicPageContent.partnerLogoAsset,
                    aspectRatio: 1,
                    icon: null));
            if (space.maxWidth < 600) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [logo, const SizedBox(height: 24), description]);
            }
            return Row(children: [
              logo,
              const SizedBox(width: 32),
              Expanded(child: description)
            ]);
          }),
        ),
      );
}

class LandingResearch extends StatelessWidget {
  const LandingResearch({super.key});

  @override
  Widget build(BuildContext context) => PublicSection(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PublicSectionHeading(
        eyebrow: PublicPageContent.researchEyebrow,
        title: PublicPageContent.researchHeading),
      const SizedBox(height: 28),
      _panel(
          title: 'Study details',
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (var i = 0; i < PublicPageContent.studyDetails.length; i++) ...[
              if (i > 0) const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: PublicPageStyles.border)),
              LayoutBuilder(builder: (context, space) {
                final detail = PublicPageContent.studyDetails[i];
                final label = Text(detail.label, style: PublicPageStyles.meta);
                final value = Text(detail.value, style: PublicPageStyles.body.copyWith(
                  color: PublicPageStyles.ink, fontWeight: FontWeight.w500));
                if (space.maxWidth < 380 || MediaQuery.textScalerOf(context).scale(14) > 20) {
                  return Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [label, const SizedBox(height: 6), value]);
                }
                return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 120, child: label),
                  const SizedBox(width: 16),
                  Expanded(child: value),
                ]);
              }),
            ],
          ]),
        ),
    ]),
  );

  Widget _panel({required String title, required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: Colors.white,
      border: Border.all(color: PublicPageStyles.border),
      borderRadius: BorderRadius.circular(20)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: PublicPageStyles.heading.copyWith(fontSize: 20)),
      const SizedBox(height: 22),
      child,
    ]),
  );
}

class LandingFooter extends StatelessWidget {
  const LandingFooter({super.key});
  @override
  Widget build(BuildContext context) => PublicSection(
        color: PublicPageStyles.forest,
        verticalPadding: 28,
        child: _Split(
          firstFlex: 2,
          secondFlex: 3,
          first: Row(children: [
            const SizedBox(
                width: 64,
                height: 64,
                child: PublicImagePlaceholder(
                    label: PublicPageContent.partnerLogoLabel,
                    assetPath: PublicPageContent.partnerLogoAsset,
                    aspectRatio: 1,
                    icon: null)),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(PublicPageContent.partnerName,
                      style:
                          PublicPageStyles.label.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(PublicPageContent.partnerContact,
                      style: PublicPageStyles.meta
                          .copyWith(color: PublicPageStyles.placeholder)),
                ])),
          ]),
          second: Theme(
            data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context)
                    .colorScheme
                    .copyWith(onSurfaceVariant: PublicPageStyles.placeholder)),
            child: const AppFooter(text: PublicPageContent.copyright),
          ),
        ),
      );
}

class _Split extends StatelessWidget {
  const _Split(
      {required this.first,
      required this.second,
      this.gap = 56,
      this.firstFlex = 1,
      this.secondFlex = 1,
      this.align = CrossAxisAlignment.center});
  final Widget first;
  final Widget second;
  final double gap;
  final int firstFlex;
  final int secondFlex;
  final CrossAxisAlignment align;
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, space) {
        if (space.maxWidth < 760) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [first, SizedBox(height: gap > 32 ? 32 : gap), second]);
        }
        return Row(crossAxisAlignment: align, children: [
          Expanded(flex: firstFlex, child: first),
          SizedBox(width: gap),
          Expanded(flex: secondFlex, child: second),
        ]);
      });
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(
      {required this.leading, required this.title, required this.description});
  final Widget leading;
  final String title;
  final String description;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: PublicPageStyles.border),
            borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          leading,
          const SizedBox(height: 16),
          Text(title, style: PublicPageStyles.heading.copyWith(fontSize: 20)),
          const SizedBox(height: 10),
          Text(description,
              style: PublicPageStyles.body.copyWith(fontSize: 14)),
        ]),
      );
}
