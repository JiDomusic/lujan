import 'package:flutter_test/flutter_test.dart';
import 'package:lujan/main.dart';

void main() {
  testWidgets('Portfolio loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const LujanPortfolioApp());
    expect(find.text('Lujan Allemand'), findsOneWidget);
    expect(find.text('portfolio'), findsOneWidget);
  });
}
