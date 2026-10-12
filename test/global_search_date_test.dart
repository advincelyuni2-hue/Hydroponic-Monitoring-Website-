import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_app/services/global_search_service.dart';

void main() {
  group('parseHistorySearchDate', () {
    test('parses common written and numeric formats', () {
      expect(
          parseHistorySearchDate('October 12, 2026'), DateTime(2026, 10, 12));
      expect(parseHistorySearchDate('Oct 12 2026'), DateTime(2026, 10, 12));
      expect(parseHistorySearchDate('12 October 2026'), DateTime(2026, 10, 12));
      expect(parseHistorySearchDate('10/12/2026'), DateTime(2026, 10, 12));
      expect(parseHistorySearchDate('2026-10-12'), DateTime(2026, 10, 12));
    });

    test('uses the current year when the query omits it', () {
      expect(
        parseHistorySearchDate('October 11', defaultYear: 2026),
        DateTime(2026, 10, 11),
      );
      expect(
        parseHistorySearchDate('11 Oct', defaultYear: 2026),
        DateTime(2026, 10, 11),
      );
      expect(
        parseHistorySearchDate('10/11', defaultYear: 2026),
        DateTime(2026, 10, 11),
      );
    });

    test('rejects invalid dates and ordinary search text', () {
      expect(parseHistorySearchDate('February 30, 2026'), isNull);
      expect(parseHistorySearchDate('history logs'), isNull);
    });
  });

  group('parseHistorySearchMonth', () {
    test('parses full and abbreviated month names', () {
      expect(
        parseHistorySearchMonth('October', defaultYear: 2026),
        DateTime(2026, 10),
      );
      expect(parseHistorySearchMonth('Oct 2025'), DateTime(2025, 10));
    });

    test('rejects non-month searches', () {
      expect(parseHistorySearchMonth('October 11'), isNull);
      expect(parseHistorySearchMonth('history'), isNull);
    });
  });

  test('date result is only enabled for the History Logs header', () {
    final regularResults =
        GlobalSearchService.instance.search('October 12, 2026');
    final results = GlobalSearchService.instance.search(
      'October 12, 2026',
      includeHistoryDates: true,
    );
    final result = results.first;

    expect(
      regularResults.where((item) => item.kind == SearchResultKind.historyDate),
      isEmpty,
    );
    expect(result.kind, SearchResultKind.historyDate);
    expect(result.historyDate, DateTime(2026, 10, 12));
    expect(result.pageIndex, 2);
  });

  test('History Logs search recognizes a month and day without a year', () {
    final results = GlobalSearchService.instance.search(
      'October 11',
      includeHistoryDates: true,
    );

    expect(results.first.kind, SearchResultKind.historyDate);
    expect(results.first.historyDate?.month, 10);
    expect(results.first.historyDate?.day, 11);
  });

  test('History Logs search recognizes a month by itself', () {
    final results = GlobalSearchService.instance.search(
      'October',
      includeHistoryDates: true,
    );

    expect(results.first.kind, SearchResultKind.historyDate);
    expect(results.first.historyDate?.month, 10);
    expect(results.first.historyMonth, isTrue);
  });
}
