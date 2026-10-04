import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

class HelpArticle {
  final String? id;

  /// 'tutorial' or 'faq'.
  final String type;

  /// Screen the article belongs to, for example 'Dashboard'.
  final String category;
  final String title;
  final String body;
  final int sortOrder;

  const HelpArticle({
    this.id,
    this.type = 'faq',
    this.category = 'Getting started',
    required this.title,
    required this.body,
    this.sortOrder = 0,
  });

  factory HelpArticle.fromMap(Map<String, dynamic> row) {
    final category = (row['category'] as String?)?.trim() ?? '';
    return HelpArticle(
      id: row['id']?.toString(),
      type: row['type'] as String? ?? 'faq',
      category: category.isEmpty ? 'Getting started' : category,
      title: row['title'] as String? ?? '',
      body: row['body'] as String? ?? '',
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  HelpArticle copyWith({
    String? id,
    String? type,
    String? category,
    String? title,
    String? body,
    int? sortOrder,
  }) {
    return HelpArticle(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      title: title ?? this.title,
      body: body ?? this.body,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

/// An error with a message that is safe to show to the user.
class HelpArticleException implements Exception {
  final String message;
  const HelpArticleException(this.message);

  @override
  String toString() => message;
}

class HelpArticleService {
  SupabaseClient _requireClient() {
    final client = supabaseClient;
    if (client == null) {
      throw const HelpArticleException('Supabase is not configured.');
    }
    return client;
  }

  Map<String, dynamic> _toMap(HelpArticle article,
      {bool withCategory = true}) {
    return {
      'title': article.title,
      'body': article.body,
      'type': article.type,
      'sort_order': article.sortOrder,
      if (withCategory) 'category': article.category,
    };
  }

  /// True when the database has no "category" column yet.
  bool _isMissingCategory(PostgrestException error) =>
      error.message.toLowerCase().contains('category');

  /// Turns database errors into a message that explains what to do.
  String _friendly(PostgrestException error) {
    final text = error.message.toLowerCase();
    if (error.code == '42501' ||
        text.contains('row-level security') ||
        text.contains('permission denied')) {
      return 'Permission denied. Only active admins can change help articles. '
          'Run help_articles_setup.sql in the Supabase SQL Editor, then try again.';
    }
    if (error.code == '42P01' ||
        error.code == 'PGRST205' ||
        text.contains('could not find the table') ||
        (text.contains('relation') && text.contains('does not exist'))) {
      return 'The help_articles table is missing. '
          'Run help_articles_setup.sql in the Supabase SQL Editor.';
    }
    return error.message;
  }

  Future<List<HelpArticle>> list() async {
    final client = supabaseClient;
    if (client == null) return const [];
    try {
      final rows = await client
          .from('help_articles')
          .select()
          .order('sort_order')
          .order('title');
      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map(HelpArticle.fromMap)
          .toList();
    } on PostgrestException catch (error) {
      throw HelpArticleException(_friendly(error));
    }
  }

  Future<void> create(HelpArticle article) => createMany([article]);

  Future<void> createMany(List<HelpArticle> articles) async {
    final client = _requireClient();
    try {
      try {
        await client
            .from('help_articles')
            .insert([for (final a in articles) _toMap(a)]);
      } on PostgrestException catch (error) {
        if (!_isMissingCategory(error)) rethrow;
        // The category column has not been added yet: save without it.
        await client.from('help_articles').insert(
            [for (final a in articles) _toMap(a, withCategory: false)]);
      }
    } on PostgrestException catch (error) {
      throw HelpArticleException(_friendly(error));
    }
  }

  Future<void> update(HelpArticle article) async {
    final client = _requireClient();
    final id = article.id;
    if (id == null) {
      throw const HelpArticleException(
        'This built-in article is not saved yet. Tap "Save built-in guides" first.',
      );
    }
    try {
      List<dynamic> rows;
      try {
        rows = await client
            .from('help_articles')
            .update(_toMap(article))
            .eq('id', id)
            .select('id');
      } on PostgrestException catch (error) {
        if (!_isMissingCategory(error)) rethrow;
        rows = await client
            .from('help_articles')
            .update(_toMap(article, withCategory: false))
            .eq('id', id)
            .select('id');
      }
      // Row-level security blocks silently: no error, but no rows changed.
      if (rows.isEmpty) {
        throw const HelpArticleException(
          'The article was not updated. Make sure you are signed in as an active admin.',
        );
      }
    } on PostgrestException catch (error) {
      throw HelpArticleException(_friendly(error));
    }
  }

  Future<void> delete(String id) async {
    final client = _requireClient();
    try {
      final rows =
          await client.from('help_articles').delete().eq('id', id).select('id');
      if (rows.isEmpty) {
        throw const HelpArticleException(
          'The article was not deleted. Make sure you are signed in as an active admin.',
        );
      }
    } on PostgrestException catch (error) {
      throw HelpArticleException(_friendly(error));
    }
  }
}