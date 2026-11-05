import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

final filesRemoteDataSourceProvider = Provider<FilesRemoteDataSource>(
  (ref) => FilesRemoteDataSourceImpl(apiBaseService: locator<ApiBaseService>()),
);

final filesRepositoryProvider = Provider<FilesRepository>(
  (ref) => FilesRepositoryImpl(
    remoteDataSource: ref.watch(filesRemoteDataSourceProvider),
  ),
);

final filesProvider = NotifierProvider<FilesNotifier, FilesState>(
  FilesNotifier.new,
);

final filesListProvider = AsyncNotifierProvider<FilesListNotifier, FilesPage>(
  FilesListNotifier.new,
);

final foldersListProvider =
    AsyncNotifierProvider<FoldersListNotifier, FoldersPage>(
      FoldersListNotifier.new,
    );

final filesActionsProvider =
    NotifierProvider<FilesActionsNotifier, FilesActionsState>(
      FilesActionsNotifier.new,
    );

final saveLocationPickerProvider = Provider<SaveLocationPicker>(
  (ref) =>
      (fileName) => FilePicker.saveFile(
        dialogTitle: 'Save file',
        fileName: fileName,
        lockParentWindow: true,
      ),
);

final fileDownloadsProvider =
    NotifierProvider<FileDownloadsNotifier, Map<String, double?>>(
      FileDownloadsNotifier.new,
    );

final fileDeletionsProvider =
    NotifierProvider<FileDeletionsNotifier, Set<String>>(
      FileDeletionsNotifier.new,
    );

final fileRenamesProvider = NotifierProvider<FileRenamesNotifier, Set<String>>(
  FileRenamesNotifier.new,
);

final fileMovesProvider = NotifierProvider<FileMovesNotifier, Set<String>>(
  FileMovesNotifier.new,
);

/// The folders a file can be moved into: the top-level folders of all files,
/// across every page.
final moveTargetFoldersProvider = FutureProvider.autoDispose<List<FileFolder>>((
  ref,
) async {
  final repository = ref.watch(filesRepositoryProvider);
  final folders = <FileFolder>[];
  for (var page = 1; ; page++) {
    final result = await repository.fetchFolders(
      view: FilesScope.all,
      page: page,
    );
    final value = switch (result) {
      Success(:final value) => value,
      Failure(:final error) => throw error,
    };
    folders.addAll(value.folders);
    if (value.folders.isEmpty || page >= value.totalPages) return folders;
  }
});

final fileSharesProvider = NotifierProvider<FileSharesNotifier, Set<String>>(
  FileSharesNotifier.new,
);

final pinnedFilesProvider =
    AsyncNotifierProvider<PinnedFilesNotifier, Set<String>>(
      PinnedFilesNotifier.new,
    );

/// A file's current details from the server, for its Info panel.
final fileDetailsProvider = FutureProvider.autoDispose
    .family<WorkspaceFile, String>((ref, fileId) async {
      final result = await ref
          .watch(filesRepositoryProvider)
          .fetchFileDetails(fileId);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw error,
      };
    });

/// Where a file was shared, from the server's file info. The files list
/// doesn't say, so the Shared in column and the Info panel ask for it. A
/// failure shows a dash and is not retried, so a page of rows can't keep
/// asking.
final fileSharedInProvider = FutureProvider.autoDispose.family<String, String>((
  ref,
  fileId,
) async {
  final result = await ref
      .watch(filesRepositoryProvider)
      .fetchFileSharedIn(fileId);
  return switch (result) {
    Success(:final value) => value,
    Failure(:final error) => throw error,
  };
}, retry: (_, _) => null);
