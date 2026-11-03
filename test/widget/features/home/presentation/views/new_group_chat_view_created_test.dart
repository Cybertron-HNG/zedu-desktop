import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class _MockWebsocket extends Mock implements ChatWebsocketService {}

class _MockRepository extends Mock implements GroupDmRepository {}

const _ada = TeamMember(
  id: 'u-1',
  email: 'ada@zedu.test',
  role: 'Member',
  dateJoined: '2026-01-01',
  status: TeamMemberStatus.active,
  name: 'Ada Lovelace',
);

const _bola = TeamMember(
  id: 'u-2',
  email: 'bola@zedu.test',
  role: 'Member',
  dateJoined: '2026-01-01',
  status: TeamMemberStatus.active,
  name: 'Bola Ade',
);

class _FakeProfileNotifier extends UserProfileNotifier {
  @override
  UserProfileState build() =>
      const UserProfileState(teamMembers: [_ada, _bola]);

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
  late _MockRepository repository;

  setUp(() {
    repository = _MockRepository();
    when(
      () => repository.list(
        orgId: any(named: 'orgId'),
        currentUserId: any(named: 'currentUserId'),
      ),
    ).thenAnswer((_) async => []);
  });

  Future<void> pumpView(WidgetTester tester) async {
    final websocket = _MockWebsocket();
    when(() => websocket.messageStream).thenAnswer((_) => const Stream.empty());
    when(() => websocket.connect(any())).thenReturn(null);
    await tester.binding.setSurfaceSize(const Size(1100, 700));
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

  Future<void> pickBothAndCreate(WidgetTester tester) async {
    for (final name in ['Ada Lovelace', 'Bola Ade']) {
      await tester.tap(find.byType(TextField).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(name).last);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
  }

  testWidgets('a new group says it was created, not that it already existed', (
    tester,
  ) async {
    when(
      () => repository.create(
        orgId: any(named: 'orgId'),
        memberIds: any(named: 'memberIds'),
        currentUserId: any(named: 'currentUserId'),
      ),
    ).thenAnswer(
      (_) async => const GroupDM(
        id: 'c-1',
        name: 'Ada Lovelace, Bola Ade',
        members: [_ada, _bola],
      ),
    );
    await pumpView(tester);

    await pickBothAndCreate(tester);

    expect(
      find.text('Group DM "Ada Lovelace, Bola Ade" created successfully!'),
      findsOneWidget,
    );
    expect(find.textContaining('Opening existing conversation'), findsNothing);
    // Let the snackbar time out so no timer is left running.
    await tester.pump(const Duration(seconds: 5));
    verify(
      () => repository.create(
        orgId: 'org-1',
        memberIds: ['u-1', 'u-2'],
        currentUserId: 'me',
      ),
    ).called(1);
  });

  testWidgets('a failed create shows the server error', (tester) async {
    when(
      () => repository.create(
        orgId: any(named: 'orgId'),
        memberIds: any(named: 'memberIds'),
        currentUserId: any(named: 'currentUserId'),
      ),
    ).thenThrow(
      const ApiFailure(
        message: 'participants: must contain at least 2 people',
        kind: ApiFailureKind.client,
      ),
    );
    await pumpView(tester);

    await pickBothAndCreate(tester);

    expect(find.text('Creation Failed'), findsOneWidget);
    expect(
      find.text('participants: must contain at least 2 people'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 5));
  });
}
