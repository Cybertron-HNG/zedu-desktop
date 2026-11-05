import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../../helpers/helpers.dart';

void main() {
  const testChannelId = 'test-channel-id';

  testWidgets('renders nothing when no users are typing', (tester) async {
    await tester.pumpWidget(
      buildTestMaterialApp(
        const ProviderScope(
          child: Scaffold(
            body: TypingIndicator(channelId: testChannelId),
          ),
        ),
      ),
    );

    expect(find.byType(TypingIndicator), findsOneWidget);
    expect(find.textContaining('typing'), findsNothing);
  });

  testWidgets('displays typing text when a user is typing', (tester) async {
    late WidgetRef capturedRef;

    await tester.pumpWidget(
      buildTestMaterialApp(
        ProviderScope(
          child: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return const TypingIndicator(channelId: testChannelId);
              },
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('typing'), findsNothing);

    capturedRef.read(typingProvider(testChannelId)).setUserTyping(
      userId: 'user-1',
      username: 'Sarah Connor',
      isTyping: true,
    );

    await tester.pump();

    expect(find.text('Sarah Connor is typing…'), findsOneWidget);
  });

  testWidgets('updates display when multiple users type', (tester) async {
    late WidgetRef capturedRef;

    await tester.pumpWidget(
      buildTestMaterialApp(
        ProviderScope(
          child: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return const TypingIndicator(channelId: testChannelId);
              },
            ),
          ),
        ),
      ),
    );

    final notifier = capturedRef.read(typingProvider(testChannelId));

    notifier.setUserTyping(
      userId: 'user-1',
      username: 'Sarah',
      isTyping: true,
    );
    notifier.setUserTyping(
      userId: 'user-2',
      username: 'John',
      isTyping: true,
    );

    await tester.pump();
    expect(find.text('Sarah and John are typing…'), findsOneWidget);

    notifier.setUserTyping(
      userId: 'user-3',
      username: 'Kyle',
      isTyping: true,
    );

    await tester.pump();
    expect(find.text('Several people are typing…'), findsOneWidget);
  });
}
