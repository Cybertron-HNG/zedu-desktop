import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class FilesNotifier extends Notifier<FilesState> {
  @override
  FilesState build() {
    // Folders belong to one workspace, so start over when it changes.
    ref.watch(currentOrgIdProvider);
    return const FilesState();
  }

  FilesState _with({
    FilesScope? view,
    List<FileFolder>? folderPath,
    FileCategory? Function()? category,
    DateModifiedFilter? Function()? dateModified,
    String? search,
    FilesSort? sort,
    FilesTab? tab,
    int? page,
    int? folderPage,
  }) => FilesState(
    view: view ?? state.view,
    folderPath: folderPath ?? state.folderPath,
    category: category != null ? category() : state.category,
    dateModified: dateModified != null ? dateModified() : state.dateModified,
    search: search ?? state.search,
    sort: sort ?? state.sort,
    tab: tab ?? state.tab,
    page: page ?? state.page,
    folderPage: folderPage ?? state.folderPage,
  );

  /// Opens one of the sidebar lists at its top level.
  void selectView(FilesScope view) {
    state = _with(view: view, folderPath: const [], page: 1, folderPage: 1);
  }

  /// Opens the Deleted files (Trash) view directly on the Files tab.
  void openTrash() {
    state = _with(
      view: FilesScope.trash,
      folderPath: const [],
      tab: FilesTab.files,
      page: 1,
      folderPage: 1,
    );
  }

  /// Opens [folder] inside the current one and shows its files.
  void openFolder(FileFolder folder) {
    state = _with(
      folderPath: [...state.folderPath, folder],
      tab: FilesTab.files,
      page: 1,
      folderPage: 1,
    );
  }

  /// Goes back to the folder at [depth] in the path; 0 is the top level.
  void goToDepth(int depth) {
    if (depth >= state.folderPath.length) return;
    state = _with(
      folderPath: state.folderPath.sublist(0, depth),
      page: 1,
      folderPage: 1,
    );
  }

  void setCategory(FileCategory? category) {
    state = _with(category: () => category, page: 1);
  }

  void setDateModified(DateModifiedFilter? filter) {
    state = _with(dateModified: () => filter, page: 1);
  }

  void setSearch(String search) {
    if (search.trim() == state.search.trim()) return;
    state = _with(search: search, page: 1);
  }

  void setSort(FilesSort sort) => state = _with(sort: sort);

  void setTab(FilesTab tab) => state = _with(tab: tab);

  void setPage(int page) {
    if (page < 1) return;
    state = _with(page: page);
  }

  void setFolderPage(int page) {
    if (page < 1) return;
    state = _with(folderPage: page);
  }
}

/// The current page of files for the Files page's query.
class FilesListNotifier extends AsyncNotifier<FilesPage> {
  @override
  Future<FilesPage> build() async {
    final query = ref.watch(filesProvider.select((s) => s.query));
    final result = await ref.read(filesRepositoryProvider).fetchFiles(query);
    return switch (result) {
      Success<FilesPage>(:final value) => value,
      Failure<FilesPage>(:final error) => throw error,
    };
  }
}

/// The current page of folders in the open list and folder.
class FoldersListNotifier extends AsyncNotifier<FoldersPage> {
  @override
  Future<FoldersPage> build() async {
    final (view, parentId, page) = ref.watch(
      filesProvider.select((s) => (s.view, s.folderId, s.folderPage)),
    );
    final result = await ref
        .read(filesRepositoryProvider)
        .fetchFolders(view: view, parentId: parentId, page: page);
    return switch (result) {
      Success<FoldersPage>(:final value) => value,
      Failure<FoldersPage>(:final error) => throw error,
    };
  }
}

/// What an Upload File run did.
class FilesUploadOutcome {
  final int uploaded;
  final List<String> failedNames;

  const FilesUploadOutcome({required this.uploaded, required this.failedNames});
}

/// Whether an upload, folder creation, or file mutation is running.
class FilesActionsState {
  final int uploadsLeft;
  final bool isCreatingFolder;
  final Set<String> busyFileIds;

  const FilesActionsState({
    this.uploadsLeft = 0,
    this.isCreatingFolder = false,
    this.busyFileIds = const <String>{},
  });

  bool get isUploading => uploadsLeft > 0;

  bool isFileBusy(String fileId) => busyFileIds.contains(fileId);
}

/// Upload File, New Folder, Restore File, and Delete File. Each refreshes the
/// list it changed.
class FilesActionsNotifier extends Notifier<FilesActionsState> {
  @override
  FilesActionsState build() => const FilesActionsState();

  /// Uploads [files] one at a time, as the web app does, then shows the
  /// Files tab at the top level, where the server puts uploads. Deleted files
  /// and Shared with me never list your own uploads, so those switch to All
  /// files.
  Future<FilesUploadOutcome> uploadFiles(List<XFile> files) async {
    if (files.isEmpty || state.isUploading) {
      return const FilesUploadOutcome(uploaded: 0, failedNames: []);
    }
    final repository = ref.read(filesRepositoryProvider);
    var uploaded = 0;
    final failed = <String>[];
    state = FilesActionsState(
      uploadsLeft: files.length,
      isCreatingFolder: state.isCreatingFolder,
      busyFileIds: state.busyFileIds,
    );
    for (final file in files) {
      final result = await repository.uploadFile(file);
      if (!ref.mounted) break;
      switch (result) {
        case Success():
          uploaded++;
        case Failure():
          failed.add(file.name);
      }
      state = FilesActionsState(
        uploadsLeft: state.uploadsLeft - 1,
        isCreatingFolder: state.isCreatingFolder,
        busyFileIds: state.busyFileIds,
      );
    }
    if (ref.mounted && uploaded > 0) {
      final files = ref.read(filesProvider.notifier);
      final view = ref.read(filesProvider).view;
      if (view == FilesScope.trash || view == FilesScope.shared) {
        files.selectView(FilesScope.all);
      }
      files
        ..goToDepth(0)
        ..setTab(FilesTab.files)
        ..setPage(1);
      ref.invalidate(filesListProvider);
    }
    return FilesUploadOutcome(uploaded: uploaded, failedNames: failed);
  }

  /// Creates [name] inside the open folder. Returns an error message, or
  /// null when it worked.
  Future<String?> createFolder(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Enter a folder name.';
    if (state.isCreatingFolder) return null;
    final orgId = ref.read(currentOrgIdProvider);
    if (orgId.isEmpty) return 'Choose a workspace first.';

    state = FilesActionsState(
      uploadsLeft: state.uploadsLeft,
      isCreatingFolder: true,
      busyFileIds: state.busyFileIds,
    );
    final result = await ref
        .read(filesRepositoryProvider)
        .createFolder(
          name: trimmed,
          orgId: orgId,
          parentId: ref.read(filesProvider).folderId,
        );
    if (!ref.mounted) return null;
    state = FilesActionsState(
      uploadsLeft: state.uploadsLeft,
      busyFileIds: state.busyFileIds,
    );
    switch (result) {
      case Success():
        ref.read(filesProvider.notifier).setTab(FilesTab.folders);
        ref.invalidate(foldersListProvider);
        return null;
      case Failure(:final error):
        return error.message.isNotEmpty
            ? error.message
            : 'Could not create the folder. Try again.';
    }
  }

  /// Restores a deleted [fileId] from Trash back to its original location.
  /// Returns null on success, or a user-facing error message on failure.
  Future<String?> restoreFile(String fileId) async {
    if (fileId.isEmpty || state.isFileBusy(fileId)) return null;
    state = FilesActionsState(
      uploadsLeft: state.uploadsLeft,
      isCreatingFolder: state.isCreatingFolder,
      busyFileIds: {...state.busyFileIds, fileId},
    );
    final result = await ref.read(filesRepositoryProvider).restoreFile(fileId);
    if (!ref.mounted) return null;
    final remaining = {...state.busyFileIds}..remove(fileId);
    state = FilesActionsState(
      uploadsLeft: state.uploadsLeft,
      isCreatingFolder: state.isCreatingFolder,
      busyFileIds: remaining,
    );
    switch (result) {
      case Success():
        ref.invalidate(filesListProvider);
        ref.invalidate(foldersListProvider);
        return null;
      case Failure(:final error):
        return error.message.isNotEmpty
            ? error.message
            : 'Could not restore the file. Try again.';
    }
  }

  /// Deletes [fileId] (moves to Trash, or purges when [permanently] is true).
  /// Returns null on success, or a user-facing error message on failure.
  Future<String?> deleteFile(String fileId, {bool permanently = false}) async {
    if (fileId.isEmpty || state.isFileBusy(fileId)) return null;
    state = FilesActionsState(
      uploadsLeft: state.uploadsLeft,
      isCreatingFolder: state.isCreatingFolder,
      busyFileIds: {...state.busyFileIds, fileId},
    );
    final result = await ref
        .read(filesRepositoryProvider)
        .deleteFile(fileId, permanently: permanently);
    if (!ref.mounted) return null;
    final remaining = {...state.busyFileIds}..remove(fileId);
    state = FilesActionsState(
      uploadsLeft: state.uploadsLeft,
      isCreatingFolder: state.isCreatingFolder,
      busyFileIds: remaining,
    );
    switch (result) {
      case Success():
        ref.invalidate(filesListProvider);
        ref.invalidate(foldersListProvider);
        return null;
      case Failure(:final error):
        return error.message.isNotEmpty
            ? error.message
            : (permanently
                  ? 'Could not permanently delete the file. Try again.'
                  : 'Could not delete the file. Try again.');
    }
  }
}
