import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

class FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}

Widget buildResetPasswordViewUnderTest() {
  return ProviderScope(
    overrides: [authNotifierProvider.overrideWith(() => FakeAuthNotifier())],
    child: const MaterialApp(home: ResetPasswordView(email: 'a@b.com')),
  );
}

/// The six code boxes, in order.
Finder codeBox(int index) => find.byType(TextFormField).at(index);

List<String> codeDigits(WidgetTester tester) => [
  for (var i = 0; i < 6; i++)
    tester.widget<TextFormField>(codeBox(i)).controller!.text,
];

bool hasFocus(WidgetTester tester, int index) {
  final editable = find.descendant(
    of: codeBox(index),
    matching: find.byType(EditableText),
  );
  return tester.widget<EditableText>(editable).focusNode.hasFocus;
}

void main() {
  group('ResetPasswordView code boxes', () {
    Future<void> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildResetPasswordViewUnderTest());
      await tester.pump();
    }

    testWidgets('pasting a 6-digit code into the first box fills all six', (
      tester,
    ) async {
      await pump(tester);

      await tester.enterText(codeBox(0), '123456');
      await tester.pump();

      expect(codeDigits(tester), ['1', '2', '3', '4', '5', '6']);
      expect(hasFocus(tester, 5), isTrue);
    });

    testWidgets('pasting into a later box fills from that box on', (
      tester,
    ) async {
      await pump(tester);

      await tester.enterText(codeBox(2), '9876');
      await tester.pump();

      expect(codeDigits(tester), ['', '', '9', '8', '7', '6']);
    });

    testWidgets('a pasted code with spaces or dashes keeps only its digits', (
      tester,
    ) async {
      await pump(tester);

      await tester.enterText(codeBox(0), '12-34 56');
      await tester.pump();

      expect(codeDigits(tester), ['1', '2', '3', '4', '5', '6']);
    });

    testWidgets('a longer paste is cut to the boxes left', (tester) async {
      await pump(tester);

      await tester.enterText(codeBox(3), '12345678');
      await tester.pump();

      expect(codeDigits(tester), ['', '', '', '1', '2', '3']);
    });

    testWidgets('typing one digit still moves to the next box', (tester) async {
      await pump(tester);

      await tester.enterText(codeBox(0), '4');
      await tester.pump();

      expect(codeDigits(tester), ['4', '', '', '', '', '']);
      expect(hasFocus(tester, 1), isTrue);
    });

    testWidgets('typing into a filled box replaces its digit', (tester) async {
      await pump(tester);
      await tester.enterText(codeBox(0), '4');
      await tester.pump();

      // The field holds '4' with the cursor after it; typing 7 gives '47'.
      await tester.enterText(codeBox(0), '47');
      await tester.pump();

      expect(codeDigits(tester), ['7', '', '', '', '', '']);
      expect(hasFocus(tester, 1), isTrue);
    });

    testWidgets('clearing a box moves back to the previous one', (
      tester,
    ) async {
      await pump(tester);
      await tester.enterText(codeBox(0), '4');
      await tester.enterText(codeBox(1), '5');
      await tester.pump();

      await tester.enterText(codeBox(1), '');
      await tester.pump();

      expect(codeDigits(tester), ['4', '', '', '', '', '']);
      expect(hasFocus(tester, 0), isTrue);
    });
  });
}
