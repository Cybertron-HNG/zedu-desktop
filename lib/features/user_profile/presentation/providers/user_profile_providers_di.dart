import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

final userProfileRemoteDataSourceProvider =
    Provider<UserProfileRemoteDataSource>(
      (ref) => UserProfileRemoteDataSourceImpl(
        config: locator<AppConfig>(),
        apiBaseService: locator<ApiBaseService>(),
      ),
    );

final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => UserProfileRepositoryImpl(
    remote: ref.watch(userProfileRemoteDataSourceProvider),
  ),
);

final userProfileNotifierProvider =
    NotifierProvider<UserProfileNotifier, UserProfileState>(
      UserProfileNotifier.new,
    );
