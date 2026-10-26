import 'package:flutter_test/flutter_test.dart';
import 'package:helmguard/main.dart';

void main() {
  testWidgets('SmartHelmetApp renders navigation and cockpit', (WidgetTester tester) async {
    // Build app
    await tester.pumpWidget(const SmartHelmetApp());
    await tester.pump(const Duration(milliseconds: 500));

    // Verify app title & navigation items
    expect(find.text('HELMGUARD'), findsOneWidget);
    expect(find.text('Cockpit'), findsOneWidget);
    expect(find.text('BLE Pair'), findsOneWidget);
    expect(find.text('Trips'), findsOneWidget);
    expect(find.text('Alerts'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Switch to BLE Pair tab
    await tester.tap(find.text('BLE Pair'));
    await tester.pump();
    expect(find.text('Bluetooth LE Pairing'), findsOneWidget);

    // Switch to Trips tab
    await tester.tap(find.text('Trips'));
    await tester.pump();
    expect(find.text('Trip & Ride History'), findsOneWidget);

    // Switch to Alerts tab
    await tester.tap(find.text('Alerts'));
    await tester.pump();
    expect(find.text('Incident Alerts & SOS'), findsOneWidget);

    // Switch to Settings tab
    await tester.tap(find.text('Settings'));
    await tester.pump();
    expect(find.text('Profile & Settings'), findsOneWidget);
  });
}
