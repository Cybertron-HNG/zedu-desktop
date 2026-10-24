import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zedu/features/features.dart';

class _MockDio extends Mock implements Dio {}

Response<Map<String, dynamic>> _release(Map<String, dynamic> data) => Response(
  data: data,
  requestOptions: RequestOptions(path: UpdateCheckService.latestReleaseUrl),
);

void main() {
  group('UpdateCheckService.isNewer', () {
    test('compares versions number by number', () {
      expect(UpdateCheckService.isNewer('v0.2.0', '0.1.0'), isTrue);
      expect(UpdateCheckService.isNewer('0.10.0', '0.9.0'), isTrue);
      expect(UpdateCheckService.isNewer('1.0.0', '0.9.9'), isTrue);
    });

    test('is false for the same or an older version', () {
      expect(UpdateCheckService.isNewer('v0.1.0', '0.1.0'), isFalse);
      expect(UpdateCheckService.isNewer('0.1.0', '0.1.1'), isFalse);
    });

    test('ignores the build number', () {
      expect(UpdateCheckService.isNewer('0.1.0', '0.1.0+5'), isFalse);
    });
  });

  group('UpdateCheckService.latestIfNewer', () {
    late _MockDio dio;
    late UpdateCheckService service;

    setUp(() {
      dio = _MockDio();
      service = UpdateCheckService(dio: dio);
    });

    test('returns the release when it is newer', () async {
      when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => _release({
          'tag_name': 'v0.2.0',
          'html_url': 'https://example.com/releases/tag/v0.2.0',
        }),
      );

      final update = await service.latestIfNewer('0.1.0');

      expect(update?.version, '0.2.0');
      expect(update?.url, contains('/releases/tag/v0.2.0'));
    });

    test('returns null when up to date', () async {
      when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => _release({'tag_name': 'v0.1.0', 'html_url': 'https://x'}),
      );

      expect(await service.latestIfNewer('0.1.0'), isNull);
    });

    test('returns null when the check fails', () async {
      when(
        () => dio.get<Map<String, dynamic>>(any()),
      ).thenThrow(DioException(requestOptions: RequestOptions(path: '')));

      expect(await service.latestIfNewer('0.1.0'), isNull);
    });
  });
}
