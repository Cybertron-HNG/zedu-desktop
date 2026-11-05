import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class _MockWebsocket extends Mock implements ChatWebsocketService {}

class _MockRepository extends Mock implements GroupDmRepository {}

/// Ten teammates: one more than a group DM may hold.
final _members = [
  for (var i = 1; i <= 10; i++)
    TeamMember(
      id: 'u-$i',
      email: 'person$i@zedu.test',
      role: 'Member',
      dateJoined: '2026-01-01',
      status: TeamMemberStatus.active,
      name: 'Person $i',
    ),
];

class _FakeProfileNotifier extends UserProfileNotifier {
  @override
  UserProfileState build() => UserProfileState(teamMembers: _members);

  @override
  Future<void> load() async {}
}

class _FakeWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState(
    selectedWorkspace: Workspace(id: 'org-1', name: 'Workspace A', avatar: ''),
  );
}

void main() {
  Future<void> pumpView(WidgetTester tester) async {
    final repository = _MockRepository();
    when(
      () => repository.list(
        orgId: any(named: 'orgId'),
        currentUserId: any(named: 'currentUserId'),
      ),
    ).thenAnswer((_) async => []);
    final websocket = _MockWebsocket();
    when(() => websocket.messageStream).thenAnswer((_) => const Stream.empty());
    when(() => websocket.connect(any())).thenReturn(null);
    await tester.binding.setSurfaceSize(const Size(1100, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatWebsocketProvider.overrideWithValue(websocket),
          groupDmRepositoryProvider.overrideWithValue(repository),
          groupDmUserIdProvider.overrideWithValue('me'),
          workspaceProvider.overrideWith(_FakeWorkspaceNotifier.new),
          userProfileNotifierProvider.overrideWith(_FakeProfileNotifier.new),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: NewGroupChatView()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pick(WidgetTester tester, String name) async {
    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();
    final suggestion = find.text(name);
    if (suggestion.evaluate().isEmpty) return;
    await tester.tap(suggestion.last);
    await tester.pumpAndSettle();
  }

  testWidgets('a group DM takes at most nine members, as the server allows', (
    tester,
  ) async {
    await pumpView(tester);

    for (var i = 1; i <= 10; i++) {
      await pick(tester, 'Person $i');
    }

    expect(
      find.text('A group DM can have up to 9 members (Selected: 9/9)'),
      findsOneWidget,
    );
  });
}
