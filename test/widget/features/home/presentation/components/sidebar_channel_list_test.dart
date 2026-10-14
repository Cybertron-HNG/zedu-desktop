import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

Channel _channel(String name, {bool archived = false}) => Channel(
  id: 'channel-$name',
  name: name,
  description: '',
  organisationId: 'org-1',
  ownerId: 'user-1',
  archived: archived,
);

class FakeChannelNotifier extends ChannelNotifier {
  @override
  ChannelState build() => ChannelState(
    channels: [
      _channel('general'),
      _channel('random'),
      _channel('old', archived: true),
    ],
  );
}

void main() {
  group('SidebarChannelList', () {
    late ProviderContainer container;

    Future<void> pumpList(WidgetTester tester) async {
      container = ProviderContainer(
        overrides: [channelProvider.overrideWith(FakeChannelNotifier.new)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: buildTestMaterialApp(
            const Scaffold(body: SidebarChannelList()),
          ),
        ),
      );
    }

    testWidgets('lists the active channels and hides archived ones', (
      tester,
    ) async {
      await pumpList(tester);

      expect(find.text('general'), findsOneWidget);
      expect(find.text('random'), findsOneWidget);
      expect(find.text('old'), findsNothing);
    });

    testWidgets('tapping a channel opens it', (tester) async {
      await pumpList(tester);
      expect(container.read(activeChatProvider).id, 'general');

      await tester.tap(find.text('random'));
      await tester.pump();

      expect(
        container.read(activeChatProvider),
        const ActiveChatState(type: ActiveChatType.channel, id: 'random'),
      );
    });
  });
}
