import 'package:flutter/material.dart';
import '../../theme/public_page_styles.dart';

/// Uses local assets only. Null or unavailable assets retain the placeholder.
class PublicImagePlaceholder extends StatelessWidget {
  const PublicImagePlaceholder({
    super.key,
    required this.label,
    this.assetPath,
    this.aspectRatio = 2.1,
    this.icon = Icons.photo_camera_outlined,
  });

  final String label;
  final String? assetPath;
  final double aspectRatio;
  final IconData? icon;

  Widget _placeholder() => LayoutBuilder(builder: (context, space) {
        final padding = icon == null ? 12.0 : 20.0;
        return CustomPaint(
          painter: const _PlaceholderStripes(),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: (space.maxWidth - padding * 2)
                      .clamp(1.0, double.infinity)
                      .toDouble(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: PublicPageStyles.muted, size: 28),
                        const SizedBox(height: 12),
                      ],
                      Text(label,
                          textAlign: TextAlign.center,
                          style: PublicPageStyles.body.copyWith(fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      });

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: assetPath == null || assetPath!.isEmpty
              ? _placeholder()
              : Image.asset(
                  assetPath!,
                  fit: BoxFit.cover,
                  semanticLabel: label,
                  errorBuilder: (_, __, ___) => _placeholder(),
                ),
        ),
      );
}

class _PlaceholderStripes extends CustomPainter {
  const _PlaceholderStripes();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = PublicPageStyles.placeholder);
    final paint = Paint()
      ..color = PublicPageStyles.stripe
      ..strokeWidth = 16;
    for (double x = -size.height; x < size.width; x += 32) {
      canvas.drawLine(
          Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PlaceholderStripes oldDelegate) => false;
}
