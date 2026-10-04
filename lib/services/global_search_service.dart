import 'package:flutter/material.dart';
import '../models/notification_models.dart';
import 'app_state.dart';
import 'help_article_service.dart';
import 'help_content.dart';
import 'notification_service.dart';

/// Page index used for the Notifications screen (it is not in the side menu).
const int kNotificationsPageIndex = -1;

enum SearchResultKind { page, help, alert }

class SearchResult {
  final SearchResultKind kind;
  final String title;
  final String subtitle;
  final IconData icon;
  final int score;
  final int? pageIndex;
  final HelpArticle? article;
  final AppNotificationItem? notification;

  const SearchResult({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.score = 0,
    this.pageIndex,
    this.article,
    this.notification,
  });
}

class _PageEntry {
  final int index;
  final String title;
  final String description;
  final IconData icon;
  final List<String> keywords;
  final bool adminOnly;

  const _PageEntry({
    required this.index,
    required this.title,
    required this.description,
    required this.icon,
    this.keywords = const [],
    this.adminOnly = false,
  });
}

/// Searches the app's pages, help articles and alerts.
///
/// Pages are searched instantly. Help articles and alerts are loaded from
/// Supabase and cached for a short time, so typing never waits on the network.
class GlobalSearchService {
  GlobalSearchService._();
  static final GlobalSearchService instance = GlobalSearchService._();

  static const List<_PageEntry> _pages = [
    _PageEntry(
      index: 0,
      title: 'Dashboard',
      description: 'Live pH, EC and temperature readings',
      icon: Icons.dashboard_outlined,
      keywords: [
        'home', 'overview', 'live', 'realtime', 'gauge', 'status',
        'latest insight', 'alert admin',
      ],
    ),
    _PageEntry(
      index: 1,
      title: 'Forecasts',
      description: 'Predicted pH and EC for the next hours',
      icon: Icons.show_chart,
      keywords: [
        'forecast', 'prediction', 'predict', 'model', 'trend',
        'machine learning', 'report an issue',
      ],
    ),
    _PageEntry(
      index: 2,
      title: 'History logs',
      description: 'Sensor, calibration and report logs',
      icon: Icons.receipt_long_outlined,
      keywords: [
        'logs', 'history', 'sensor logs', 'calibration', 'records', 'daily',
        'weekly', 'monthly',
      ],
    ),
    _PageEntry(
      index: 3,
      title: 'Reports',
      description: 'Trends, summaries and PDF export',
      icon: Icons.description_outlined,
      keywords: [
        'report', 'pdf', 'export', 'generate report', 'analytics',
        'telemetry', 'distribution', 'alert frequency', 'sensor health',
      ],
    ),
    _PageEntry(
      index: kNotificationsPageIndex,
      title: 'Notifications',
      description: 'Active and resolved alerts',
      icon: Icons.notifications_none,
      keywords: ['alerts', 'bell', 'critical', 'warning', 'resolved', 'active'],
    ),
    _PageEntry(
      index: 4,
      title: 'Settings',
      description: 'Profile, password, email, units and theme',
      icon: Icons.settings_outlined,
      keywords: [
        'profile', 'account', 'password', 'email', 'units', 'metric',
        'imperial', 'dark mode', 'light mode', 'theme', 'log out', 'logout',
      ],
    ),
    _PageEntry(
      index: 5,
      title: 'Help',
      description: 'Guides and frequently asked questions',
      icon: Icons.help_outline,
      keywords: ['faq', 'tutorial', 'guide', 'how to', 'support'],
    ),
    _PageEntry(
      index: 6,
      title: 'Admin settings',
      description: 'User management and ideal pH/EC ranges',
      icon: Icons.admin_panel_settings_outlined,
      keywords: [
        'admin', 'users', 'user management', 'roles', 'ideal range',
        'threshold', 'parameter', 'configuration',
      ],
      adminOnly: true,
    ),
  ];

  List<HelpArticle> _help = kDefaultHelpArticles;
  List<AppNotificationItem> _alerts = const [];
  DateTime? _loadedAt;
  Future<void>? _loading;

  bool get _isAdmin => appProfile.value?.isAdmin == true;

  /// Loads help articles and alerts. Cached for 45 seconds.
  Future<void> refresh({bool force = false}) {
    final stale = _loadedAt == null ||
        DateTime.now().difference(_loadedAt!) > const Duration(seconds: 45);
    if (!force && !stale) return Future.value();
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  Future<void> _load() async {
    try {
      final saved = await HelpArticleService().list();
      _help = saved.isEmpty ? kDefaultHelpArticles : saved;
    } catch (_) {
      _help = kDefaultHelpArticles;
    }
    try {
      _alerts = await NotificationService().getNotificationItems(limit: 50);
    } catch (_) {
      _alerts = const [];
    }
    _loadedAt = DateTime.now();
  }

  /// Shortcuts shown when the search box is empty.
  List<SearchResult> quickLinks() {
    return [
      for (final page in _pages)
        if (!page.adminOnly || _isAdmin) _pageResult(page, 0),
    ];
  }

  List<SearchResult> search(String rawQuery, {int limit = 10}) {
    final query = _normalize(rawQuery);
    if (query.isEmpty) return quickLinks();
    final tokens = query.split(' ');
    final results = <SearchResult>[];

    for (final page in _pages) {
      if (page.adminOnly && !_isAdmin) continue;
      final score = _score(
        query,
        tokens,
        title: page.title,
        keywords: '${page.description} ${page.keywords.join(' ')}',
      );
      if (score >= 0) results.add(_pageResult(page, score + 5));
    }

    for (final article in _help) {
      final score = _score(
        query,
        tokens,
        title: article.title,
        keywords: article.category,
        body: article.body,
      );
      if (score < 0) continue;
      final kindLabel = article.type == 'tutorial' ? 'Tutorial' : 'FAQ';
      results.add(SearchResult(
        kind: SearchResultKind.help,
        title: article.title,
        subtitle:
            '${article.category} • $kindLabel — ${_snippet(article.body, query)}',
        icon: article.type == 'tutorial'
            ? Icons.menu_book_outlined
            : Icons.question_answer_outlined,
        score: score,
        article: article,
      ));
    }

    for (final alert in _alerts) {
      final score = _score(
        query,
        tokens,
        title: alert.title,
        keywords: '${alert.currentStatus} ${alert.idealRange}',
        body: '${alert.subtitle} ${alert.recommendation}',
      );
      if (score < 0) continue;
      final state = alert.isResolved ? 'Resolved' : 'Active';
      results.add(SearchResult(
        kind: SearchResultKind.alert,
        title: alert.title,
        subtitle: '$state • ${alert.timestamp}',
        icon: alert.isCritical
            ? Icons.error_outline
            : Icons.warning_amber_rounded,
        score: score,
        notification: alert,
      ));
    }

    results.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      final byKind = a.kind.index.compareTo(b.kind.index);
      if (byKind != 0) return byKind;
      return a.title.compareTo(b.title);
    });
    return results.take(limit).toList();
  }

  SearchResult _pageResult(_PageEntry page, int score) {
    return SearchResult(
      kind: SearchResultKind.page,
      title: page.title,
      subtitle: page.description,
      icon: page.icon,
      score: score,
      pageIndex: page.index,
    );
  }

  String _normalize(String text) =>
      text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// Returns -1 when the text does not match. Higher is a better match.
  int _score(
    String query,
    List<String> tokens, {
    required String title,
    String keywords = '',
    String body = '',
  }) {
    final t = title.toLowerCase();
    final k = keywords.toLowerCase();
    final b = body.toLowerCase();
    final all = '$t $k $b';
    for (final token in tokens) {
      if (!all.contains(token)) return -1;
    }
    if (t == query) return 100;
    if (t.startsWith(query)) return 80;
    if (t.contains(query)) return 60;
    if (tokens.every((token) => t.contains(token))) return 50;
    if (k.contains(query)) return 40;
    final titleAndKeywords = '$t $k';
    if (tokens.every((token) => titleAndKeywords.contains(token))) return 30;
    return 10;
  }

  String _snippet(String body, String query) {
    final text = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    final index = text.toLowerCase().indexOf(query);
    if (index < 0) {
      return text.length <= 70 ? text : '${text.substring(0, 70)}…';
    }
    final start = index > 20 ? index - 20 : 0;
    final end = index + 60 < text.length ? index + 60 : text.length;
    return '${start > 0 ? '…' : ''}${text.substring(start, end)}'
        '${end < text.length ? '…' : ''}';
  }
}