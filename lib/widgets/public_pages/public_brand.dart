import 'package:flutter/material.dart';
import '../../config/public_page_content.dart';
import '../../theme/public_page_styles.dart';

class PublicBrand extends StatelessWidget {
  const PublicBrand({
    super.key,
    this.showName = true,
    this.onDark = false,
    this.size = 60,
    this.nameSize = 28,
    this.mobileAuth = false,
  });

  final bool mobileAuth;
  final bool showName;
  final bool onDark;
  final double size;
  final double nameSize;

  Widget _logoPlaceholder() => Tooltip(
        message: PublicPageContent.brandLogoLabel,
        child: Semantics(
          label: PublicPageContent.brandLogoLabel,
          image: true,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: mobileAuth ? PublicPageStyles.green : PublicPageStyles.placeholder,
              borderRadius: BorderRadius.circular(size * .25),
            ),
            child: Icon(Icons.eco_outlined,
                color: mobileAuth ? Colors.white : PublicPageStyles.green, size: size * .62),
          ),
        ),
      );

  // Open lib/widgets/public_pages/public_brand.dart

@override
Widget build(BuildContext context) {
  final path = PublicPageContent.brandLogoAsset;
  final logo = path == null
      ? _logoPlaceholder()
      : ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.25), // Adjust radius (e.g., 12 or size * 0.25)
          child: Image.asset(
            path,
            width: size,
            height: size,
            fit: BoxFit.contain,
            semanticLabel: PublicPageContent.brandName,
            errorBuilder: (_, __, ___) => _logoPlaceholder(),
          ),
        );

  if (!showName) return logo;

  return Row(
    children: [
      logo,
      const SizedBox(width: 16),
      Flexible(
        child: Text(
          PublicPageContent.brandName,
          style: PublicPageStyles.heading.copyWith(
            fontSize: nameSize,
            color: onDark ? Colors.white : PublicPageStyles.green,
          ),
        ),
      ),
    ],
  );
}}