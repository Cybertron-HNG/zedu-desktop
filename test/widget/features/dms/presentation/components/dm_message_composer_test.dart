import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

class MockDmRepository extends Mock implements DmRepository {}

/// Keeps a send off GetIt and the network: the composer only reads the
/// current user id and forwards to the repository.
class FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}

MockDmRepository buildMockRepository() {
  final repository = MockDmRepository();
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
    ),
  ).thenAnswer((_) async {});
  when(
    () => repository.editMessage(any(), content: any(named: 'content')),
  ).thenAnswer((_) async {});
  return repository;
}

final adaParticipant = DmParticipant(
  userId: 'user-1',
  username: 'ada_test',
  email: 'ada@example.com',
);

Widget buildComposerUnderTest({
  List<DmParticipant> participants = const [],
  ValueChanged<String>? onSend,
}) {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(FakeAuthNotifier.new),
      dmRepositoryProvider.overrideWithValue(buildMockRepository()),
    ],
    child: buildTestMaterialApp(
      Scaffold(
        body: DmMessageComposer(
          recipientName: 'Ada',
          channelId: 'channel-1',
          participants: participants,
          onSend: onSend,
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

/// Types [text] leaving a collapsed cursor at the end, which is what the
/// @mention trigger needs.
Future<void> typeAtEnd(WidgetTester tester, String text) async {
  await tester.tap(find.byType(TextField));
  await tester.enterText(find.byType(TextField), text);
  composerController(tester).selection = TextSelection.collapsed(
    offset: text.length,
  );
  await tester.pump();
}

/// Presses [key] with no modifier held.
Future<void> pressKey(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
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

  group('DmMessageComposer sending', () {
    testWidgets('Enter sends the message and clears the box', (tester) async {
      final sent = <String>[];
      await tester.pumpWidget(buildComposerUnderTest(onSend: sent.add));
      await typeAtEnd(tester, 'hello');

      await pressKey(tester, LogicalKeyboardKey.enter);

      expect(sent, ['hello']);
      expect(composerController(tester).text, isEmpty);
    });

    testWidgets('Enter on an empty box sends nothing', (tester) async {
      final sent = <String>[];
      await tester.pumpWidget(buildComposerUnderTest(onSend: sent.add));

      await pressKey(tester, LogicalKeyboardKey.enter);

      expect(sent, isEmpty);
      expect(composerController(tester).text, isEmpty);
    });

    testWidgets('Shift+Enter does not send', (tester) async {
      final sent = <String>[];
      await tester.pumpWidget(buildComposerUnderTest(onSend: sent.add));
      await typeAtEnd(tester, 'hello');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await pressKey(tester, LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);

      expect(sent, isEmpty);
      expect(composerController(tester).text, 'hello');
    });

    testWidgets('Ctrl+Enter sends', (tester) async {
      final sent = <String>[];
      await tester.pumpWidget(buildComposerUnderTest(onSend: sent.add));
      await typeAtEnd(tester, 'hello');

      await pressShortcut(tester, LogicalKeyboardKey.enter);

      expect(sent, ['hello']);
    });

    testWidgets('Cmd+Enter sends', (tester) async {
      final sent = <String>[];
      await tester.pumpWidget(buildComposerUnderTest(onSend: sent.add));
      await typeAtEnd(tester, 'hello');

      await pressShortcut(
        tester,
        LogicalKeyboardKey.enter,
        modifier: LogicalKeyboardKey.metaLeft,
      );

      expect(sent, ['hello']);
    });
  });

  group('DmMessageComposer @mention suggestions', () {
    Future<void> openSuggestionList(
      WidgetTester tester,
      List<String> sent,
    ) async {
      await tester.pumpWidget(
        buildComposerUnderTest(
          participants: [adaParticipant],
          onSend: sent.add,
        ),
      );
      await typeAtEnd(tester, 'hi @ad');
      expect(find.text('People'), findsOneWidget);
    }

    testWidgets('Enter inserts the suggestion instead of sending', (
      tester,
    ) async {
      final sent = <String>[];
      await openSuggestionList(tester, sent);

      await pressKey(tester, LogicalKeyboardKey.enter);

      expect(sent, isEmpty);
      expect(composerController(tester).text, 'hi @ada_test ');
      expect(find.text('People'), findsNothing);
    });

    testWidgets('numpad Enter inserts the suggestion instead of sending', (
      tester,
    ) async {
      final sent = <String>[];
      await openSuggestionList(tester, sent);

      await pressKey(tester, LogicalKeyboardKey.numpadEnter);

      expect(sent, isEmpty);
      expect(composerController(tester).text, 'hi @ada_test ');
      expect(find.text('People'), findsNothing);
    });

    testWidgets('Tab inserts the suggestion instead of sending', (
      tester,
    ) async {
      final sent = <String>[];
      await openSuggestionList(tester, sent);

      await pressKey(tester, LogicalKeyboardKey.tab);

      expect(sent, isEmpty);
      expect(composerController(tester).text, 'hi @ada_test ');
      expect(find.text('People'), findsNothing);
    });

    testWidgets('Enter with the list open keeps the text in the box', (
      tester,
    ) async {
      final sent = <String>[];
      await openSuggestionList(tester, sent);

      await pressKey(tester, LogicalKeyboardKey.enter);

      expect(sent, isEmpty);
      expect(composerController(tester).text, isNotEmpty);
    });

    testWidgets('Escape closes the list and sends nothing', (tester) async {
      final sent = <String>[];
      await openSuggestionList(tester, sent);

      await pressKey(tester, LogicalKeyboardKey.escape);

      expect(sent, isEmpty);
      expect(find.text('People'), findsNothing);
      expect(composerController(tester).text, 'hi @ad');
    });
  });
}
