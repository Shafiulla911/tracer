import 'package:flutter_test/flutter_test.dart';
import 'package:tracer_app/main.dart';

void main() {
  testWidgets('App starts with splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TracerApp());
    expect(find.text('TRACER'), findsAny);
    await tester.pump(const Duration(seconds: 4));
  });
}
