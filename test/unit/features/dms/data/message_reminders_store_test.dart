import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

MessageReminder reminder(
  String messageId, {
  String channelId = 'ch-1',
  String content = 'hello',
  DateTime? remindAt,
}) => MessageReminder(
  messageId: messageId,
  channelId: channelId,
  conversationName: 'Ada Lovelace',
  participantId: 'u-2',
  content: content,
  remindAt: remindAt ?? DateTime(2026, 11, 5, 12),
  createdAt: DateTime(2026, 11, 5, 10),
);

void main() {
  late MockSecureStorageService storage;
  late Map<String, String> values;
  late MessageRemindersStore store;
  late List<MessageReminder> fired;
  late DateTime now;

  setUp(() {
    storage = MockSecureStorageService();
    values = <String, String>{};
    fired = <MessageReminder>[];
    now = DateTime(2026, 11, 5, 10, 15);

    when(() => storage.readData(any())).thenAnswer((invocation) async {
      final key = invocation.positionalArguments[0] as String;
      return values[key];
    });

    when(() => storage.writeData(any(), any())).thenAnswer((invocation) async {
      final key = invocation.positionalArguments[0] as String;
      final value = invocation.positionalArguments[1] as String;
      values[key] = value;
    });

    store = MessageRemindersStore(
      storage,
      userId: 'user-1',
      clock: () => now,
      onDue: fired.add,
    );
    addTearDown(store.dispose);
  });

  group('ReminderPreset', () {
    test('relative presets add from now', () {
      expect(
        ReminderPreset.in20Minutes.resolve(now),
        DateTime(2026, 11, 5, 10, 35),
      );
      expect(
        ReminderPreset.in1Hour.resolve(now),
        DateTime(2026, 11, 5, 11, 15),
      );
    });

    test('this evening means 6pm today while it is still ahead', () {
      expect(
        ReminderPreset.thisEvening.resolve(now),
        DateTime(2026, 11, 5, 18),
      );
    });

    test('this evening rolls to tomorrow once 6pm has passed', () {
      expect(
        ReminderPreset.thisEvening.resolve(DateTime(2026, 11, 5, 19, 30)),
        DateTime(2026, 11, 6, 18),
      );
    });

    test('tomorrow morning is 9am the next day, across a month end', () {
      expect(
        ReminderPreset.tomorrowMorning.resolve(DateTime(2026, 11, 30, 22)),
        DateTime(2026, 12, 1, 9),
      );
    });
  });

  test('starts empty and loads once', () async {
    await store.load();

    expect(store.isLoaded, isTrue);
    expect(store.items, isEmpty);
    expect(values, isEmpty);
  });

  test('adds reminders soonest first and persists them', () async {
    await store.load();

    await store.add(reminder('m2', remindAt: DateTime(2026, 11, 5, 15)));
    await store.add(reminder('m1', remindAt: DateTime(2026, 11, 5, 12)));

    expect(store.items.map((item) => item.messageId), ['m1', 'm2']);
    final persisted =
        jsonDecode(values['message_reminders_user-1']!) as List<dynamic>;
    expect(persisted, hasLength(2));
  });

  test('setting a reminder again for the same message replaces it', () async {
    await store.load();

    await store.add(reminder('m1', remindAt: DateTime(2026, 11, 5, 12)));
    await store.add(reminder('m1', remindAt: DateTime(2026, 11, 5, 16)));

    expect(store.items, hasLength(1));
    expect(store.items.single.remindAt, DateTime(2026, 11, 5, 16));
    expect(store.forMessage('ch-1', 'm1')?.remindAt, DateTime(2026, 11, 5, 16));
  });

  test('restores saved reminders on load', () async {
    values['message_reminders_user-1'] = jsonEncode([
      reminder('m1', remindAt: DateTime(2026, 11, 6, 9)).toJson(),
    ]);

    final restored = MessageRemindersStore(
      storage,
      userId: 'user-1',
      clock: () => now,
      onDue: fired.add,
    );
    addTearDown(restored.dispose);
    await restored.load();

    expect(restored.items.single.messageId, 'm1');
    expect(restored.forMessage('ch-1', 'm1'), isNotNull);
  });

  test('a due reminder fires once and is forgotten', () async {
    await store.load();
    await store.add(reminder('m1', remindAt: DateTime(2026, 11, 5, 10)));
    await store.add(reminder('m2', remindAt: DateTime(2026, 11, 5, 23)));

    await store.checkDue();

    expect(fired.map((item) => item.messageId), ['m1']);
    expect(store.items.map((item) => item.messageId), ['m2']);
    final persisted =
        jsonDecode(values['message_reminders_user-1']!) as List<dynamic>;
    expect(persisted, hasLength(1));

    await store.checkDue();
    expect(fired, hasLength(1));
  });

  test('a reminder that came due while closed fires on load', () async {
    values['message_reminders_user-1'] = jsonEncode([
      reminder('m1', remindAt: DateTime(2026, 11, 5, 9)).toJson(),
    ]);

    final restored = MessageRemindersStore(
      storage,
      userId: 'user-1',
      clock: () => now,
      onDue: fired.add,
    );
    addTearDown(restored.dispose);
    await restored.load();

    expect(fired.map((item) => item.messageId), ['m1']);
    expect(restored.items, isEmpty);
  });

  test('cancel removes the reminder and persists', () async {
    await store.load();
    await store.add(reminder('m1'));
    await store.add(reminder('m2'));

    await store.cancel('ch-1:m1');

    expect(store.items.map((item) => item.messageId), ['m2']);
    final persisted =
        jsonDecode(values['message_reminders_user-1']!) as List<dynamic>;
    expect(persisted, hasLength(1));
  });

  test('a corrupt stored list starts empty instead of throwing', () async {
    values['message_reminders_user-1'] = 'not json';

    await store.load();

    expect(store.items, isEmpty);
    expect(store.isLoaded, isTrue);
  });

  test('signed out does not read or write storage', () async {
    final signedOut = MessageRemindersStore(
      storage,
      userId: '',
      clock: () => now,
      onDue: fired.add,
    );
    addTearDown(signedOut.dispose);

    await signedOut.load();
    await signedOut.add(reminder('m1'));

    expect(signedOut.items, hasLength(1));
    expect(values, isEmpty);
    verifyNever(() => storage.readData(any()));
    verifyNever(() => storage.writeData(any(), any()));
  });
}
