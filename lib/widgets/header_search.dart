import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/notifications_screen.dart';
import '../services/global_search_service.dart';
import '../services/help_article_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/app_navigation.dart';

/// Opens the page, help article or alert that was picked in the search.
void handleSearchResult(NavigatorState navigator, SearchResult result) {
  switch (result.kind) {
    case SearchResultKind.page:
      final index = result.pageIndex;
      if (index == null) return;
      if (index == kNotificationsPageIndex) {
        navigator.push(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
      } else {
        openAppPage(navigator, index);
      }
    case SearchResultKind.help:
      final article = result.article;
      if (article != null) _showHelpArticle(navigator, article);
    case SearchResultKind.alert:
      final alert = result.notification;
      if (alert == null) return;
      navigator.push(
        MaterialPageRoute(
          builder: (_) => NotificationsScreen(
            initialSelectedId: alert.id,
            initialTab: alert.isResolved ? 'Resolved' : 'Active',
          ),
        ),
      );
  }
}

void _showHelpArticle(NavigatorState navigator, HelpArticle article) {
  showDialog<void>(
    context: navigator.context,
    builder: (dialogContext) => AlertDialog(
      title: Text(article.title, style: AppTextStyles.sectionTitle),
      content: SingleChildScrollView(
        child: Text(article.body, style: AppTextStyles.body),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            openAppPage(navigator, 5);
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryButton,
            foregroundColor: Colors.white,
          ),
          child: const Text('Open Help'),
        ),
      ],
    ),
  );
}

/// Search box for the header on tablets and desktops. Shows a results list
/// under the box while typing.
class HeaderSearchField extends StatefulWidget {
  const HeaderSearchField({super.key});

  @override
  State<HeaderSearchField> createState() => _HeaderSearchFieldState();
}

class _HeaderSearchFieldState extends State<HeaderSearchField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  final LayerLink _link = LayerLink();
  final Object _groupId = Object();
  final GlobalSearchService _service = GlobalSearchService.instance;

  OverlayEntry? _entry;
  List<SearchResult> _results = const [];
  bool _loading = false;
  int _highlight = 0;
  double _width = 320;

  @override
  void initState() {
    super.initState();
    _results = _service.quickLinks();
    _focus.addListener(() {
      if (_focus.hasFocus) {
        _openDropdown();
        _warmUp();
      }
    });
  }

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _warmUp() async {
    if (mounted) setState(() => _loading = true);
    _entry?.markNeedsBuild();
    await _service.refresh();
    if (!mounted) return;
    _loading = false;
    _refreshResults();
  }

  void _refreshResults() {
    if (!mounted) return;
    setState(() {
      _results = _service.search(_controller.text);
      _highlight = 0;
    });
    _entry?.markNeedsBuild();
  }

  void _openDropdown() {
    if (_entry != null) return;
    final box = context.findRenderObject() as RenderBox?;
    _width = (box?.size.width ?? 320).clamp(300.0, 560.0).toDouble();

    _entry = OverlayEntry(
      builder: (_) => Positioned(
        width: _width,
        child: CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          offset: const Offset(0, 50),
          child: TapRegion(
            groupId: _groupId,
            onTapOutside: (_) => _close(),
            child: Material(
              elevation: 8,
              color: AppColors.cardBackground,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppColors.cardBorder),
              ),
              child: SearchResultsView(
                results: _results,
                query: _controller.text.trim(),
                loading: _loading,
                highlighted: _highlight,
                onSelect: _select,
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_entry!);
  }

  void _close({bool unfocus = true}) {
    _entry?.remove();
    _entry = null;
    if (unfocus) _focus.unfocus();
  }

  void _select(SearchResult result) {
    final navigator = Navigator.of(context);
    _close();
    _controller.clear();
    _refreshResults();
    handleSearchResult(navigator, result);
  }

  void _selectHighlighted() {
    if (_results.isEmpty) return;
    _select(_results[_highlight.clamp(0, _results.length - 1)]);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown && _results.isNotEmpty) {
      _openDropdown();
      setState(() => _highlight = (_highlight + 1) % _results.length);
      _entry?.markNeedsBuild();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp && _results.isNotEmpty) {
      _openDropdown();
      setState(() {
        _highlight = (_highlight - 1 + _results.length) % _results.length;
      });
      _entry?.markNeedsBuild();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _close();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: TapRegion(
        groupId: _groupId,
        onTapOutside: (_) => _close(),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: AppDecorations.card(radius: 24),
          child: Row(
            children: [
              Icon(Icons.search, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Focus(
                  canRequestFocus: false,
                  onKeyEvent: _onKey,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    style: AppTextStyles.body,
                    textInputAction: TextInputAction.search,
                    onTap: _openDropdown,
                    // Keep focus while the list is used; the TapRegion above
                    // closes the list when the user taps somewhere else.
                    onTapOutside: (_) {},
                    onChanged: (_) {
                      _openDropdown();
                      _refreshResults();
                    },
                    onSubmitted: (_) => _selectHighlighted(),
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: AppTextStyles.cardMeta,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ),
              if (_controller.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _controller.clear();
                    _refreshResults();
                    _focus.requestFocus();
                  },
                  child: Icon(
                    Icons.close,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the search as a bottom sheet (phones).
void showMobileSearchSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _MobileSearchSheet(),
  );
}

class _MobileSearchSheet extends StatefulWidget {
  const _MobileSearchSheet();

  @override
  State<_MobileSearchSheet> createState() => _MobileSearchSheetState();
}

class _MobileSearchSheetState extends State<_MobileSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  final GlobalSearchService _service = GlobalSearchService.instance;
  List<SearchResult> _results = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _results = _service.quickLinks();
    _warmUp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _warmUp() async {
    setState(() => _loading = true);
    await _service.refresh();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _results = _service.search(_controller.text);
    });
  }

  void _onChanged(String value) {
    setState(() => _results = _service.search(value));
  }

  void _select(SearchResult result) {
    final navigator = Navigator.of(context);
    navigator.pop();
    handleSearchResult(navigator, result);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            style: AppTextStyles.body,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            onSubmitted: (_) {
              if (_results.isNotEmpty) _select(_results.first);
            },
            decoration: InputDecoration(
              hintText: 'Search...',
              hintStyle: AppTextStyles.cardMeta,
              prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SearchResultsView(
            results: _results,
            query: _controller.text.trim(),
            loading: _loading,
            highlighted: -1,
            onSelect: _select,
            maxHeight: screenHeight * 0.4,
          ),
        ],
      ),
    );
  }
}

/// The list of results, shared by the desktop dropdown and the phone sheet.
class SearchResultsView extends StatelessWidget {
  final List<SearchResult> results;
  final String query;
  final bool loading;
  final int highlighted;
  final ValueChanged<SearchResult> onSelect;
  final double maxHeight;

  const SearchResultsView({
    super.key,
    required this.results,
    required this.query,
    required this.loading,
    required this.highlighted,
    required this.onSelect,
    this.maxHeight = 380,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          loading ? 'Searching…' : 'No results for “$query”',
          style: AppTextStyles.cardMeta,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (query.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Text('Go to', style: AppTextStyles.cardMeta),
          ),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: results.length,
            itemBuilder: (_, index) => _ResultTile(
              result: results[index],
              highlighted: index == highlighted,
              onTap: () => onSelect(results[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  final SearchResult result;
  final bool highlighted;
  final VoidCallback onTap;

  const _ResultTile({
    required this.result,
    required this.highlighted,
    required this.onTap,
  });

  String get _kindLabel => switch (result.kind) {
        SearchResultKind.page => 'Page',
        SearchResultKind.help => 'Help',
        SearchResultKind.alert => 'Alert',
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? AppColors.statusCardGreen : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.pillBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  result.icon,
                  size: 18,
                  color: AppColors.primaryButton,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
                    ),
                    if (result.subtitle.isNotEmpty)
                      Text(
                        result.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardMeta.copyWith(fontSize: 11),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _kindLabel,
                style: AppTextStyles.cardMeta.copyWith(
                  fontSize: 10,
                  color: AppColors.pillText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}