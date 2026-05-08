import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_memo/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: StockMemoApp()),
    );
    await tester.pump();
    expect(find.byType(StockMemoApp), findsOneWidget);
  });
}
