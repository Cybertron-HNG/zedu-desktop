import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class FakeSecureStorageService extends Fake implements SecureStorageService {
  final _values = <String, String>{};

  @override
  Future<String?> readData(String key) async => _values[key];

  @override
  Future<void> writeData(String key, String value) async =>
      _values[key] = value;

  @override
  Future<void> deleteValue(String key) async => _values.remove(key);
}

class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

void main() {
  late ScheduledMessagesStore scheduled;

  Future<void> pumpComposer(WidgetTester tester) async {
    scheduled = ScheduledMessagesStore(
      null,
      userId: 'user-1',
      armTimers: false,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          dmDraftStoreProvider.overrideWith(
            (ref) => DmDraftStore(
              FakeSecureStorageService(),
              userId: 'user-1',
              orgId: 'org-1',
            ),
          ),
          scheduledMessagesStoreProvider.overrideWith((ref) => scheduled),
        ],
        child: buildTestMaterialApp(
          const Scaffold(
            body: DmMessageComposer(
              recipientName: 'Ada',
              conversationName: 'Ada Lovelace',
              channelId: 'dm-1',
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('the clock opens the schedule dialog with the typed text', (
    tester,
  ) async {
    await pumpComposer(tester);

    await tester.enterText(find.byType(TextField), 'Ship it later');
    await tester.pump();
    await tester.tap(find.byTooltip('Schedule message'));
    await tester.pumpAndSettle();

    expect(find.byType(ScheduleMessageDialog), findsOneWidget);
    final messageField = tester
        .widgetList<TextField>(find.byType(TextField))
        .where((field) => field.decoration?.labelText == 'Message');
    expect(messageField, hasLength(1));
    expect(messageField.single.controller!.text, 'Ship it later');
    expect(find.text('Sends to Ada Lovelace.'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(ScheduleMessageDialog), findsNothing);
    expect(scheduled.items, isEmpty);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
  });

  testWidgets('scheduling stores the message and clears the composer', (
    tester,
  ) async {
    await pumpComposer(tester);

    await tester.enterText(find.byType(TextField), 'Ship it later');
    await tester.pump();
    await tester.tap(find.byTooltip('Schedule message'));
    await tester.pumpAndSettle();

    // The dialog's own TextField is the second one on screen.
    final dialog = find.byType(ScheduleMessageDialog);
    expect(dialog, findsOneWidget);
    await tester.tap(
      find.descendant(of: dialog, matching: find.text('Schedule')),
    );
    await tester.pumpAndSettle();

    expect(scheduled.items, hasLength(1));
    expect(scheduled.items.single.content, 'Ship it later');
    expect(scheduled.items.single.conversationName, 'Ada Lovelace');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });
}
