import 'dart:async';
import 'dart:io';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

const _docs = FileFolder(id: 'docs', name: 'docs');
const _drafts = FileFolder(id: 'drafts', name: 'drafts');

/// A file in the temp folder. On desktop XFile takes its name from the
/// path, split on the platform's separator, so the path must use it.
XFile _file(String name) =>
    XFile('${Directory.systemTemp.path}${Platform.pathSeparator}$name');

/// The open workspace, switchable mid-test.
class _Org extends Notifier<String> {
  @override
  String build() => 'org-a';

  void select(String id) => state = id;
}

final _orgProvider = NotifierProvider<_Org, String>(_Org.new);

/// Creates folders when [done] completes.
class _SlowFolderRepository extends _UploadRepository {
  final done = Completer<Result<void>>();

  @override
  Future<Result<void>> createFolder({
    required String name,
    required String orgId,
    String? parentId,
  }) => done.future;
}

void main() {
  late ProviderContainer container;
  FilesNotifier notifier() => container.read(filesProvider.notifier);
  FilesState state() => container.read(filesProvider);

  setUp(() {
    container = ProviderContainer(
      overrides: [currentOrgIdProvider.overrideWithValue('org-1')],
    );
    addTearDown(container.dispose);
  });

  test('opening a folder shows its files from the first page', () {
    notifier().setPage(3);
    notifier().openFolder(_docs);

    expect(state().folderId, 'docs');
    expect(state().tab, FilesTab.files);
    expect(state().page, 1);
  });

  test('going back to a level drops the folders below it', () {
    notifier()
      ..openFolder(_docs)
      ..openFolder(_drafts);

    notifier().goToDepth(1);
    expect(state().folderPath, [_docs]);

    notifier().goToDepth(0);
    expect(state().folderId, isNull);
  });

  test('picking a sidebar list leaves the open folder', () {
    notifier().openFolder(_docs);
    notifier().selectView(FilesScope.trash);

    expect(state().view, FilesScope.trash);
    expect(state().folderPath, isEmpty);
  });

  test('filters go back to the first page and can be cleared', () {
    notifier().setPage(2);
    notifier().setCategory(FileCategory.images);
    expect(state().page, 1);
    expect(state().query.category, FileCategory.images);

    notifier().setCategory(null);
    expect(state().category, isNull);

    notifier().setDateModified(DateModifiedFilter.thisYear);
    notifier().setSearch('logo');
    expect(state().query.dateModified, DateModifiedFilter.thisYear);
    expect(state().query.search, 'logo');
  });

  test('sorting does not change the query sent to the server', () {
    final before = state().query;
    notifier().setSort(FilesSort.oldestFirst);

    expect(state().sort, FilesSort.oldestFirst);
    expect(state().query, before);
  });

  group('uploadFiles', () {
    late ProviderContainer uploads;
    late _UploadRepository repository;

    setUp(() {
      repository = _UploadRepository();
      uploads = ProviderContainer(
        overrides: [
          currentOrgIdProvider.overrideWithValue('org-1'),
          filesRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(uploads.dispose);
    });

    test('uploads each file and reports the failures', () async {
      final outcome = await uploads
          .read(filesActionsProvider.notifier)
          .uploadFiles([_file('a.png'), _file('bad.pdf'), _file('c.txt')]);

      expect(repository.uploaded, ['a.png', 'bad.pdf', 'c.txt']);
      expect(outcome.uploaded, 2);
      expect(outcome.failedNames, ['bad.pdf']);
      expect(uploads.read(filesActionsProvider).isUploading, isFalse);
    });

    test('shows the top-level Files tab afterwards', () async {
      uploads.read(filesProvider.notifier)
        ..selectView(FilesScope.trash)
        ..openFolder(_docs)
        ..setTab(FilesTab.folders);

      await uploads.read(filesActionsProvider.notifier).uploadFiles([
        _file('a.png'),
      ]);

      final state = uploads.read(filesProvider);
      expect(state.view, FilesScope.all);
      expect(state.folderPath, isEmpty);
      expect(state.tab, FilesTab.files);
    });

    test('an upload from Shared with me shows it in All files', () async {
      uploads.read(filesProvider.notifier).selectView(FilesScope.shared);

      await uploads.read(filesActionsProvider.notifier).uploadFiles([
        _file('a.png'),
      ]);

      expect(uploads.read(filesProvider).view, FilesScope.all);
    });

    test('an upload from My files stays in My files', () async {
      uploads.read(filesProvider.notifier).selectView(FilesScope.mine);

      await uploads.read(filesActionsProvider.notifier).uploadFiles([
        _file('a.png'),
      ]);

      expect(uploads.read(filesProvider).view, FilesScope.mine);
    });
  });

  group('createFolder', () {
    late ProviderContainer container;
    late _SlowFolderRepository repository;

    setUp(() {
      repository = _SlowFolderRepository();
      container = ProviderContainer(
        overrides: [
          currentOrgIdProvider.overrideWith((ref) => ref.watch(_orgProvider)),
          filesRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      container.read(filesProvider.notifier).setTab(FilesTab.files);
    });

    test(
      'a result that lands after a workspace switch changes nothing',
      () async {
        final pending = container
            .read(filesActionsProvider.notifier)
            .createFolder('Plans');
        expect(container.read(filesActionsProvider).isCreatingFolder, isTrue);

        container.read(_orgProvider.notifier).select('org-b');
        container.read(filesProvider.notifier).setTab(FilesTab.files);
        repository.done.complete(const Success(null));

        expect(await pending, isNull);
        expect(container.read(filesProvider).tab, FilesTab.files);
        expect(container.read(filesActionsProvider).isCreatingFolder, isFalse);
      },
    );

    test('a result in the same workspace shows the folders', () async {
      final pending = container
          .read(filesActionsProvider.notifier)
          .createFolder('Plans');
      repository.done.complete(const Success(null));

      expect(await pending, isNull);
      expect(container.read(filesProvider).tab, FilesTab.folders);
    });

    test(
      'a folder created from a later page goes back to page 1, where it is',
      () async {
        container.read(filesProvider.notifier)
          ..setTab(FilesTab.folders)
          ..setFolderPage(3);

        final pending = container
            .read(filesActionsProvider.notifier)
            .createFolder('Plans');
        repository.done.complete(const Success(null));

        expect(await pending, isNull);
        expect(container.read(filesProvider).folderPage, 1);
      },
    );

    test('a failed create leaves the folders page alone', () async {
      container.read(filesProvider.notifier)
        ..setTab(FilesTab.folders)
        ..setFolderPage(3);

      final pending = container
          .read(filesActionsProvider.notifier)
          .createFolder('Plans');
      repository.done.complete(
        const Failure(ApiFailure(message: 'Folder name already exists')),
      );

      expect(await pending, 'Folder name already exists');
      expect(container.read(filesProvider).folderPage, 3);
    });
  });
}

class _UploadRepository implements FilesRepository {
  final uploaded = <String>[];

  @override
  Future<Result<WorkspaceFile>> uploadFile(XFile file) async {
    uploaded.add(file.name);
    return file.name.startsWith('bad')
        ? const Failure(ApiFailure(message: 'too large'))
        : Success(WorkspaceFile(id: file.name, name: file.name));
  }

  @override
  Future<Result<FilesPage>> fetchFiles(FilesQuery query) async =>
      const Success(FilesPage(files: []));

  @override
  Future<Result<FoldersPage>> fetchFolders({
    required FilesScope view,
    String? parentId,
    int page = 1,
  }) async => const Success(FoldersPage(folders: []));

  @override
  Future<Result<void>> createFolder({
    required String name,
    required String orgId,
    String? parentId,
  }) async => const Success(null);
}
