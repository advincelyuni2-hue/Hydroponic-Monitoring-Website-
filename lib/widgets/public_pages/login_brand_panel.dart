import 'package:flutter/material.dart';
import '../../config/public_page_content.dart';
import '../../theme/public_page_styles.dart';
import 'public_brand.dart';
import 'public_image_placeholder.dart';

class LoginBrandPanel extends StatelessWidget {
  const LoginBrandPanel({
    super.key,
    this.compact = false,
    this.headingSize = 48,
    this.fitViewport = false,
    this.showBenefits = false,
  });

  final bool compact;
  final double headingSize;
  final bool fitViewport;
  final bool showBenefits;

  @override
  Widget build(BuildContext context) {
    if (fitViewport) {
      return LayoutBuilder(builder: (context, space) {
        final inset = space.maxHeight < 700 ? 24.0 : 36.0;
        final titleSize = ((space.maxWidth - inset * 2) * .10)
            .clamp(30.0, space.maxHeight < 700 ? 40.0 : 56.0)
            .toDouble();
        return Container(
          padding: EdgeInsets.all(inset),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PublicPageStyles.panelRadius),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [PublicPageStyles.forest, PublicPageStyles.green],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PublicBrand(onDark: true, size: showBenefits ? 36 : 48,
                nameSize: showBenefits ? 22 : 28),
              const SizedBox(height: 24),
              // EDIT TEXT HERE: Login hero heading.
              Text.rich(
                const TextSpan(children: [
                  TextSpan(text: PublicPageContent.loginHeroHeading),
                  TextSpan(
                      text: PublicPageContent.loginHeroHighlight,
                      style: TextStyle(color: PublicPageStyles.lime)),
                ]),
                style: PublicPageStyles.heading.copyWith(
                    fontSize: titleSize,
                    height: 1.13,
                    letterSpacing: -1,
                    color: Colors.white),
              ),
              const SizedBox(height: 16),
              if (showBenefits)
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final benefit in PublicPageContent.loginBenefits)
                    Padding(padding: const EdgeInsets.only(bottom: 8),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Padding(padding: EdgeInsets.only(top: 3),
                          child: Icon(Icons.check_rounded, color: PublicPageStyles.lime, size: 18)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(benefit, style: PublicPageStyles.body.copyWith(
                          color: PublicPageStyles.placeholder, fontSize: 14, height: 1.4))),
                      ])),
                ])
              else
                Text(PublicPageContent.loginHeroDescription,
                    style: PublicPageStyles.body.copyWith(
                        color: PublicPageStyles.placeholder, fontSize: 16)),
              SizedBox(height: showBenefits ? space.maxHeight * .06 : 20),
              // REPLACE IMAGE HERE: Hydroponic plants photo.
              const Expanded(
                  child: PublicImagePlaceholder(
                label: PublicPageContent.loginPlantsLabel,
                assetPath: PublicPageContent.loginPlantsAsset,
              )),
              SizedBox(height: showBenefits ? 10 : 20),
              Text(PublicPageContent.loginPartnership,
                  style: PublicPageStyles.meta
                      .copyWith(color: PublicPageStyles.placeholder,
                        fontSize: showBenefits ? 11 : null)),
            ],
          ),
        );
      });
    }
    return Container(
      padding: EdgeInsets.all(compact ? 24 : 40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PublicPageStyles.panelRadius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PublicPageStyles.forest, PublicPageStyles.green],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PublicBrand(onDark: true, size: compact ? 44 : 64),
          if (!compact) const Spacer(),
          SizedBox(height: compact ? 22 : 56),
          // EDIT TEXT HERE: Login hero heading and highlighted phrase.
          Text.rich(
            TextSpan(children: [
              const TextSpan(text: PublicPageContent.loginHeroHeading),
              TextSpan(
                text: PublicPageContent.loginHeroHighlight,
                style: const TextStyle(color: PublicPageStyles.lime),
              ),
            ]),
            style: PublicPageStyles.heading.copyWith(
                fontSize: compact ? 30 : headingSize,
                height: 1.16,
                letterSpacing: -1.5,
                color: Colors.white),
          ),
          if (!compact) ...[
            const SizedBox(height: 28),
            Text(PublicPageContent.loginHeroDescription,
                style: PublicPageStyles.body.copyWith(
                    color: PublicPageStyles.placeholder, fontSize: 18)),
            const SizedBox(height: 30),
            // REPLACE IMAGE HERE: Hydroponic plants photo.
            const PublicImagePlaceholder(
              label: PublicPageContent.loginPlantsLabel,
              assetPath: PublicPageContent.loginPlantsAsset,
            ),
            const SizedBox(height: 40),
            const Spacer(),
            // EDIT HERE: Partner office information.
            Text(PublicPageContent.loginPartnership,
                style: PublicPageStyles.body.copyWith(
                    color: PublicPageStyles.placeholder, fontSize: 14)),
          ],
        ],
      ),
    );
  }
}
