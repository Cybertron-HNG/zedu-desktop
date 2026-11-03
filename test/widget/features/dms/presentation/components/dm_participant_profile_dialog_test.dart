import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

DmConversation _conversation({
  String username = 'Ada Lovelace',
  String? email = 'ada@example.com',
}) => DmConversation(
  channelId: 'ch-1',
  username: username,
  participantId: '0193a2b4-internal-id',
  participantEmail: email,
  previewMessage: '',
  unreadCount: 0,
);

Future<void> _pump(WidgetTester tester, DmConversation conversation) =>
    tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: DmParticipantProfileDialog(conversation: conversation),
        ),
      ),
    );

void main() {
  testWidgets('shows the name, email and initial, never the internal id', (
    tester,
  ) async {
    await _pump(tester, _conversation());

    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('ada@example.com'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.textContaining('0193a2b4'), findsNothing);
    expect(find.textContaining('User ID'), findsNothing);
  });

  testWidgets('leaves the email out when there is none', (tester) async {
    await _pump(tester, _conversation(email: null));

    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.byType(SelectableText), findsNothing);
  });

  testWidgets('keeps an emoji initial whole', (tester) async {
    await _pump(tester, _conversation(username: '🚀 Rocket Team'));

    expect(find.text('🚀'), findsOneWidget);
  });

  testWidgets('Close dismisses the dialog', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) =>
                    DmParticipantProfileDialog(conversation: _conversation()),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(DmParticipantProfileDialog), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(DmParticipantProfileDialog), findsNothing);
  });
}
