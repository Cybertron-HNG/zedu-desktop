import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

Widget buildComposerUnderTest() {
  return ProviderScope(
    child: buildTestMaterialApp(
      Scaffold(
        body: DmMessageComposer(
          recipientName: 'Ada',
          channelId: 'channel-1',
          participants: [
            DmParticipant(
              userId: 'user-1',
              username: 'ada_test',
              email: 'ada@example.com',
            ),
          ],
        ),
      ),
    ),
  );
}

TextEditingController composerController(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).controller;

void main() {
  group('DmMessageComposer Enter with the @mention list open', () {
    testWidgets('inserts the suggested mention instead of sending', (
      tester,
    ) async {
      await tester.pumpWidget(buildComposerUnderTest());
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'hi @ad');
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(composerController(tester).text, 'hi @ada_test ');
    });
  });
}
