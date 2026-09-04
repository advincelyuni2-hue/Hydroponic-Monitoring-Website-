import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppDrawer(selectedIndex: -1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppHeader(title: 'Help'),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isMobile ? 16 : 28),
                decoration: AppDecorations.card(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tutorial', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 8),
                    Text(
                      'Getting Started',
                      style: AppTextStyles.bodyBold,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Follow these steps to move through the hydroponic monitoring workflow.',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 20),
                    for (var i = 0; i < _steps.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: AppDecorations.card(
                            color: Theme.of(context).colorScheme.surface,
                            radius: 12,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.primaryButton,
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_steps[i].$1, style: AppTextStyles.bodyBold),
                                    const SizedBox(height: 4),
                                    Text(_steps[i].$2, style: AppTextStyles.body),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 24),
                    Text('FAQs', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 16),
                    for (final faq in _faqs)
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(bottom: 12),
                        title: Text(faq.$1, style: AppTextStyles.bodyBold),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(faq.$2, style: AppTextStyles.body),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _steps = [
    (
      'Read the dashboard',
      'Review pH, EC, and temperature cards for the latest sensor values.',
    ),
    (
      'Check an alert',
      'Open a notification to see the affected parameter and recommended action.',
    ),
    (
      'Review forecasts',
      'Use Forecasts to compare recent readings with predicted trends.',
    ),
    (
      'Inspect history',
      'Use History logs to review sensor readings and calibration activity.',
    ),
  ];

  static const _faqs = [
    (
      'What do the dashboard readings mean?',
      'pH shows acidity, EC shows nutrient concentration, and temperature shows the water temperature.',
    ),
    (
      'How often are readings updated?',
      'The dashboard displays the latest reading reported by the connected monitoring system.',
    ),
    (
      'What should I do when an alert appears?',
      'Open the notification, review the affected parameter, and follow the recommended action before checking the reading again.',
    ),
    (
      'Who can change calibration settings?',
      'Only authorized administrators should perform calibration or change system settings.',
    ),
    (
      'How do I get help with an account issue?',
      'Review your profile settings first, then contact the system administrator for account or access problems.',
    ),
  ];
}
