import 'package:flutter/material.dart';
import '../models/notification_models.dart';
import 'app_state.dart';
import 'help_article_service.dart';
import 'help_content.dart';
import 'notification_service.dart';
import '../utils/manila_time.dart';

/// Page index used for the Notifications screen (it is not in the side menu).
const int kNotificationsPageIndex = -1;

typedef HistoryDateSelection = void Function(DateTime date, bool wholeMonth);

enum SearchResultKind { page, historyDate, help, alert }

class SearchResult {
  final SearchResultKind kind;
  final String title;
  final String subtitle;
  final IconData icon;
  final int score;
  final int? pageIndex;
  final HelpArticle? article;
  final AppNotificationItem? notification;
  final DateTime? historyDate;
  final bool historyMonth;

  const SearchResult({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.score = 0,
    this.pageIndex,
    this.article,
    this.notification,
    this.historyDate,
    this.historyMonth = false,
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
        'home',
        'overview',
        'live',
        'realtime',
        'gauge',
        'status',
        'latest insight',
        'alert admin',
      ],
    ),
    _PageEntry(
      index: 1,
      title: 'Forecasts',
      description: 'Predicted pH and EC for the next hours',
      icon: Icons.show_chart,
      keywords: [
        'forecast',
        'prediction',
        'predict',
        'model',
        'trend',
        'machine learning',
        'report an issue',
      ],
    ),
    _PageEntry(
      index: 2,
      title: 'History logs',
      description: 'Sensor, calibration and intervention logs',
      icon: Icons.receipt_long_outlined,
      keywords: [
        'logs',
        'history',
        'sensor logs',
        'calibration',
        'records',
        'daily',
        'weekly',
        'monthly',
      ],
    ),
    _PageEntry(
      index: 3,
      title: 'Reports',
      description: 'Trends, summaries and PDF export',
      icon: Icons.description_outlined,
      keywords: [
        'report',
        'pdf',
        'export',
        'generate report',
        'analytics',
        'telemetry',
        'distribution',
        'alert frequency',
        'sensor health',
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
        'profile',
        'account',
        'password',
        'email',
        'units',
        'metric',
        'imperial',
        'dark mode',
        'light mode',
        'theme',
        'log out',
        'logout',
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
        'admin',
        'users',
        'user management',
        'roles',
        'ideal range',
        'threshold',
        'parameter',
        'configuration',
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

  List<SearchResult> search(
    String rawQuery, {
    int limit = 10,
    bool includeHistoryDates = false,
  }) {
    final query = _normalize(rawQuery);
    if (query.isEmpty) return quickLinks();
    final tokens = query.split(' ');
    final results = <SearchResult>[];

    final historyDate =
        includeHistoryDates ? parseHistorySearchDate(rawQuery) : null;
    final historyMonth = includeHistoryDates && historyDate == null
        ? parseHistorySearchMonth(rawQuery)
        : null;
    if (historyDate != null) {
      results.add(SearchResult(
        kind: SearchResultKind.historyDate,
        title: 'History logs — ${_formatHistoryDate(historyDate)}',
        subtitle: 'Show logs recorded on this date',
        icon: Icons.calendar_today_outlined,
        score: 120,
        pageIndex: 2,
        historyDate: historyDate,
      ));
    } else if (historyMonth != null) {
      results.add(SearchResult(
        kind: SearchResultKind.historyDate,
        title: 'History logs — ${_formatHistoryMonth(historyMonth)}',
        subtitle: 'Show logs recorded during this month',
        icon: Icons.calendar_month_outlined,
        score: 120,
        pageIndex: 2,
        historyDate: historyMonth,
        historyMonth: true,
      ));
    }

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

  String _formatHistoryDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatHistoryMonth(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

DateTime? parseHistorySearchDate(String rawQuery, {int? defaultYear}) {
  final query = rawQuery.trim().toLowerCase();
  if (query.isEmpty) return null;
  final fallbackYear = defaultYear ?? manilaNow().year;

  final isoMatch =
      RegExp(r'^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})$').firstMatch(query);
  if (isoMatch != null) {
    return _validDate(
      int.parse(isoMatch.group(1)!),
      int.parse(isoMatch.group(2)!),
      int.parse(isoMatch.group(3)!),
    );
  }

  final numericMatch =
      RegExp(r'^(\d{1,2})[-/.](\d{1,2})[-/.](\d{4})$').firstMatch(query);
  if (numericMatch != null) {
    return _validDate(
      int.parse(numericMatch.group(3)!),
      int.parse(numericMatch.group(1)!),
      int.parse(numericMatch.group(2)!),
    );
  }

  final shortNumericMatch =
      RegExp(r'^(\d{1,2})[-/.](\d{1,2})$').firstMatch(query);
  if (shortNumericMatch != null) {
    return _validDate(
      fallbackYear,
      int.parse(shortNumericMatch.group(1)!),
      int.parse(shortNumericMatch.group(2)!),
    );
  }

  const monthNames = <String, int>{
    'january': 1,
    'jan': 1,
    'february': 2,
    'feb': 2,
    'march': 3,
    'mar': 3,
    'april': 4,
    'apr': 4,
    'may': 5,
    'june': 6,
    'jun': 6,
    'july': 7,
    'jul': 7,
    'august': 8,
    'aug': 8,
    'september': 9,
    'sep': 9,
    'sept': 9,
    'october': 10,
    'oct': 10,
    'november': 11,
    'nov': 11,
    'december': 12,
    'dec': 12,
  };
  final normalized = query.replaceAll(',', ' ').replaceAll(RegExp(r'\s+'), ' ');
  final monthFirst =
      RegExp(r'^([a-z]+) (\d{1,2}) (\d{4})$').firstMatch(normalized);
  if (monthFirst != null) {
    final month = monthNames[monthFirst.group(1)];
    if (month != null) {
      return _validDate(
        int.parse(monthFirst.group(3)!),
        month,
        int.parse(monthFirst.group(2)!),
      );
    }
  }

  final dayFirst =
      RegExp(r'^(\d{1,2}) ([a-z]+) (\d{4})$').firstMatch(normalized);
  if (dayFirst != null) {
    final month = monthNames[dayFirst.group(2)];
    if (month != null) {
      return _validDate(
        int.parse(dayFirst.group(3)!),
        month,
        int.parse(dayFirst.group(1)!),
      );
    }
  }

  final shortMonthFirst =
      RegExp(r'^([a-z]+) (\d{1,2})$').firstMatch(normalized);
  if (shortMonthFirst != null) {
    final month = monthNames[shortMonthFirst.group(1)];
    if (month != null) {
      return _validDate(
        fallbackYear,
        month,
        int.parse(shortMonthFirst.group(2)!),
      );
    }
  }

  final shortDayFirst = RegExp(r'^(\d{1,2}) ([a-z]+)$').firstMatch(normalized);
  if (shortDayFirst != null) {
    final month = monthNames[shortDayFirst.group(2)];
    if (month != null) {
      return _validDate(
        fallbackYear,
        month,
        int.parse(shortDayFirst.group(1)!),
      );
    }
  }
  return null;
}

DateTime? _validDate(int year, int month, int day) {
  final date = DateTime(year, month, day);
  return date.year == year && date.month == month && date.day == day
      ? date
      : null;
}

DateTime? parseHistorySearchMonth(String rawQuery, {int? defaultYear}) {
  final query = rawQuery.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  if (query.isEmpty) return null;

  const monthNames = <String, int>{
    'january': 1,
    'jan': 1,
    'february': 2,
    'feb': 2,
    'march': 3,
    'mar': 3,
    'april': 4,
    'apr': 4,
    'may': 5,
    'june': 6,
    'jun': 6,
    'july': 7,
    'jul': 7,
    'august': 8,
    'aug': 8,
    'september': 9,
    'sep': 9,
    'sept': 9,
    'october': 10,
    'oct': 10,
    'november': 11,
    'nov': 11,
    'december': 12,
    'dec': 12,
  };
  final match = RegExp(r'^([a-z]+)(?: (\d{4}))?$').firstMatch(query);
  if (match == null) return null;
  final month = monthNames[match.group(1)];
  if (month == null) return null;
  final year = match.group(2) == null
      ? (defaultYear ?? manilaNow().year)
      : int.parse(match.group(2)!);
  return DateTime(year, month);
}
