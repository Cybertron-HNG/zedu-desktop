import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/auth/data/models/login_response_model.dart';

void main() {
  final validUserJson = <String, dynamic>{
    'id': 'user-123',
    'first_name': 'Test',
    'last_name': 'User',
    'fullname': 'Test User',
    'email': 'test@example.com',
    'phone': '+123456789',
    'username': 'testuser',
    'is_verified': true,
    'is_onboarded': true,
    'created_at': '1700000000',
    'updated_at': '1700000000',
    'avatar_url': 'https://example.com/avatar.png',
    'current_org': 'org-1',
    'current_organisation_slug': 'org-slug',
    'default_avatar_url': 'https://example.com/default.png',
    'expires_in': '1778991491',
    'is_active': true,
    'online': true,
    'organisation': {
      'id': 'org-1',
      'name': 'Org One',
      'description': 'Description',
      'email': 'org@example.com',
      'type': 'company',
      'location': 'Remote',
      'country': 'World',
      'owner_id': 'user-123',
      'logo_url': '',
      'credit_balance': 0,
      'channels_count': 0,
      'total_messages_count': 0,
      'org_roles': <dynamic>[],
      'pinned': false,
      'Users': null,
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
      'channels': null,
      'subscription_plan_id': '',
      'stripe_customer_id': '',
      'org_plan_id': '',
      'organisation_plan': {
        'started_at': '2026-01-01T00:00:00Z',
        'ended_at': '2026-12-31T00:00:00Z',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
        'plan_details': {
          'id': 'plan-1',
          'name': 'Standard',
          'description': 'Details',
          'fee': 0,
          'max_channels': 10,
          'max_users': 10,
          'max_notifications': 10,
          'credits': 0,
        },
      },
      'organisation_slug': 'org-slug',
      'user_role': {'role_id': 'admin', 'role_name': 'Admin'},
    },
    'profile_updated': true,
    'user_id': 'user-123',
  };

  group('LoginResponseModel.fromJson', () {
    test('parses access_token_expires_in when provided as numeric integer', () {
      final json = <String, dynamic>{
        'user': validUserJson,
        'access_token': 'jwt-token-abc',
        'access_token_expires_in': 1778991491,
        'notification_token': 'notif-token-xyz',
      };

      final model = LoginResponseModel.fromJson(json);

      expect(model.accessToken, 'jwt-token-abc');
      expect(model.notificationToken, 'notif-token-xyz');
      expect(
        model.accessTokenExpiresIn,
        DateTime.fromMillisecondsSinceEpoch(1778991491 * 1000),
      );
      expect(model.user.id, 'user-123');
    });

    test('parses access_token_expires_in when provided as string', () {
      final json = <String, dynamic>{
        'user': validUserJson,
        'access_token': 'jwt-token-abc',
        'access_token_expires_in': '1778991491',
        'notification_token': 'notif-token-xyz',
      };

      final model = LoginResponseModel.fromJson(json);

      expect(
        model.accessTokenExpiresIn,
        DateTime.fromMillisecondsSinceEpoch(1778991491 * 1000),
      );
    });

    test(
      'handles null notification_token and null access_token_expires_in safely',
      () {
        final json = <String, dynamic>{
          'user': validUserJson,
          'access_token': 'jwt-token-abc',
          'access_token_expires_in': null,
          'notification_token': null,
        };

        expect(() => LoginResponseModel.fromJson(json), returnsNormally);

        final model = LoginResponseModel.fromJson(json);
        expect(model.notificationToken, '');
        expect(
          model.accessTokenExpiresIn,
          DateTime.fromMillisecondsSinceEpoch(0),
        );
      },
    );

    test('handles unparseable or empty access_token_expires_in gracefully', () {
      final json = <String, dynamic>{
        'user': validUserJson,
        'access_token': null,
        'access_token_expires_in': 'not-a-number',
        'notification_token': null,
      };

      final model = LoginResponseModel.fromJson(json);
      expect(model.accessToken, '');
      expect(
        model.accessTokenExpiresIn,
        DateTime.fromMillisecondsSinceEpoch(0),
      );
    });
  });

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
