import 'package:flutter_test/flutter_test.dart';
import 'package:blackjack/main.dart';

void main() {
  testWidgets('App launches and shows home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BlackjackApp());
    expect(find.text('BLACKJACK'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
  });
}
