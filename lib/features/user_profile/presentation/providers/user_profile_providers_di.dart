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

final subscriptionPlansProvider =
    FutureProvider.autoDispose<List<SubscriptionPlan>>((ref) async {
      final result = await ref
          .watch(userProfileRepositoryProvider)
          .getSubscriptionPlans();
      switch (result) {
        case Success<List<SubscriptionPlan>>(:final value):
          return value;
        case Failure<List<SubscriptionPlan>>(:final error):
          throw error;
      }
    });
