import '../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockChannelRepository extends Mock implements ChannelRepository {}

final _channel = Channel(
  id: 'c1',
  name: 'general',
  description: 'All team members',
  organisationId: 'org-1',
  ownerId: 'u1',
  topic: 'Company news',
);

// Starts with one channel and avoids the network call in the real build().
class FakeChannelNotifier extends ChannelNotifier {
  @override
  Future<List<Channel>> build() async => [_channel];
}

Widget _app(ChannelRepository repository) {
  return ProviderScope(
    overrides: [
      channelProvider.overrideWith(FakeChannelNotifier.new),
      channelRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => EditChannelModal(channel: _channel),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openAndEdit(WidgetTester tester, {String? topic}) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  if (topic != null) {
    await tester.enterText(find.byType(TextField).first, topic);
  }
}

void main() {
  group('EditChannelModal save', () {
    late MockChannelRepository repository;

    setUp(() {
      repository = MockChannelRepository();
    });

    void stubUpdate(Result<void> result) {
      when(
        () => repository.updateChannelTopicOrDescription(
          channelId: any(named: 'channelId'),
          topic: any(named: 'topic'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async => result);
    }

    testWidgets('closes the dialog after a successful save', (tester) async {
      stubUpdate(const Success<void>(null));
      await tester.pumpWidget(_app(repository));
      await _openAndEdit(tester, topic: '  Launch week  ');

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.byType(EditChannelModal), findsNothing);
      verify(
        () => repository.updateChannelTopicOrDescription(
          channelId: 'c1',
          topic: 'Launch week',
          description: 'All team members',
        ),
      ).called(1);
    });

    testWidgets('stays open with the error and the typed text on failure', (
      tester,
    ) async {
      stubUpdate(
        const Failure<void>(
          ApiFailure(
            message: 'You are not allowed to edit this channel.',
            kind: ApiFailureKind.client,
          ),
        ),
      );
      await tester.pumpWidget(_app(repository));
      await _openAndEdit(tester, topic: 'Launch week');

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.byType(EditChannelModal), findsOneWidget);
      expect(
        find.text('You are not allowed to edit this channel.'),
        findsOneWidget,
      );
      expect(find.text('Launch week'), findsOneWidget);
    });

    testWidgets('asks for a topic or description instead of sending none', (
      tester,
    ) async {
      stubUpdate(const Success<void>(null));
      await tester.pumpWidget(_app(repository));
      await _openAndEdit(tester, topic: '');
      await tester.enterText(find.byType(TextField).last, '   ');

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.byType(EditChannelModal), findsOneWidget);
      expect(
        find.text('Add a topic or a description to save.'),
        findsOneWidget,
      );
      verifyNever(
        () => repository.updateChannelTopicOrDescription(
          channelId: any(named: 'channelId'),
          topic: any(named: 'topic'),
          description: any(named: 'description'),
        ),
      );
    });
  });
}
