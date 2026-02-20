import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PrayerApp());
    expect(find.text('Prayer App'), findsOneWidget);
  });
}
