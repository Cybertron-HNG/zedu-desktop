import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../helpers/test_material_app.dart';

Future<void> _pump(WidgetTester tester, AppUpdate? update) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appUpdateProvider.overrideWith((ref) async => update)],
      child: buildTestMaterialApp(const Scaffold(body: UpdateBanner())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const update = AppUpdate(version: '0.2.0', url: 'https://example.com/r');

  testWidgets('shows the banner when a newer release exists', (tester) async {
    await _pump(tester, update);

    expect(
      find.textContaining('A new version of Zedu is available'),
      findsOneWidget,
    );
    expect(find.text('Download'), findsOneWidget);
  });

  testWidgets('shows nothing when up to date', (tester) async {
    await _pump(tester, null);

    expect(find.textContaining('A new version'), findsNothing);
  });

  testWidgets('can be dismissed', (tester) async {
    await _pump(tester, update);

    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pumpAndSettle();

    expect(find.textContaining('A new version'), findsNothing);
  });

  group('remembering a dismissed update', () {
    late _MockSecureStorage storage;

    setUp(() {
      storage = _MockSecureStorage();
      when(() => storage.readData(any())).thenAnswer((_) async => null);
      when(() => storage.writeData(any(), any())).thenAnswer((_) async {});
      locator.registerSingleton<SecureStorageService>(storage);
    });

    tearDown(() => locator.unregister<SecureStorageService>());

    testWidgets('saves the dismissed version', (tester) async {
      await _pump(tester, update);

      await tester.tap(find.byTooltip('Dismiss'));
      await tester.pumpAndSettle();

      verify(
        () => storage.writeData(DismissedUpdateNotifier.storageKey, '0.2.0'),
      ).called(1);
    });

    testWidgets('keeps the banner hidden after a restart', (tester) async {
      when(
        () => storage.readData(DismissedUpdateNotifier.storageKey),
      ).thenAnswer((_) async => '0.2.0');

      await _pump(tester, update);

      expect(find.textContaining('A new version'), findsNothing);
    });
  });
}

class _MockSecureStorage extends Mock implements SecureStorageService {}
