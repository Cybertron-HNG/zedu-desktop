import '../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

// Avoids the network call the real ChannelNotifier starts in build().
class FakeChannelNotifier extends ChannelNotifier {
  @override
  Future<List<Channel>> build() async => const [];
}

Channel _channel() => Channel(
  id: 'c1',
  name: 'general',
  description: 'All team members',
  organisationId: 'org-1',
  ownerId: 'u1',
  topic: 'Company news',
);

Widget _app(Channel? channel) {
  return ProviderScope(
    overrides: [channelProvider.overrideWith(FakeChannelNotifier.new)],
    child: MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topRight,
          child: ChannelOptionsMenu(channel: channel),
        ),
      ),
    ),
  );
}

void main() {
  group('ChannelOptionsMenu', () {
    testWidgets('Edit channel opens the edit dialog for the channel', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_channel()));

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text('Edit channel'), findsOneWidget);

      await tester.tap(find.text('Edit channel'));
      await tester.pumpAndSettle();

      expect(find.byType(EditChannelModal), findsOneWidget);
      expect(find.text('Edit #general'), findsOneWidget);
      // The form starts with the channel's current topic and description.
      expect(find.text('Company news'), findsOneWidget);
      expect(find.text('All team members'), findsOneWidget);
    });

    testWidgets('is disabled until the channel has loaded', (tester) async {
      await tester.pumpWidget(_app(null));

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Edit channel'), findsNothing);
      expect(find.byType(EditChannelModal), findsNothing);
    });
  });
}
