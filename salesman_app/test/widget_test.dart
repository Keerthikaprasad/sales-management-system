import 'package:flutter_test/flutter_test.dart';
import 'package:salesman_app/main.dart';

void main() {
  testWidgets('Salesman app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const SalesmanApp());

    expect(find.byType(SalesmanApp), findsOneWidget);
  });
}