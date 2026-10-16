import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The circular back-button styling used by Guided Sensor Calibration.
class MobilePageHeader extends StatelessWidget {
  const MobilePageHeader({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(children: [
      Tooltip(
        message: 'Back',
        child: Material(
          color: AppColors.iconCircle,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.maybePop(context),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(child: Text(title, style: AppTextStyles.pageHeading.copyWith(fontSize: 22))),
    ]),
  );
}
