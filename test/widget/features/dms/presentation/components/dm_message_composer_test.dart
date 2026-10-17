import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

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

void main() {
  group('DmMessageComposer block quotes', () {
    const cases = [
      (
        name: 'quotes every selected line across paragraphs',
        text:
            'The meeting starts at 10 AM.\nPlease join five minutes early.\n\n'
            'Bring your project updates.\nWe will review them together.',
        selection: null,
        expected:
            '> The meeting starts at 10 AM.\n> Please join five minutes early.\n> \n'
            '> Bring your project updates.\n> We will review them together.',
        cursor: null,
      ),
      (
        name: 'preserves text outside a reversed multiline selection',
        text: 'Before\nfirst\n\nlast\nAfter',
        selection: TextSelection(baseOffset: 18, extentOffset: 7),
        expected: 'Before\n> first\n> \n> last\nAfter',
        cursor: 24,
      ),
      (
        name: 'preserves text outside a selection within lines',
        text: 'before first\nlast after',
        selection: TextSelection(baseOffset: 7, extentOffset: 17),
        expected: 'before > first\n> last after',
        cursor: 21,
      ),
      (
        name:
            'does not quote the next line when the selection ends in a newline',
        text: 'first\nsecond\nthird',
        selection: TextSelection(baseOffset: 0, extentOffset: 13),
        expected: '> first\n> second\nthird',
        cursor: 17,
      ),
      (
        name: 'quotes one selected line that ends in a newline',
        text: 'one\ntwo',
        selection: TextSelection(baseOffset: 0, extentOffset: 4),
        expected: '> one\ntwo',
        cursor: 6,
      ),
      (
        name: 'continues to quote a single line',
        text: 'hello',
        selection: null,
        expected: '> hello',
        cursor: null,
      ),
      (
        name: 'inserts a quote prefix at the cursor without selecting text',
        text: 'before after',
        selection: TextSelection.collapsed(offset: 7),
        expected: 'before > after',
        cursor: 9,
      ),
      (
        name: 'inserts a quote prefix into an empty composer',
        text: '',
        selection: null,
        expected: '> ',
        cursor: null,
      ),
    ];

    for (final example in cases) {
      testWidgets(example.name, (tester) async {
        await tester.pumpWidget(buildComposerUnderTest());
        await typeAndSelect(tester, example.text, selection: example.selection);

        await tester.tap(find.byTooltip('Block quote'));
        await tester.pump();

        final controller = composerController(tester);
        expect(controller.text, example.expected);
        expect(
          controller.selection,
          TextSelection.collapsed(
            offset: example.cursor ?? example.expected.length,
          ),
        );
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .focusNode
              .hasFocus,
          isTrue,
        );
      });
    }
  });
}
