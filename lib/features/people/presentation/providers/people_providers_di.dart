import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

final peopleRemoteDataSourceProvider = Provider<PeopleRemoteDataSource>(
  (ref) =>
      PeopleRemoteDataSourceImpl(apiBaseService: locator<ApiBaseService>()),
);

final peopleRepositoryProvider = Provider<PeopleRepository>(
  (ref) => PeopleRepositoryImpl(
    remoteDataSource: ref.watch(peopleRemoteDataSourceProvider),
  ),
);

/// Members matching a search; '' lists everyone.
final peopleListProvider = AsyncNotifierProvider.autoDispose
    .family<PeopleListNotifier, PeopleListState, String>(
      PeopleListNotifier.new,
    );

/// The People tab's one search, shared by the sidebar and the member grid
/// so a name typed in either box filters both. Clears on a workspace switch.
final peopleSearchProvider =
    NotifierProvider.autoDispose<PeopleSearchNotifier, String>(
      PeopleSearchNotifier.new,
    );

final peopleActionsProvider = NotifierProvider<PeopleActionsNotifier, String?>(
  PeopleActionsNotifier.new,
);
