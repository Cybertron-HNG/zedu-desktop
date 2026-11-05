import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

MessageReminder reminder(
  String messageId, {
  String content = 'follow up on this',
  String conversation = 'Ada Lovelace',
  DateTime? remindAt,
}) => MessageReminder(
  messageId: messageId,
  channelId: 'ch-1',
  conversationName: conversation,
  participantId: 'u-2',
  content: content,
  remindAt: remindAt ?? DateTime(2030, 1, 6, 9),
  createdAt: DateTime(2026, 11, 5, 9),
);

void main() {
  late MockSecureStorageService storage;

  setUp(() {
    storage = MockSecureStorageService();
    when(() => storage.readData(any())).thenAnswer((_) async => null);
    when(() => storage.writeData(any(), any())).thenAnswer((_) async {});
  });

  final now = DateTime(2026, 11, 5, 10, 15);

  testWidgets('offers the presets with the time each one means', (
    tester,
  ) async {
    ReminderPreset? chosen;

    await tester.pumpWidget(
      buildTestMaterialApp(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                chosen = await showDialog<ReminderPreset>(
                  context: context,
                  builder: (_) => MessageReminderDialog(now: now),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('In 20 minutes'), findsOneWidget);
    expect(find.text('In 1 hour'), findsOneWidget);
    expect(find.text('This evening'), findsOneWidget);
    expect(find.text('Tomorrow morning'), findsOneWidget);
    expect(find.text('today at 6:00 PM'), findsOneWidget);
    expect(find.text('tomorrow at 9:00 AM'), findsOneWidget);

    await tester.tap(find.text('In 20 minutes'));
    await tester.pumpAndSettle();

    expect(chosen, ReminderPreset.in20Minutes);
  });

  testWidgets('a cancelled picker returns nothing', (tester) async {
    ReminderPreset? chosen;

    await tester.pumpWidget(
      buildTestMaterialApp(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                chosen = await showDialog<ReminderPreset>(
                  context: context,
                  builder: (_) => MessageReminderDialog(now: now),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(chosen, isNull);
  });

  testWidgets('upcoming list shows an empty state before anything is set', (
    tester,
  ) async {
    final store = MessageRemindersStore(storage, userId: 'user-1');
    await store.load();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [messageRemindersStoreProvider.overrideWith((ref) => store)],
        child: buildTestMaterialApp(
          const Scaffold(body: UpcomingRemindersDialog()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reminders'), findsOneWidget);
    expect(find.textContaining('No reminders yet'), findsOneWidget);
  });

  testWidgets('upcoming list shows reminders soonest first and cancels one', (
    tester,
  ) async {
    final store = MessageRemindersStore(storage, userId: 'user-1');
    await store.load();
    await store.add(
      reminder(
        'm2',
        content: 'later reminder',
        conversation: 'Bola',
        remindAt: DateTime(2030, 1, 7, 9),
      ),
    );
    await store.add(
      reminder(
        'm1',
        content: 'sooner reminder',
        remindAt: DateTime(2030, 1, 6, 9),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [messageRemindersStoreProvider.overrideWith((ref) => store)],
        child: buildTestMaterialApp(
          const Scaffold(body: UpcomingRemindersDialog()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNWidgets(2));
    expect(find.text('sooner reminder'), findsOneWidget);
    expect(find.text('later reminder'), findsOneWidget);
    expect(find.textContaining('Bola ·'), findsOneWidget);

    final titles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((tile) => ((tile.title as Text).data))
        .toList();
    expect(titles, ['sooner reminder', 'later reminder']);

    await tester.tap(find.byTooltip('Cancel reminder').first);
    await tester.pumpAndSettle();

    expect(store.items.map((item) => item.messageId), ['m2']);
    expect(find.text('sooner reminder'), findsNothing);
  });
}
