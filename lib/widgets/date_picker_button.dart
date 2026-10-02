import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';


class DatePickerButton extends StatelessWidget {
  final VoidCallback onTap;
  final String? dateText; // Optional date label (e.g. "Aug 10, 2026")
  final bool isSelected;

  const DatePickerButton({
    super.key,
    required this.onTap,
    this.dateText,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryButton : const Color(0xFFE2E2E2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
            if (dateText != null && dateText!.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                dateText!,
                style: AppTextStyles.cardMeta.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}