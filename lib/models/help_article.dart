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