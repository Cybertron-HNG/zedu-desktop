import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class FilesRepositoryImpl implements FilesRepository {
  final FilesRemoteDataSource remoteDataSource;

  FilesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<FilesPage>> fetchFiles(FilesQuery query) async {
    try {
      return Success(await remoteDataSource.fetchFiles(query));
    } on ApiFailure catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<FileFolder>>> fetchFolders({
    required FilesScope view,
    String? parentId,
  }) async {
    try {
      return Success(
        await remoteDataSource.fetchFolders(view: view, parentId: parentId),
      );
    } on ApiFailure catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(ApiFailure(message: e.toString()));
    }
  }
}
