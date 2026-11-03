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
  }) => FilesState(
    view: view ?? state.view,
    folderPath: folderPath ?? state.folderPath,
    category: category != null ? category() : state.category,
    dateModified: dateModified != null ? dateModified() : state.dateModified,
    search: search ?? state.search,
    sort: sort ?? state.sort,
    tab: tab ?? state.tab,
    page: page ?? state.page,
  );

  /// Opens one of the sidebar lists at its top level.
  void selectView(FilesScope view) {
    state = _with(view: view, folderPath: const [], page: 1);
  }

  /// Opens [folder] inside the current one and shows its files.
  void openFolder(FileFolder folder) {
    state = _with(
      folderPath: [...state.folderPath, folder],
      tab: FilesTab.files,
      page: 1,
    );
  }

  /// Goes back to the folder at [depth] in the path; 0 is the top level.
  void goToDepth(int depth) {
    if (depth >= state.folderPath.length) return;
    state = _with(folderPath: state.folderPath.sublist(0, depth), page: 1);
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

/// The folders in the open list and folder.
class FoldersListNotifier extends AsyncNotifier<List<FileFolder>> {
  @override
  Future<List<FileFolder>> build() async {
    final (view, parentId) = ref.watch(
      filesProvider.select((s) => (s.view, s.folderId)),
    );
    final result = await ref
        .read(filesRepositoryProvider)
        .fetchFolders(view: view, parentId: parentId);
    return switch (result) {
      Success<List<FileFolder>>(:final value) => value,
      Failure<List<FileFolder>>(:final error) => throw error,
    };
  }
}
