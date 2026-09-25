import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';

class ActionConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? toastMessage; // Optional: Null means no toast is shown
  final Future<void> Function() onConfirm;

  const ActionConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.toastMessage,
    required this.onConfirm,
  });

  /// Shows Apply Fix Dialog (with toast)
  static Future<void> showApplyFix(
    BuildContext context, {
    required Future<void> Function() onConfirm,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => ActionConfirmationDialog(
        title: 'Apply Corrective Fix?',
        message:
            'Are you sure you want to apply this fix? This intervention will be logged to action history.',
        toastMessage: 'Fix logged successfully',
        onConfirm: onConfirm,
      ),
    );
  }

  /// Shows Dismiss Fix Dialog (no toast notification shown on completion)
  static Future<void> showDismissFix(
    BuildContext context, {
    required Future<void> Function() onConfirm,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => ActionConfirmationDialog(
        title: 'Dismiss Corrective Fix?',
        message:
            'Are you sure you want to dismiss this fix? This action will be logged to dismissed action logs.',
        toastMessage: null, // Silenced
        onConfirm: onConfirm,
      ),
    );
  }

  static void showToast(BuildContext context, String message) {
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryButton,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  message,
                  style: AppTextStyles.button.copyWith(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.background,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: AppDecorations.card(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryButton),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    'No',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.primaryButton,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await onConfirm();
                    if (context.mounted && toastMessage != null) {
                      ActionConfirmationDialog.showToast(context, toastMessage!);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryButton,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    'Yes',
                    style: AppTextStyles.button.copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}