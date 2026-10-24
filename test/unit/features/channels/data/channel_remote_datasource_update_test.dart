import '../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

void main() {
  group('ChannelRemoteDataSourceImpl.updateChannelTopicOrDescription', () {
    late MockApiBaseService mockApi;
    late ChannelRemoteDataSourceImpl datasource;

    setUp(() {
      mockApi = MockApiBaseService();
      datasource = ChannelRemoteDataSourceImpl(apiBaseService: mockApi);
      when(
        () => mockApi.patch<Map<String, dynamic>>(
          path: any(named: 'path'),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => ApiResponseModel<Map<String, dynamic>>(
          data: const {},
          statusCode: 200,
        ),
      );
    });

    test('sends PATCH /channels/:id, the route the backend has', () async {
      await datasource.updateChannelTopicOrDescription(
        channelId: 'c1',
        topic: 'Launch week',
        description: 'All team members',
      );

      verify(
        () => mockApi.patch<Map<String, dynamic>>(
          path: '/channels/c1',
          data: {'topic': 'Launch week', 'description': 'All team members'},
        ),
      ).called(1);
    });

    test('leaves out a field that is not being changed', () async {
      await datasource.updateChannelTopicOrDescription(
        channelId: 'c1',
        topic: 'Launch week',
      );

      verify(
        () => mockApi.patch<Map<String, dynamic>>(
          path: '/channels/c1',
          data: {'topic': 'Launch week'},
        ),
      ).called(1);
    });
  });
}
