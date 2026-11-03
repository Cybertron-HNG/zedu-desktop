import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

Map<String, dynamic> _participant(String id, String name) => {
  'user_id': id,
  'email': '$id@zedu.chat',
  'display_name': name,
  'avatar_url': '',
};

void main() {
  late MockApiBaseService api;
  late GroupDmRepository repository;

  setUp(() {
    api = MockApiBaseService();
    repository = GroupDmRepository(api);
  });

  test('create posts the members to the org group-dms route', () async {
    when(
      () => api.post<Map<String, dynamic>>(
        path: any(named: 'path'),
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => ApiResponseModel(
        data: {
          'data': {
            'channel_id': 'c-1',
            'channel_type': 'group_dm',
            'participants': [
              _participant('u1', 'Ada'),
              _participant('u2', 'Bola'),
            ],
          },
        },
        statusCode: 201,
      ),
    );

    final group = await repository.create(
      orgId: 'org-1',
      memberIds: ['u1', 'u2'],
      currentUserId: 'me',
    );

    verify(
      () => api.post<Map<String, dynamic>>(
        path: '/organisations/org-1/group-dms',
        data: {
          'participants': ['u1', 'u2'],
          'chat_type': 'user',
        },
      ),
    ).called(1);
    expect(group.id, 'c-1');
    expect(group.name, 'Ada, Bola');
    expect(group.members.map((m) => m.id), ['u1', 'u2']);
  });

  test('list keeps group DMs only and leaves the signed-in user out', () async {
    when(
      () => api.get<Map<String, dynamic>>(
        path: any(named: 'path'),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => ApiResponseModel(
        data: {
          'data': [
            {
              'channel_id': 'dm-1',
              'channel_type': 'dm',
              'participants': [_participant('u1', 'Ada')],
            },
            {
              'channel_id': 'g-1',
              'channel_type': 'group_dm',
              'participants': [
                _participant('me', 'Me'),
                _participant('u1', 'Ada'),
                _participant('u2', 'Bola'),
              ],
            },
            {'channel_type': 'group_dm', 'participants': <dynamic>[]},
          ],
        },
        statusCode: 200,
      ),
    );

    final groups = await repository.list(orgId: 'org-1', currentUserId: 'me');

    expect(groups.map((g) => g.id), ['g-1']);
    expect(groups.single.members.map((m) => m.id), ['u1', 'u2']);
    expect(groups.single.name, 'Ada, Bola');
    verify(
      () => api.get<Map<String, dynamic>>(
        path: '/organisations/org-1/group-dms',
        queryParameters: {'page': 1, 'limit': 100},
      ),
    ).called(1);
  });

  test(
    'sendMessage posts to the group thread route with a thread id',
    () async {
      when(
        () => api.post<Map<String, dynamic>>(
          path: any(named: 'path'),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async =>
            const ApiResponseModel(data: <String, dynamic>{}, statusCode: 201),
      );

      await repository.sendMessage('g-1', 'Hello team');

      final captured =
          verify(
                () => api.post<Map<String, dynamic>>(
                  path: '/group-dms/channels/g-1/threads',
                  data: captureAny(named: 'data'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured['content'], 'Hello team');
      expect(captured['thread_id'], matches(RegExp(r'^[0-9a-f-]{36}$')));
    },
  );

  test('a create response without a channel id is an error', () {
    when(
      () => api.post<Map<String, dynamic>>(
        path: any(named: 'path'),
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => const ApiResponseModel(
        data: <String, dynamic>{'data': <String, dynamic>{}},
        statusCode: 201,
      ),
    );

    expect(
      repository.create(orgId: 'org-1', memberIds: ['u1', 'u2']),
      throwsFormatException,
    );
  });
}
