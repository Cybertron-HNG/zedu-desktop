import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  final now = DateTime(2026, 11, 5, 9);

  group('ScheduleMessageDialog', () {
    /// Opens the dialog and returns a getter for the value it popped with.
    Future<ScheduleDraft? Function()> openDialog(
      WidgetTester tester, {
      String initialText = '',
      DateTime? initialSendAt,
      DateTime? pickedDate,
      TimeOfDay? pickedTime,
    }) async {
      ScheduleDraft? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showDialog<ScheduleDraft>(
                      context: context,
                      builder: (context) => ScheduleMessageDialog(
                        conversationName: 'Ada Lovelace',
                        initialText: initialText,
                        initialSendAt: initialSendAt,
                        now: () => now,
                        pickDate: (_, _) async => pickedDate,
                        pickTime: (_, _) async => pickedTime,
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return () => result;
    }

    testWidgets('schedules the typed text for the chosen date and time', (
      tester,
    ) async {
      final result = await openDialog(
        tester,
        pickedDate: DateTime(2026, 11, 6),
        pickedTime: const TimeOfDay(hour: 15, minute: 30),
      );

      expect(find.text('5 Nov 2026'), findsOneWidget);
      expect(find.text('10:00 AM'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'See you tomorrow');

      await tester.tap(find.byIcon(Icons.event_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.schedule));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();

      final draft = result();
      expect(draft, isNotNull);
      expect(draft!.content, 'See you tomorrow');
      expect(draft.sendAt, DateTime(2026, 11, 6, 15, 30));
    });

    testWidgets('refuses a time that has already passed', (tester) async {
      final result = await openDialog(
        tester,
        initialText: 'Too late',
        pickedTime: const TimeOfDay(hour: 8, minute: 0),
      );

      await tester.tap(find.byIcon(Icons.schedule));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();

      expect(find.text('Pick a time in the future.'), findsOneWidget);
      expect(find.text('Schedule message'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result(), isNull);
    });

    testWidgets('needs a message to schedule', (tester) async {
      final result = await openDialog(tester);

      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();

      expect(find.text('Write a message to schedule.'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result(), isNull);
    });

    testWidgets('editing shows the saved text and time', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScheduleMessageDialog(
            conversationName: 'Ada Lovelace',
            initialText: 'Saved text',
            initialSendAt: DateTime(2026, 11, 6, 10),
            now: () => now,
          ),
        ),
      );

      expect(find.text('Edit scheduled message'), findsOneWidget);
      expect(find.text('Saved text'), findsOneWidget);
      expect(find.text('6 Nov 2026'), findsOneWidget);
      expect(find.text('10:00 AM'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });
  });

  group('ScheduledMessagesDialog', () {
    late MockSecureStorageService storage;
    late ScheduledMessagesStore store;
    late List<ScheduledMessage> sent;

    setUp(() {
      storage = MockSecureStorageService();
      when(() => storage.readData(any())).thenAnswer((_) async => null);
      when(() => storage.writeData(any(), any())).thenAnswer((_) async {});
      sent = [];
      store = ScheduledMessagesStore(
        storage,
        userId: 'u1',
        clock: () => now,
        armTimers: false,
        onSend: (message) async => sent.add(message),
      );
    });

    tearDown(() => store.dispose());

    Future<void> seed() async {
      await store.load();
      await store.add(
        channelId: 'ch-1',
        conversationName: 'Ada Lovelace',
        content: 'Later today',
        sendAt: now.add(const Duration(hours: 2)),
      );
      await store.add(
        channelId: 'ch-2',
        conversationName: 'Grace Hopper',
        content: 'Tomorrow',
        sendAt: now.add(const Duration(days: 1)),
      );
    }

    Future<void> pumpDialog(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) =>
                        ScheduledMessagesDialog(store: store, now: () => now),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('lists pending messages soonest first with their time', (
      tester,
    ) async {
      await seed();
      await pumpDialog(tester);

      expect(
        find.text('Ada Lovelace · sends today at 11:00 AM'),
        findsOneWidget,
      );
      expect(
        find.text('Grace Hopper · sends tomorrow at 9:00 AM'),
        findsOneWidget,
      );
      final later = tester.getTopLeft(find.text('Later today')).dy;
      final tomorrow = tester.getTopLeft(find.text('Tomorrow')).dy;
      expect(later, lessThan(tomorrow));
    });

    testWidgets('cancelling removes the message and nothing is sent', (
      tester,
    ) async {
      await seed();
      await pumpDialog(tester);

      await tester.tap(find.byTooltip('Cancel scheduled message').first);
      await tester.pumpAndSettle();
      expect(find.text('Cancel scheduled message?'), findsOneWidget);

      await tester.tap(find.text('Cancel message'));
      await tester.pumpAndSettle();

      expect(store.items.map((m) => m.content), ['Tomorrow']);
      expect(find.text('Later today'), findsNothing);
      expect(sent, isEmpty);
    });

    testWidgets('editing changes the pending text', (tester) async {
      await seed();
      await pumpDialog(tester);

      await tester.tap(find.byTooltip('Edit scheduled message').first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Edited message');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(store.items.map((m) => m.content), contains('Edited message'));
      expect(find.text('Edited message'), findsOneWidget);
    });

    testWidgets('says when there is nothing scheduled', (tester) async {
      await store.load();
      await pumpDialog(tester);

      expect(find.text('No scheduled messages yet.'), findsOneWidget);
    });
  });
}
