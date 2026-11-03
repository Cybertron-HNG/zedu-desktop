import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/auth/data/models/login_response_model.dart';

void main() {
  group('LoginResponseModel.mockLoginResponse', () {
    test('does not contain hardcoded real JWT or real user PII', () {
      final mock = LoginResponseModel.mockLoginResponse;
      final token = mock['access_token'] as String;
      final user = mock['user'] as Map<String, dynamic>;

      // Verify no 3-part JWT with signature
      expect(token.contains('eyJh'), isFalse);
      expect(token, 'mock-access-token-test-placeholder');

      // Verify no real personal email or username
      expect(user['email'], 'mock.user@example.com');
      expect(user['username'], 'mockuser');
      expect(user['fullname'], 'Mock User');
      expect(user['id'], '00000000-0000-0000-0000-000000000001');

      // Verify notification token is a placeholder
      expect(mock['notification_token'], 'mock-notification-token-test');

      // Verify it safely parses into a LoginResponseModel
      final model = LoginResponseModel.fromJson(mock);
      expect(model.accessToken, 'mock-access-token-test-placeholder');
      expect(model.user.email, 'mock.user@example.com');
    });
  });
}
