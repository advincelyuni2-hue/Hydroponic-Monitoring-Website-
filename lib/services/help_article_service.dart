import 'supabase_client.dart';

class HelpArticle {
  final String? id;
  final String type;
  final String title;
  final String body;
  final int sortOrder;

  const HelpArticle({
    this.id,
    this.type = 'faq',
    required this.title,
    required this.body,
    this.sortOrder = 0,
  });

  factory HelpArticle.fromMap(Map<String, dynamic> row) => HelpArticle(
        id: row['id']?.toString(),
        type: row['type'] as String? ?? 'faq',
        title: row['title'] as String? ?? '',
        body: row['body'] as String? ?? '',
        sortOrder: row['sort_order'] as int? ?? 0,
      );
}

class HelpArticleService {
  Future<List<HelpArticle>> list() async {
    final client = supabaseClient;
    if (client == null) return const [];
    final rows = await client
        .from('help_articles')
        .select('id, type, title, body, media_url, sort_order')
        .order('sort_order')
        .order('created_at');
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(HelpArticle.fromMap)
        .toList();
  }

  Future<void> create(HelpArticle article) async {
    final client = supabaseClient;
    if (client == null) throw StateError('Supabase is not configured.');
    await client.from('help_articles').insert({
      'title': article.title,
      'body': article.body,
      'type': article.type,
      'sort_order': article.sortOrder,
    });
  }

  Future<void> update(HelpArticle article) async {
    final client = supabaseClient;
    if (client == null || article.id == null) {
      throw StateError('A persisted article is required.');
    }
    await client.from('help_articles').update({
      'title': article.title,
      'body': article.body,
      'type': article.type,
      'sort_order': article.sortOrder,
    }).eq('id', article.id!);
  }

  Future<void> delete(String id) async {
    final client = supabaseClient;
    if (client == null) throw StateError('Supabase is not configured.');
    await client.from('help_articles').delete().eq('id', id);
  }
}
