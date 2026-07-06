import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/main.dart';

void main() {
  testWidgets('App boots to login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ParkEasy());
    expect(find.text('ParkEasy Login'), findsOneWidget);
  });
}
