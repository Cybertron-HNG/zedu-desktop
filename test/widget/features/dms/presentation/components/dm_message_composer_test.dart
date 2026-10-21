import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

class _MockDmRepository extends Mock implements DmRepository {}

class _TestXFile extends XFile {
  _TestXFile(super.path, {super.name});

  @override
  Future<int> length() async => 3;
}

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
      currentOrganisationSlug: 'test-org',
      avatarUrl: '',
      defaultAvatarUrl: '',
    ),
  );
}

Widget buildComposerUnderTest() {
  return ProviderScope(
    child: buildTestMaterialApp(
      const Scaffold(
        body: DmMessageComposer(
          recipientName: 'Ada',
          channelId: 'channel-1',
          participants: [],
        ),
      ),
    ),
  );
}

TextEditingController composerController(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).controller;

Future<void> typeAndSelect(
  WidgetTester tester,
  String text, {
  TextSelection? selection,
}) async {
  await tester.tap(find.byType(TextField));
  await tester.enterText(find.byType(TextField), text);
  composerController(tester).selection =
      selection ?? TextSelection(baseOffset: 0, extentOffset: text.length);
  await tester.pump();
}

Future<void> pressShortcut(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  LogicalKeyboardKey modifier = LogicalKeyboardKey.controlLeft,
}) async {
  await tester.sendKeyDownEvent(modifier);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(modifier);
  await tester.pump();
}

void main() {
  group('DmMessageComposer formatting shortcuts', () {
    testWidgets('Ctrl+B wraps the selected text in bold markers', (
      tester,
    ) async {
      await tester.pumpWidget(buildComposerUnderTest());
      await typeAndSelect(tester, 'hello');

      await pressShortcut(tester, LogicalKeyboardKey.keyB);

      expect(composerController(tester).text, '**hello**');
    });

    testWidgets('Ctrl+I wraps the selected text in italic markers', (
      tester,
    ) async {
      await tester.pumpWidget(buildComposerUnderTest());
      await typeAndSelect(tester, 'hello');

      await pressShortcut(tester, LogicalKeyboardKey.keyI);

      expect(composerController(tester).text, '*hello*');
    });

    testWidgets('Cmd+B works the same as Ctrl+B', (tester) async {
      await tester.pumpWidget(buildComposerUnderTest());
      await typeAndSelect(tester, 'hello');

      await pressShortcut(
        tester,
        LogicalKeyboardKey.keyB,
        modifier: LogicalKeyboardKey.metaLeft,
      );

      expect(composerController(tester).text, '**hello**');
    });

    testWidgets('with no selection, inserts markers with cursor between', (
      tester,
    ) async {
      await tester.pumpWidget(buildComposerUnderTest());
      await typeAndSelect(
        tester,
        'hi ',
        selection: const TextSelection.collapsed(offset: 3),
      );

      await pressShortcut(tester, LogicalKeyboardKey.keyB);

      final controller = composerController(tester);
      expect(controller.text, 'hi ****');
      expect(controller.selection, const TextSelection.collapsed(offset: 5));
    });
  });

  group('DmMessageComposer conversation switch cleanup', () {
    testWidgets(
      'switching channelId clears pending files, mention suggestions, and active edit mode',
      (tester) async {
        final repository = _MockDmRepository();
        when(
          () => repository.getMessages('ch-1', page: any(named: 'page')),
        ).thenAnswer(
          (_) async => [
            {
              'id': 'm-1',
              'content': 'Original message in DM 1',
              'user_id': 'user-1',
              'created_at': '2026-10-21T08:00:00Z',
            },
          ],
        );
        when(
          () => repository.getMessages('ch-2', page: any(named: 'page')),
        ).thenAnswer((_) async => []);
        when(
          () => repository.sendMessage(
            any(),
            any(),
            media: any(named: 'media'),
            mentions: any(named: 'mentions'),
            isChannel: any(named: 'isChannel'),
          ),
        ).thenAnswer((_) async {});

        final composerKey = GlobalKey<DmMessageComposerState>();
        final channelNotifier = ValueNotifier<String>('ch-1');
        addTearDown(channelNotifier.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              dmRepositoryProvider.overrideWithValue(repository),
              authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
            ],
            child: buildTestMaterialApp(
              Scaffold(
                body: ValueListenableBuilder<String>(
                  valueListenable: channelNotifier,
                  builder: (context, channelId, _) {
                    return DmMessageComposer(
                      key: composerKey,
                      recipientName: channelId == 'ch-1' ? '@ada' : '@grace',
                      channelId: channelId,
                      participants: [
                        DmParticipant(
                          userId: 'u-2',
                          username: 'ada',
                          email: 'ada@example.com',
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Prime ch-1 history so lastSentMessageId is available for ArrowUp edit mode.
        final container = ProviderScope.containerOf(
          tester.element(find.byType(DmMessageComposer)),
        );
        final history1 = container.read(chatHistoryProvider('ch-1'));
        await tester.pump();

        // Attach a pending file in ch-1.
        await composerKey.currentState!.addFiles([
          _TestXFile('/tmp/secret-dm1.txt', name: 'secret-dm1.txt'),
        ]);
        await tester.pump();
        expect(find.text('secret-dm1.txt'), findsOneWidget);

        // Press ArrowUp with empty text to enter edit mode on ch-1's message.
        await tester.tap(find.byType(TextField));
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();

        expect(find.text('Editing message'), findsOneWidget);
        expect(history1.editingMessageId, 'm-1');
        expect(composerController(tester).text, 'Original message in DM 1');

        // Switch to ch-2 while composerKey preserves the same DmMessageComposerState.
        channelNotifier.value = 'ch-2';
        await tester.pump();

        expect(find.text('Editing message'), findsNothing);
        expect(find.text('secret-dm1.txt'), findsNothing);
        expect(history1.editingMessageId, isNull);
        expect(composerController(tester).text, isEmpty);

        // Sending in ch-2 should not include ch-1's attachment.
        await tester.enterText(find.byType(TextField), 'Hello Grace');
        await tester.pump();
        await pressShortcut(tester, LogicalKeyboardKey.enter);
        await tester.pump();

        verify(
          () => repository.sendMessage(
            'ch-2',
            'Hello Grace',
            media: const <XFile>[],
            mentions: any(named: 'mentions'),
            isChannel: false,
          ),
        ).called(1);
      },
    );
  });
}
