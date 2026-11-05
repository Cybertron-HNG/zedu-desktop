import 'dart:async';

import '../../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class _MockDmRepository extends Mock implements DmRepository {}

class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: User(
      id: 'user-1',
      firstName: 'Test',
      lastName: 'User',
      email: 'test@example.com',
      phone: '',
      username: 'testuser',
      isVerified: true,
      isOnboarded: true,
      createdAt: DateTime(2026),
      currentOrg: 'org-1',
      currentOrganisationSlug: 'org-slug',
      avatarUrl: '',
      defaultAvatarUrl: '',
    ),
  );
}

void main() {
  late _MockDmRepository repository;
  late ChatHistoryNotifier notifier;
  late Completer<String> send;
  ProgressCallback? reportProgress;

  final media = [
    XFile.fromData(Uint8List(100), name: 'a.pdf'),
    XFile.fromData(Uint8List(300), name: 'b.png'),
  ];

  List<Object?> progress() => [
    for (final file in notifier.messages.first['media'] as List)
      (file as Map)['upload_progress'],
  ];

  setUp(() async {
    repository = _MockDmRepository();
    send = Completer<String>();
    reportProgress = null;
    when(
      () => repository.getMessages(any(), page: any(named: 'page')),
    ).thenAnswer((_) async => <Map<String, dynamic>>[]);
    when(
      () => repository.sendMessage(
        any(),
        any(),
        media: any(named: 'media'),
        mentions: any(named: 'mentions'),
        isChannel: any(named: 'isChannel'),
        onUploadProgress: any(named: 'onUploadProgress'),
      ),
    ).thenAnswer((invocation) {
      reportProgress =
          invocation.namedArguments[#onUploadProgress] as ProgressCallback?;
      return send.future;
    });

    final container = ProviderContainer(
      overrides: [
        dmRepositoryProvider.overrideWithValue(repository),
        authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(chatHistoryProvider('ch-1'), (_, _) {});
    addTearDown(sub.close);
    notifier = sub.read();
    await pumpEventQueue();
  });

  test('shares the upload progress over the files in order by size', () async {
    final sending = notifier.sendMessage('', media: media);
    // Let the file sizes be read.
    await pumpEventQueue();

    // A quarter of 400 bytes: the 100-byte first file is fully sent.
    reportProgress!(250, 1000);
    expect(progress(), [1.0, 0.0]);

    // 70% is 280 bytes: the second file has 180 of its 300 bytes.
    reportProgress!(700, 1000);
    expect(progress()[0], 1.0);
    expect(progress()[1], closeTo(0.6, 1e-9));

    send.complete('thread-1');
    await sending;

    // Sent: the bars go away.
    expect(notifier.messages.first['status'], isNull);
    expect(progress(), [null, null]);
  });

  test('only tells listeners when the percentage changes', () async {
    final sending = notifier.sendMessage('', media: media);
    await pumpEventQueue();
    var notified = 0;
    void count() => notified++;
    notifier.addListener(count);
    addTearDown(() => notifier.removeListener(count));

    reportProgress!(500, 1000);
    reportProgress!(501, 1000);
    reportProgress!(509, 1000);
    expect(notified, 1);

    send.complete('thread-1');
    await sending;
  });

  test('a failed upload drops its progress', () async {
    final sending = notifier.sendMessage('', media: media);
    await pumpEventQueue();
    reportProgress!(500, 1000);

    send.completeError(Exception('offline'));
    await sending;

    expect(notifier.messages.first['status'], 'failed');
    expect(progress(), [null, null]);
  });

  test('a message without files reports no progress', () async {
    final sending = notifier.sendMessage('hello');
    await pumpEventQueue();

    expect(reportProgress, isNull);

    send.complete('thread-1');
    await sending;
  });
}
