import 'package:flutter_test/flutter_test.dart';
import 'package:salguri/main.dart';

void main() {
  testWidgets('App renders splash then navigates to onboarding',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SalguriApp());
    expect(find.text('SALGURI'), findsOneWidget);

    // Advance past the 3-second splash delay
    await tester.pumpAndSettle(const Duration(seconds: 4));
    expect(find.text('Find Your Dream Home'), findsOneWidget);
  });
}
