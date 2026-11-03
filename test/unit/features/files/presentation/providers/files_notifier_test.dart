import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

const _docs = FileFolder(id: 'docs', name: 'docs');
const _drafts = FileFolder(id: 'drafts', name: 'drafts');

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
}
