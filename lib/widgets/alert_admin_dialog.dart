import 'package:flutter/material.dart';
import '../services/notification_service.dart';

/// Asks for a message, then sends it to the admins as a notification.
Future<void> showAlertAdminDialog(
  BuildContext context, {
  String? source,
}) async {
  final controller = TextEditingController();
  final message = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Alert Admin'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Describe the issue for the administrator',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(dialogContext, controller.text.trim()),
          child: const Text('Send alert'),
        ),
      ],
    ),
  );

  if (message == null || message.isEmpty || !context.mounted) return;

  final fullMessage = source == null ? message : '$message\n(Sent from: $source)';

  try {
    await NotificationService().sendAdminAlert(fullMessage);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert sent to an administrator.')),
      );
    }
  } catch (e) {
    debugPrint('Alert admin failed: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to send the alert right now.')),
      );
    }
  }
}