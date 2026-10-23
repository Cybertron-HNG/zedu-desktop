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

Widget buildBuzzMeetingViewUnderTest({required bool isFullPage}) {
  return ProviderScope(
    overrides: [
      activeCallProvider.overrideWith(
        (ref) => FakeActiveCallNotifier(ref, isFullPage: isFullPage),
      ),
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

  group('BuzzMeetingView control tooltips', () {
    testWidgets('compact view labels every control', (tester) async {
      await tester.pumpWidget(buildBuzzMeetingViewUnderTest(isFullPage: false));
      await tester.pump();

      for (final label in [
        'Open full page',
        'Mute',
        'Turn camera off',
        'Raise hand',
        'Leave call',
      ]) {
        expect(find.byTooltip(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('full-page view labels every control', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildBuzzMeetingViewUnderTest(isFullPage: true));
      await tester.pump();

      for (final label in [
        'Mute',
        'Share screen',
        'Turn camera off',
        'Raise hand',
        'Leave call',
      ]) {
        expect(find.byTooltip(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('mute, camera and hand tooltips follow the button state', (
      tester,
    ) async {
      await tester.pumpWidget(buildBuzzMeetingViewUnderTest(isFullPage: false));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.mic));
      await tester.tap(find.byIcon(Icons.videocam));
      await tester.tap(find.byIcon(Icons.back_hand));
      await tester.pump();

      expect(find.byTooltip('Unmute'), findsOneWidget);
      expect(find.byTooltip('Turn camera on'), findsOneWidget);
      expect(find.byTooltip('Lower hand'), findsOneWidget);
      expect(find.byTooltip('Mute'), findsNothing);
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
}
