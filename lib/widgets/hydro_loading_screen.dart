import '../config/public_page_content.dart';
import 'package:flutter/material.dart';

/// HydroPulse loading screen: logo + animated heartbeat line.
///
/// UI only. Show it wherever you currently show a spinner, e.g.
///
///   if (isLoading) return const HydroLoadingScreen();
///
/// Add your logo to pubspec.yaml under `flutter: assets:` and point
/// [logoAsset] at it. If the asset can't be found, a leaf icon is shown
/// instead so the screen never crashes.
class HydroLoadingScreen extends StatefulWidget {
  const HydroLoadingScreen({
    super.key,
    this.title = 'Loading your screen',
    this.subtitle = 'This only takes a moment',
    this.logoAsset = PublicPageContent.brandLogoAsset ?? 'images/thesislogo.png',
  });

  final String title;
  final String? subtitle;
  final String logoAsset;

  @override
  State<HydroLoadingScreen> createState() => _HydroLoadingScreenState();
}

class _HydroLoadingScreenState extends State<HydroLoadingScreen>
    with SingleTickerProviderStateMixin {
  static const _cream = Color(0xFFFDFEEE);
  static const _green = Color(0xFF2E6B0E);
  static const _ink = Color(0xFF1B2410);
  static const _muted = Color(0xFF5C6356);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect "reduce motion": show the finished line, no animation.
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
      _controller.value = _EcgPainter.drawEnd;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cream,
      child: SizedBox.expand(
        child: Center(
          child: Semantics(
            label: 'Loading',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    widget.logoAsset,
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 96,
                      height: 96,
                      color: _green,
                      child: const Icon(Icons.eco, color: Colors.white, size: 48),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) => CustomPaint(
                    size: const Size(240, 60),
                    painter: _EcgPainter(_controller.value),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.subtitle!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _muted, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws the heartbeat line in 240x60 space: draws left to right, then
/// wipes away left to right, and repeats.
class _EcgPainter extends CustomPainter {
  _EcgPainter(this.t);

  final double t;

  /// Share of the loop spent drawing (the rest is spent wiping).
  static const double drawEnd = 0.6;

  static const _track = Color(0xFFDDDCC8);
  static const _line = Color(0xFF2E6B0E);

  static const _points = [
    Offset(0, 30),
    Offset(80, 30),
    Offset(90, 24),
    Offset(100, 30),
    Offset(112, 4),
    Offset(126, 56),
    Offset(138, 30),
    Offset(152, 30),
    Offset(160, 24),
    Offset(168, 30),
    Offset(240, 30),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Flat grey stubs at both ends.
    final trackPaint = Paint()
      ..color = _track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(0, 30), const Offset(80, 30), trackPaint);
    canvas.drawLine(const Offset(160, 30), const Offset(240, 30), trackPaint);

    final path = Path()..moveTo(_points.first.dx, _points.first.dy);
    for (final p in _points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final metric = path.computeMetrics().first;
    final length = metric.length;

    double start = 0;
    double end = length;
    if (t < drawEnd) {
      end = length * (t / drawEnd);
    } else {
      start = length * ((t - drawEnd) / (1 - drawEnd));
    }
    if (end - start <= 0) return;

    final linePaint = Paint()
      ..color = _line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(metric.extractPath(start, end), linePaint);
  }

  @override
  bool shouldRepaint(covariant _EcgPainter oldDelegate) => oldDelegate.t != t;
}
