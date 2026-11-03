import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

abstract class FilesRepository {
  Future<Result<FilesPage>> fetchFiles(FilesQuery query);

  /// Folders in [view], inside [parentId] or at the top level when null.
  Future<Result<List<FileFolder>>> fetchFolders({
    required FilesScope view,
    String? parentId,
  });
}
