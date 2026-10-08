import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../services/help_article_service.dart';
import '../services/help_content.dart';
import '../theme/app_colors.dart';
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
  static const _all = 'All';

  final _service = HelpArticleService();
  List<HelpArticle> _saved = [];
  bool _loading = true;
  bool _busy = false;
  String? _loadError;
  String _category = _all;
  String _searchQuery = '';

  bool get _isAdmin => appProfile.value?.isAdmin == true;

  /// True when nothing is saved in the database, so the built-in guides show.
  bool get _usingDefaults => _saved.isEmpty;

  List<HelpArticle> get _articles {
    final articles = _usingDefaults ? kDefaultHelpArticles : _saved;

    if (_isAdmin) return articles;

    return articles
        .where((article) => article.category != 'Admin settings')
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final items = await _service.list();
      if (!mounted) return;
      setState(() {
        _saved = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error.toString();
      });
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  int _nextSortOrder() {
    if (_saved.isEmpty) return (kDefaultHelpArticles.length + 1) * 10;
    final highest =
        _saved.map((a) => a.sortOrder).reduce((a, b) => a > b ? a : b);
    return highest + 10;
  }

  /// Saves the built-in guides to Supabase so they can be edited.
  Future<void> _saveDefaults({bool quiet = false}) async {
    await _service.createMany([
      for (var i = 0; i < kDefaultHelpArticles.length; i++)
        kDefaultHelpArticles[i].copyWith(sortOrder: (i + 1) * 10),
    ]);
    if (!quiet) {
      await _load();
      _message('Built-in guides saved. You can now edit them.');
    }
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      _message('$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add() async {
    final result = await showDialog<HelpArticle>(
      context: context,
      builder: (_) => _ArticleDialog(
        initialCategory: _category == _all ? null : _category,
      ),
    );
    if (result == null) return;

    await _runBusy(() async {
      // Keep the built-in guides visible after the first article is added.
      if (_usingDefaults && _loadError == null) {
        await _saveDefaults(quiet: true);
      }
      await _service.create(result.copyWith(sortOrder: _nextSortOrder()));
      await _load();
      _message('Article added.');
    });
  }

  Future<void> _edit(HelpArticle article) async {
    final result = await showDialog<HelpArticle>(
      context: context,
      builder: (_) => _ArticleDialog(article: article),
    );
    if (result == null) return;

    await _runBusy(() async {
      await _service.update(result);
      await _load();
      _message('Article updated.');
    });
  }

  Future<void> _delete(HelpArticle article) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete article?'),
        content: Text('"${article.title}" will be removed for everyone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.alertText,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || article.id == null) return;

    await _runBusy(() async {
      await _service.delete(article.id!);
      await _load();
      _message('Article deleted.');
    });
  }

  List<String> _categoriesInUse() {
    final present = _articles.map((a) => a.category).toSet();
    return [
      ...kHelpCategories.where(present.contains),
      ...present.where((c) => !kHelpCategories.contains(c)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final categories = _categoriesInUse();
    if (_category != _all && !categories.contains(_category)) {
      _category = _all;
    }

    final query = _searchQuery.trim().toLowerCase();

    final visible = _articles.where((article) {
      final matchesCategory =
          _category == _all || article.category == _category;

      final matchesSearch = query.isEmpty ||
          article.title.toLowerCase().contains(query) ||
          article.body.toLowerCase().contains(query) ||
          article.category.toLowerCase().contains(query);

      return matchesCategory && matchesSearch;
    }).toList();

    final tutorials =
        visible.where((article) => article.type == 'tutorial').toList();
    final faqs = visible.where((article) => article.type == 'faq').toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppDrawer(selectedIndex: 5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppHeader(title: 'Help'),
              const SizedBox(height: 16),
              Text(
                'Step-by-step guides for every screen, plus answers to common questions.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search tutorials and FAQs',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_isAdmin) _buildAdminActions(),
              if (_isAdmin && _loadError != null) _buildLoadError(),
              if (_busy || _loading) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 12),
              ],
              _buildCategoryChips(categories),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                decoration: AppDecorations.card(),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection(
                            'Tutorials',
                            tutorials,
                            query.isEmpty
                                ? 'No tutorials in this category yet.'
                                : 'No tutorials match your search.',
                          ),
                          const SizedBox(height: 24),
                          _buildSection(
                            'FAQs',
                            faqs,
                            query.isEmpty
                                ? 'No FAQs in this category yet.'
                                : 'No FAQs match your search.',
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildSection(
                              'Tutorials',
                              tutorials,
                              query.isEmpty
                                  ? 'No tutorials in this category yet.'
                                  : 'No tutorials match your search.',
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildSection(
                              'FAQs',
                              faqs,
                              query.isEmpty
                                  ? 'No FAQs in this category yet.'
                                  : 'No FAQs match your search.',
                            ),
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

  Widget _buildAdminActions() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: _busy ? null : _add,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryButton,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add article'),
          ),
          if (_usingDefaults && _loadError == null && !_loading)
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _runBusy(() => _saveDefaults()),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.accentGreen),
                foregroundColor: AppColors.accentGreen,
              ),
              icon: const Icon(Icons.save_alt_rounded, size: 18),
              label: const Text('Save built-in guides'),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadError() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.alertBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Could not load saved articles: $_loadError',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.criticalRed),
            ),
          ),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(List<String> categories) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final name in [_all, ...categories])
          ChoiceChip(
            label: Text(name),
            selected: _category == name,
            showCheckmark: false,
            selectedColor: AppColors.primaryButton,
            backgroundColor: AppColors.pillBackground,
            side: BorderSide.none,
            labelStyle: AppTextStyles.cardMeta.copyWith(
              fontWeight: FontWeight.w600,
              color: _category == name ? Colors.white : AppColors.pillText,
            ),
            onSelected: (_) => setState(() => _category = name),
          ),
      ],
    );
  }

  Widget _buildSection(
      String title, List<HelpArticle> items, String emptyText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.sectionTitle),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(emptyText, style: AppTextStyles.cardMeta),
          )
        else
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, color: AppColors.cardBorder),
            _buildArticle(items[i]),
          ],
      ],
    );
  }

  Widget _buildArticle(HelpArticle article) {
    final canManage = _isAdmin && article.id != null;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        expandedAlignment: Alignment.centerLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        iconColor: AppColors.accentGreen,
        collapsedIconColor: AppColors.textSecondary,
        title: Text(article.title, style: AppTextStyles.bodyBold),
        subtitle: Text(
          article.category,
          style: AppTextStyles.cardMeta,
        ),
        children: [
          Text(
            article.body,
            style: AppTextStyles.body.copyWith(height: 1.55),
          ),
          if (canManage)
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                children: [
                  TextButton.icon(
                    onPressed: _busy ? null : () => _edit(article),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: _busy ? null : () => _delete(article),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.criticalRed,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Delete'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Add / edit form. It owns its text controllers, so they are always
/// disposed at the right time (after the dialog has fully closed).
class _ArticleDialog extends StatefulWidget {
  final HelpArticle? article;
  final String? initialCategory;

  const _ArticleDialog({this.article, this.initialCategory});

  @override
  State<_ArticleDialog> createState() => _ArticleDialogState();
}

class _ArticleDialogState extends State<_ArticleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _body;
  late String _type;
  late String _category;

  @override
  void initState() {
    super.initState();
    final article = widget.article;
    _title = TextEditingController(text: article?.title ?? '');
    _body = TextEditingController(text: article?.body ?? '');
    _type = article?.type ?? 'faq';
    _category =
        article?.category ?? widget.initialCategory ?? kHelpCategories.first;
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      HelpArticle(
        id: widget.article?.id,
        type: _type,
        category: _category,
        title: _title.text.trim(),
        body: _body.text.trim(),
        sortOrder: widget.article?.sortOrder ?? 0,
      ),
    );
  }

  String? _required(String? value, String label) =>
      (value == null || value.trim().isEmpty) ? 'Enter a $label.' : null;

  @override
  Widget build(BuildContext context) {
    final categories = {
      ...kHelpCategories,
      if (!kHelpCategories.contains(_category)) _category,
    }.toList();

    return AlertDialog(
      title: Text(
          widget.article == null ? 'Add help article' : 'Edit help article'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Section'),
                  items: const [
                    DropdownMenuItem(
                        value: 'tutorial', child: Text('Tutorial')),
                    DropdownMenuItem(value: 'faq', child: Text('FAQ')),
                  ],
                  onChanged: (value) => setState(() => _type = value ?? 'faq'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    for (final name in categories)
                      DropdownMenuItem(value: name, child: Text(name)),
                  ],
                  onChanged: (value) => setState(
                      () => _category = value ?? kHelpCategories.first),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _title,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) => _required(value, 'title'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _body,
                  minLines: 4,
                  maxLines: 10,
                  decoration: InputDecoration(
                    labelText: 'Content',
                    alignLabelWithHint: true,
                    hintText: _type == 'tutorial'
                        ? '1. First step\n2. Second step'
                        : 'Write the answer here',
                  ),
                  validator: (value) => _required(value, 'content'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryButton,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save article'),
        ),
      ],
    );
  }
}
