import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late MockSecureStorageService storage;
  late Map<String, String> disk;
  late DateTime now;
  late List<ScheduledMessage> sent;
  late List<String> failures;
  late ScheduledMessagesStore store;

  setUp(() {
    storage = MockSecureStorageService();
    disk = {};
    now = DateTime(2026, 11, 5, 9);
    sent = [];
    failures = [];
    when(() => storage.readData(any())).thenAnswer((inv) async {
      return disk[inv.positionalArguments.first as String];
    });
    when(() => storage.writeData(any(), any())).thenAnswer((inv) async {
      disk[inv.positionalArguments[0] as String] =
          inv.positionalArguments[1] as String;
    });
  });

  tearDown(() => store.dispose());

  ScheduledMessagesStore makeStore({
    String userId = 'u1',
    bool failSends = false,
  }) => ScheduledMessagesStore(
    storage,
    userId: userId,
    clock: () => now,
    onSend: (message) async {
      if (failSends && failures.isNotEmpty) {
        failures.removeAt(0);
        throw StateError('offline');
      }
      sent.add(message);
    },
  );

  Future<ScheduledMessage> add(
    ScheduledMessagesStore store, {
    String content = 'See you soon',
    Duration inFuture = const Duration(hours: 1),
  }) => store.add(
    channelId: 'ch-1',
    conversationName: 'Ada Lovelace',
    content: content,
    sendAt: now.add(inFuture),
  );

  test('adds a message and saves it for the user', () async {
    store = makeStore();
    await store.load();

    await add(store);

    expect(store.items, hasLength(1));
    expect(store.items.single.content, 'See you soon');
    expect(store.items.single.conversationName, 'Ada Lovelace');
    final saved = jsonDecode(disk['scheduled_messages_u1']!) as List<dynamic>;
    expect(saved, hasLength(1));
    expect((saved.single as Map)['content'], 'See you soon');
  });

  test('keeps the queue soonest first', () async {
    store = makeStore();
    await store.load();

    await add(store, content: 'later', inFuture: const Duration(hours: 3));
    await add(store, content: 'sooner', inFuture: const Duration(minutes: 20));

    expect(store.items.map((m) => m.content), ['sooner', 'later']);
  });

  test('loads saved messages', () async {
    disk['scheduled_messages_u1'] = jsonEncode([
      ScheduledMessage(
        id: 's1',
        channelId: 'ch-1',
        conversationName: 'Ada',
        content: 'Stored',
        sendAt: now.add(const Duration(hours: 2)),
        createdAt: now,
      ).toJson(),
    ]);
    store = makeStore();

    await store.load();

    expect(store.isLoaded, isTrue);
    expect(store.items.single.content, 'Stored');
  });

  test('ignores corrupt saved data', () async {
    disk['scheduled_messages_u1'] = 'not json';
    store = makeStore();

    await store.load();

    expect(store.isLoaded, isTrue);
    expect(store.items, isEmpty);
  });

  test('signed out keeps messages in memory only', () async {
    store = makeStore(userId: '');
    await store.load();

    await add(store);

    expect(store.items, hasLength(1));
    verifyNever(() => storage.writeData(any(), any()));
  });

  test('sends a due message once and removes it', () async {
    store = makeStore();
    await store.load();
    await add(store, inFuture: Duration.zero);

    await store.checkDue();

    expect(sent, hasLength(1));
    expect(sent.single.content, 'See you soon');
    expect(store.items, isEmpty);

    await store.checkDue();
    expect(sent, hasLength(1));
  });

  test('does not send before the chosen time', () async {
    store = makeStore();
    await store.load();
    await add(store);

    await store.checkDue();

    expect(sent, isEmpty);
    expect(store.items, hasLength(1));
  });

  test('sends messages that came due while the app was closed', () async {
    disk['scheduled_messages_u1'] = jsonEncode([
      ScheduledMessage(
        id: 's1',
        channelId: 'ch-1',
        conversationName: 'Ada',
        content: 'Late',
        sendAt: now.subtract(const Duration(hours: 2)),
        createdAt: now.subtract(const Duration(hours: 3)),
      ).toJson(),
    ]);
    store = makeStore();

    await store.load();

    expect(sent.single.content, 'Late');
    expect(store.items, isEmpty);
  });

  test('keeps a failed message and retries after a minute', () async {
    failures.add('offline');
    store = makeStore(failSends: true);
    await store.load();
    await add(store, inFuture: Duration.zero);

    await store.checkDue();

    expect(sent, isEmpty);
    expect(store.items.single.lastError, isNotNull);
    expect(store.items.single.retryAt, now.add(const Duration(minutes: 1)));

    now = now.add(const Duration(minutes: 2));
    await store.checkDue();

    expect(sent, hasLength(1));
    expect(store.items, isEmpty);
  });

  test('update edits the text and the time', () async {
    store = makeStore();
    await store.load();
    final message = await add(store);
    final later = now.add(const Duration(days: 1));

    await store.update(message.id, content: 'Changed', sendAt: later);

    expect(store.items.single.content, 'Changed');
    expect(store.items.single.sendAt, later);
  });

  test('cancel removes the message and forgets it on disk', () async {
    store = makeStore();
    await store.load();
    final message = await add(store);

    await store.cancel(message.id);

    expect(store.items, isEmpty);
    expect(jsonDecode(disk['scheduled_messages_u1']!), isEmpty);
  });
}
