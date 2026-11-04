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
    AsyncNotifierProvider<FoldersListNotifier, List<FileFolder>>(
      FoldersListNotifier.new,
    );

/// Opens a file's link in the browser or default app and says whether it
/// did. Tests override it so nothing is launched.
final fileLinkOpenerProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) async => await canLaunchUrl(uri) && await launchUrl(uri),
);
