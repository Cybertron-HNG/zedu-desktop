import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/test_material_app.dart';

class _FakeLaunchAtLoginService implements LaunchAtLoginService {
  _FakeLaunchAtLoginService({this.enabled = false});

  bool enabled;
  @override
  bool isSupported = true;

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<void> setEnabled(bool value) async {
    enabled = value;
  }
}

Switch _switch(WidgetTester tester) =>
    tester.widget<Switch>(find.byType(Switch));

void main() {
  macOsVersionTests();
  testWidgets('shows the switch off by default', (tester) async {
    await tester.pumpWidget(
      buildTestMaterialApp(
        Scaffold(body: LaunchAtLoginTile(service: _FakeLaunchAtLoginService())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Launch Zedu at login'), findsOneWidget);
    expect(_switch(tester).value, isFalse);
  });

  testWidgets('turning it on and off updates the login item', (tester) async {
    final service = _FakeLaunchAtLoginService();
    await tester.pumpWidget(
      buildTestMaterialApp(Scaffold(body: LaunchAtLoginTile(service: service))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(service.enabled, isTrue);
    expect(_switch(tester).value, isTrue);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(service.enabled, isFalse);
    expect(_switch(tester).value, isFalse);
  });

  testWidgets('shows the saved state when the screen opens', (tester) async {
    await tester.pumpWidget(
      buildTestMaterialApp(
        Scaffold(
          body: LaunchAtLoginTile(
            service: _FakeLaunchAtLoginService(enabled: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_switch(tester).value, isTrue);
  });

  testWidgets('shows nothing where there is no login item', (tester) async {
    final service = _FakeLaunchAtLoginService()..isSupported = false;
    await tester.pumpWidget(
      buildTestMaterialApp(Scaffold(body: LaunchAtLoginTile(service: service))),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Switch), findsNothing);
  });
}

void macOsVersionTests() {
  group('macOsSupportsLoginItem', () {
    test('is true from macOS 13', () {
      expect(macOsSupportsLoginItem('Version 13.0 (Build 22A380)'), isTrue);
      expect(macOsSupportsLoginItem('Version 14.5 (Build 23F79)'), isTrue);
    });

    test('is false before macOS 13 or when it cannot be read', () {
      expect(macOsSupportsLoginItem('Version 12.7 (Build 21H1015)'), isFalse);
      expect(macOsSupportsLoginItem('Version 10.15.7 (Build 19H2)'), isFalse);
      expect(macOsSupportsLoginItem('unknown'), isFalse);
    });
  });
}
