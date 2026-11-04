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
  _FakeFilesRepository({
    this.failFolders = false,
    this.link = 'https://files.test/logo.png',
  });

  final bool failFolders;
  final String link;
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
            link: link,
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

Future<void> _pump(
  WidgetTester tester,
  _FakeFilesRepository repository, {
  Future<bool> Function(Uri)? openLink,
}) async {
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
        fileLinkOpenerProvider.overrideWithValue(openLink ?? (_) async => true),
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

  group('opening a file', () {
    Future<void> openLogo(
      WidgetTester tester, {
      String link = 'https://files.test/logo.png',
      required Future<bool> Function(Uri) openLink,
    }) async {
      await _pump(tester, _FakeFilesRepository(link: link), openLink: openLink);
      await tester.tap(find.text('Files').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('logo.png'));
      await tester.pump();
    }

    testWidgets('opens its link without an error', (tester) async {
      final opened = <Uri>[];
      await openLogo(
        tester,
        openLink: (uri) async {
          opened.add(uri);
          return true;
        },
      );

      expect(opened, [Uri.parse('https://files.test/logo.png')]);
      expect(find.text('Could not open logo.png.'), findsNothing);
    });

    testWidgets('says so when the link cannot be opened', (tester) async {
      await openLogo(tester, openLink: (_) async => false);

      expect(find.text('Could not open logo.png.'), findsOneWidget);
    });

    testWidgets('says so when the launcher throws, without the error', (
      tester,
    ) async {
      await openLogo(
        tester,
        openLink: (_) async =>
            throw Exception('PlatformException /private/tmp/secret'),
      );

      expect(find.text('Could not open logo.png.'), findsOneWidget);
      expect(find.textContaining('secret'), findsNothing);
    });

    testWidgets('says so for a file with no link, without launching', (
      tester,
    ) async {
      var launched = false;
      await openLogo(tester, link: '', openLink: (_) async => launched = true);

      expect(launched, isFalse);
      expect(find.text('Could not open logo.png.'), findsOneWidget);
    });
  });
}
