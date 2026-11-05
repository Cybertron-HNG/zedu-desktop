import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

void main() {
  testWidgets('displays empty state when no messages are pinned', (tester) async {
    await tester.pumpWidget(
      buildTestMaterialApp(
        const Scaffold(
          body: PinnedMessagesDialog(
            conversationName: 'Team Chat',
            messages: [
              {'content': 'Hello world', 'is_pinned': false},
              {'content': 'Another message'},
            ],
          ),
        ),
      ),
    );

    expect(find.text('Pinned messages'), findsOneWidget);
    expect(find.text('Team Chat'), findsOneWidget);
    expect(find.text('No pinned messages'), findsOneWidget);
    expect(
      find.text('Messages pinned in Team Chat will show up here.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
  });

  testWidgets('displays list of pinned messages', (tester) async {
    final messages = [
      {
        'content': 'First regular message',
        'is_pinned': false,
      },
      {
        'content': '<p>Release v2 scheduled for Friday</p>',
        'is_pinned': true,
        'sender_name': 'Sarah Connor',
        'created_at': '2026-11-05T10:30:00Z',
      },
      {
        'content': 'Dont forget meeting at 2pm',
        'pinned': true,
        'username': 'John Doe',
      },
    ];

    await tester.pumpWidget(
      buildTestMaterialApp(
        Scaffold(
          body: PinnedMessagesDialog(
            conversationName: 'Project X',
            messages: messages,
          ),
        ),
      ),
    );

    expect(find.text('Pinned messages'), findsOneWidget);
    expect(find.text('No pinned messages'), findsNothing);

    // Verify first pinned message
    expect(find.text('Sarah Connor'), findsOneWidget);
    expect(find.text('Release v2 scheduled for Friday'), findsOneWidget);

    // Verify second pinned message
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Dont forget meeting at 2pm'), findsOneWidget);

    // Unpinned message not shown
    expect(find.text('First regular message'), findsNothing);
  });

  testWidgets('close button dismisses dialog', (tester) async {
    await tester.pumpWidget(
      buildTestMaterialApp(
        Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const PinnedMessagesDialog(
                  conversationName: 'General',
                  messages: [],
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(PinnedMessagesDialog), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.byType(PinnedMessagesDialog), findsNothing);
  });
}
