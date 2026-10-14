import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

// Fakes keep HomeView off GetIt/the network: the tests only care about the
// sidebar section headers.
class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}

class _FakeWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState();
}

// The sidebar now lists real channels, so the test supplies one.
class _FakeChannelNotifier extends ChannelNotifier {
  @override
  Future<List<Channel>> build() async => [
    Channel(
      id: 'channel-general',
      name: 'general',
      description: '',
      organisationId: 'org-1',
      ownerId: 'user-1',
    ),
  ];
}

class _FakeCreditsNotifier extends CreditsNotifier {
  @override
  CreditsState build() => const CreditsState();
}

ProviderContainer _container() => ProviderContainer(
  overrides: [
    authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
    workspaceProvider.overrideWith(_FakeWorkspaceNotifier.new),
    creditsNotifierProvider.overrideWith(_FakeCreditsNotifier.new),
    channelProvider.overrideWith(_FakeChannelNotifier.new),
  ],
);

Widget _app(ProviderContainer container, {Widget home = const HomeView()}) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: home),
    );

Future<void> _pumpHome(WidgetTester tester, ProviderContainer container) async {
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(container));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

// The icon rail also has a "People" label, so scope finders to the header.
Finder _header(String label) =>
    find.widgetWithText(SidebarSectionHeader, label);

double _turnsOf(WidgetTester tester, String label) => tester
    .widget<AnimatedRotation>(
      find.descendant(
        of: _header(label),
        matching: find.byType(AnimatedRotation),
      ),
    )
    .turns;

void main() {
  late ProviderContainer container;

  setUp(() {
    container = _container();
    addTearDown(container.dispose);
  });

  testWidgets('both sections start expanded with matching arrows', (
    tester,
  ) async {
    await _pumpHome(tester, container);

    expect(find.text('general'), findsOneWidget);
    expect(find.text('View all channels'), findsOneWidget);
    expect(_turnsOf(tester, 'Channels'), 0.0);
    expect(_turnsOf(tester, 'People'), 0.0);
  });

  testWidgets('tapping Channels collapses and re-expands its content', (
    tester,
  ) async {
    await _pumpHome(tester, container);

    await tester.tap(_header('Channels'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('general'), findsNothing);
    expect(find.text('View all channels'), findsNothing);
    expect(find.text('Add channel'), findsNothing);
    expect(_turnsOf(tester, 'Channels'), -0.25);

    await tester.tap(_header('Channels'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('general'), findsOneWidget);
    expect(find.text('View all channels'), findsOneWidget);
    expect(_turnsOf(tester, 'Channels'), 0.0);
  });

  testWidgets('tapping People rotates only its arrow', (tester) async {
    await _pumpHome(tester, container);

    await tester.tap(_header('People'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(_turnsOf(tester, 'People'), -0.25);
    expect(_turnsOf(tester, 'Channels'), 0.0);
    expect(find.text('general'), findsOneWidget);
  });

  testWidgets('collapsed state survives the sidebar being rebuilt', (
    tester,
  ) async {
    await _pumpHome(tester, container);
    await tester.tap(_header('Channels'));
    await tester.pump(const Duration(milliseconds: 300));

    // Simulates switching rail tabs: the sidebar is disposed then recreated.
    await tester.pumpWidget(_app(container, home: const SizedBox()));
    await tester.pumpWidget(_app(container));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('general'), findsNothing);
    expect(_turnsOf(tester, 'Channels'), -0.25);
  });
}
