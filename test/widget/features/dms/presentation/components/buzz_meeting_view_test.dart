import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

class FakeActiveCallNotifier extends ActiveCallNotifier {
  FakeActiveCallNotifier(super.ref, {required bool isFullPage})
    : _fakeState = ActiveCallState(
        status: CallStatus.active,
        remoteUserName: 'Ruby',
        isFullPage: isFullPage,
      );

  final ActiveCallState _fakeState;

  @override
  ActiveCallState get state => _fakeState;
}

/// Records what the call buttons ask the engine to do.
class FakeBuzzEngine implements BuzzEngineService {
  final mic = <bool>[];
  final video = <bool>[];
  bool fail = false;

  @override
  Future<void> toggleMic(bool mute) async {
    if (fail) throw Exception('engine not ready');
    mic.add(mute);
  }

  @override
  Future<void> toggleVideo(bool mute) async {
    if (fail) throw Exception('engine not ready');
    video.add(mute);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget buildBuzzMeetingViewUnderTest({
  required bool isFullPage,
  FakeBuzzEngine? engine,
}) {
  return ProviderScope(
    overrides: [
      activeCallProvider.overrideWith(
        (ref) => FakeActiveCallNotifier(ref, isFullPage: isFullPage),
      ),
      buzzEngineProvider.overrideWithValue(engine ?? FakeBuzzEngine()),
    ],
    // The compact view is a Positioned, so it needs a Stack ancestor.
    child: MaterialApp(
      home: Scaffold(body: Stack(children: const [BuzzMeetingView()])),
    ),
  );
}

void main() {
  group('BuzzMeetingView participant label', () {
    testWidgets('compact view shows "2 participants"', (tester) async {
      await tester.pumpWidget(buildBuzzMeetingViewUnderTest(isFullPage: false));
      await tester.pump();

      expect(find.text('2 participants'), findsOneWidget);
      expect(find.text('2 participant'), findsNothing);
    });

    testWidgets('full-page view shows "2 participants"', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildBuzzMeetingViewUnderTest(isFullPage: true));
      await tester.pump();

      expect(find.text('2 participants'), findsOneWidget);
      expect(find.text('2 participant'), findsNothing);
    });
  });

  group('BuzzMeetingView share screen button', () {
    testWidgets('tells the user screen sharing is not available yet', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildBuzzMeetingViewUnderTest(isFullPage: true));
      await tester.pump();

      const message = 'Screen sharing is not available yet.';
      expect(find.text(message), findsNothing);

      await tester.tap(find.byIcon(Icons.screen_share_outlined));
      await tester.pump();

      expect(find.text(message), findsOneWidget);

      // Let the toast's auto-dismiss timer finish.
      await tester.pump(const Duration(seconds: 10));
    });
  });

  group('BuzzMeetingView mute and camera (#2935)', () {
    for (final isFullPage in [true, false]) {
      final view = isFullPage ? 'full-page' : 'compact';

      testWidgets('$view: mute and unmute reach the call engine', (
        tester,
      ) async {
        final engine = FakeBuzzEngine();
        await tester.pumpWidget(
          buildBuzzMeetingViewUnderTest(isFullPage: isFullPage, engine: engine),
        );

        await tester.tap(find.byTooltip('Mute'));
        await tester.pump();
        expect(engine.mic, [true]);
        expect(find.byTooltip('Unmute'), findsOneWidget);

        await tester.tap(find.byTooltip('Unmute'));
        await tester.pump();
        expect(engine.mic, [true, false]);
        expect(find.byTooltip('Mute'), findsOneWidget);
      });

      testWidgets('$view: the camera button reaches the call engine', (
        tester,
      ) async {
        final engine = FakeBuzzEngine();
        await tester.pumpWidget(
          buildBuzzMeetingViewUnderTest(isFullPage: isFullPage, engine: engine),
        );

        await tester.tap(find.byTooltip('Turn camera off'));
        await tester.pump();
        expect(engine.video, [true]);
        expect(find.byTooltip('Turn camera on'), findsOneWidget);
      });
    }

    testWidgets('a mute the engine refuses leaves the button as it was', (
      tester,
    ) async {
      final engine = FakeBuzzEngine()..fail = true;
      await tester.pumpWidget(
        buildBuzzMeetingViewUnderTest(isFullPage: true, engine: engine),
      );

      await tester.tap(find.byTooltip('Mute'));
      await tester.pump();

      expect(find.byTooltip('Mute'), findsOneWidget);
      expect(find.byTooltip('Unmute'), findsNothing);
      expect(
        find.text("Couldn't change that on the call. Please try again."),
        findsOneWidget,
      );
      // Let the toast's dismiss timer run out.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });
}
