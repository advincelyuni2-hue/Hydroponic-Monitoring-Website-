import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../services/help_article_service.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});
  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _service = HelpArticleService();
  List<HelpArticle> _articles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final articles = await _service.list();
      if (mounted) {
        setState(() {
          _articles = articles;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _edit([HelpArticle? article]) async {
    final title = TextEditingController(text: article?.title);
    final body = TextEditingController(text: article?.body);
    var type = article?.type ?? 'faq';
    final result = await showDialog<HelpArticle>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(article == null ? 'Add help article' : 'Edit help article'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Title')),
          TextField(
              controller: body,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Content')),
          DropdownButtonFormField<String>(
            initialValue: type,
            decoration: const InputDecoration(labelText: 'Section'),
            items: const [
              DropdownMenuItem(value: 'tutorial', child: Text('Tutorial')),
              DropdownMenuItem(value: 'faq', child: Text('FAQ')),
            ],
            onChanged: (value) => type = value ?? 'faq',
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(
                context,
                HelpArticle(
                  id: article?.id,
                  type: type,
                  title: title.text.trim(),
                  body: body.text.trim(),
                  sortOrder: article?.sortOrder ?? _articles.length,
                )),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    title.dispose();
    body.dispose();
    if (result == null || result.title.isEmpty || result.body.isEmpty) return;
    try {
      if (result.id == null) {
        await _service.create(result);
      } else {
        await _service.update(result);
      }
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save help article.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = appProfile.value?.isAdmin == true;
    final articles = _articles.isEmpty ? _fallback : _articles;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppDrawer(selectedIndex: -1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(Responsive.isMobile(context) ? 16 : 24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const AppHeader(title: 'Help'),
            if (admin)
              Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () => _edit(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add article'),
                  )),
            const SizedBox(height: 16),
            if (_loading) const Center(child: CircularProgressIndicator()),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: AppDecorations.card(),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                        'Tutorials',
                        articles.where((a) => a.type == 'tutorial').toList(),
                        admin),
                    _buildSection('FAQs',
                        articles.where((a) => a.type == 'faq').toList(), admin),
                  ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<HelpArticle> articles, bool admin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        for (final article in articles)
          ExpansionTile(
            title: Text(article.title, style: AppTextStyles.bodyBold),
            children: [
              Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(article.body, style: AppTextStyles.body),
                  )),
              if (admin && article.id != null)
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(
                      onPressed: () => _edit(article),
                      child: const Text('Edit')),
                  TextButton(
                      onPressed: () async {
                        await _service.delete(article.id!);
                        await _load();
                      },
                      child: const Text('Delete')),
                ]),
            ],
          ),
      ],
    );
  }

  static const _fallback = [
    HelpArticle(
        type: 'tutorial',
        title: 'Getting started',
        body: 'Review pH, EC, and temperature cards on the dashboard.'),
    HelpArticle(
        type: 'faq',
        title: 'What should I do when an alert appears?',
        body:
            'Open the notification, review the affected parameter, and follow the recommended action.'),
  ];
}
