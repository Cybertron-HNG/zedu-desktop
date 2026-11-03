import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class _FakeWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState(
    selectedWorkspace: Workspace(id: 'org-1', name: 'Workspace A', avatar: ''),
  );
}

class _FakeProfileNotifier extends UserProfileNotifier {
  @override
  UserProfileState build() => const UserProfileState(
    teamMembers: [
      TeamMember(
        id: 'u-1',
        email: 'ada@zedu.test',
        role: 'Admin',
        dateJoined: '2026-01-01',
        status: TeamMemberStatus.active,
        name: 'Ada Lovelace',
      ),
    ],
  );

  @override
  Future<void> load() async {}
}

class _FakeFilesRepository implements FilesRepository {
  _FakeFilesRepository({this.failFolders = false});

  final bool failFolders;
  final queries = <FilesQuery>[];
  final folderRequests = <(FilesScope, String?)>[];

  @override
  Future<Result<FilesPage>> fetchFiles(FilesQuery query) async {
    queries.add(query);
    if (query.folderId == 'docs') {
      return const Success(
        FilesPage(
          files: [WorkspaceFile(id: 'f-2', name: 'spec.pdf')],
        ),
      );
    }
    return Success(
      FilesPage(
        files: [
          WorkspaceFile(
            id: 'f-1',
            name: 'logo.png',
            fileType: 'png',
            size: 2048,
            userId: 'u-1',
            sharedIn: 'general',
            updatedAt: DateTime(2026, 11, 1),
          ),
        ],
      ),
    );
  }

  @override
  Future<Result<List<FileFolder>>> fetchFolders({
    required FilesScope view,
    String? parentId,
  }) async {
    folderRequests.add((view, parentId));
    if (failFolders) {
      return const Failure(ApiFailure(message: 'offline'));
    }
    if (parentId != null) return const Success([]);
    return Success([
      FileFolder(
        id: 'docs',
        name: 'docs',
        userId: 'u-1',
        itemCount: 1,
        createdAt: DateTime(2026, 11, 1),
      ),
    ]);
  }
}

Future<void> _pump(WidgetTester tester, _FakeFilesRepository repository) async {
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        workspaceProvider.overrideWith(_FakeWorkspaceNotifier.new),
        userProfileNotifierProvider.overrideWith(_FakeProfileNotifier.new),
        filesRepositoryProvider.overrideWithValue(repository),
      ],
      child: buildTestMaterialApp(
        const Scaffold(
          body: Row(
            children: [
              FilesSidebar(),
              Expanded(child: FilesView()),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens on All files with the folders listed', (tester) async {
    final repository = _FakeFilesRepository();
    await _pump(tester, repository);

    for (final label in [
      'All files',
      'My files',
      'Shared with me',
      'Deleted files',
    ]) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.text('Channels'), findsNothing);
    expect(find.text('docs'), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('Nov 1, 2026'), findsOneWidget);
    expect(find.text('1 item'), findsOneWidget);
    expect(repository.folderRequests.last, (FilesScope.all, null));
  });

  testWidgets('the Files tab lists files with their details', (tester) async {
    await _pump(tester, _FakeFilesRepository());

    await tester.tap(find.text('Files').last);
    await tester.pumpAndSettle();

    expect(find.text('logo.png'), findsOneWidget);
    expect(find.text('general'), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('2 KB'), findsOneWidget);
  });

  testWidgets('a sidebar list loads that list', (tester) async {
    final repository = _FakeFilesRepository();
    await _pump(tester, repository);

    await tester.tap(find.text('Deleted files'));
    await tester.pumpAndSettle();

    expect(repository.folderRequests.last, (FilesScope.trash, null));
    // The title follows the list.
    expect(find.text('Deleted files'), findsNWidgets(2));
  });

  testWidgets('opening a folder shows its files and a way back', (
    tester,
  ) async {
    final repository = _FakeFilesRepository();
    await _pump(tester, repository);

    await tester.tap(find.text('docs'));
    await tester.pumpAndSettle();

    expect(repository.queries.last.folderId, 'docs');
    expect(find.text('spec.pdf'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'All files'));
    await tester.pumpAndSettle();

    expect(repository.queries.last.folderId, isNull);
  });

  testWidgets('choosing a file type filters on the server', (tester) async {
    final repository = _FakeFilesRepository();
    await _pump(tester, repository);

    await tester.tap(find.text('File Type'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Images').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Files').last);
    await tester.pumpAndSettle();

    expect(repository.queries.last.category, FileCategory.images);
  });

  testWidgets('shows a retry when folders fail to load', (tester) async {
    await _pump(tester, _FakeFilesRepository(failFolders: true));

    expect(find.text('Could not load folders'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
