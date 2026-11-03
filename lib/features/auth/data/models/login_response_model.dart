import 'package:zedu/features/features.dart';

class LoginResponseModel {
  const LoginResponseModel({
    required this.user,
    required this.accessToken,
    required this.accessTokenExpiresIn,
    required this.notificationToken,
  });

  final UserModel user;
  final String accessToken;
  final DateTime accessTokenExpiresIn;
  final String notificationToken;

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['access_token'] as String,
      accessTokenExpiresIn: DateTime.fromMillisecondsSinceEpoch(
        int.parse(json['access_token_expires_in'] as String) * 1000,
      ),
      notificationToken: json['notification_token'] as String,
    );
  }

  static const String _mockAccessToken = 'mock-access-token-test-placeholder';

  static final Map<String, dynamic> _mockLoginResponse = {
    'access_token': _mockAccessToken,
    'access_token_expires_in': '1778991491',
    'notification_token': 'mock-notification-token-test',
    'user': {
      'avatar_url': '',
      'created_at': '1778373782',
      'current_org': '00000000-0000-0000-0000-000000000002',
      'current_organisation_slug': 'mock-org',
      'default_avatar_url': 'https://example.com/avatar.png',
      'email': 'mock.user@example.com',
      'expires_in': '1778991491',
      'first_name': 'Mock',
      'fullname': 'Mock User',
      'id': '00000000-0000-0000-0000-000000000001',
      'is_active': true,
      'is_onboarded': true,
      'is_verified': false,
      'last_name': 'User',
      'online': true,
      'organisation': {
        'id': '00000000-0000-0000-0000-000000000002',
        'name': 'Mock Organization',
        'description': 'Mock test organization',
        'email': 'mock.org@example.com',
        'type': 'user default org',
        'location': '0.0,0.0',
        'country': 'us',
        'owner_id': '00000000-0000-0000-0000-000000000001',
        'logo_url': '',
        'credit_balance': 10,
        'channels_count': 1,
        'total_messages_count': 0,
        'org_roles': <Map<String, dynamic>>[],
        'pinned': false,
        'Users': null,
        'created_at': '2026-05-10T02:43:02.443874+02:00',
        'updated_at': '2026-05-10T02:43:02.443874+02:00',
        'channels': null,
        'subscription_plan_id': 'free',
        'stripe_customer_id': '',
        'org_plan_id': '00000000-0000-0000-0000-000000000003',
        'organisation_plan': {
          'started_at': '0001-01-01T00:00:00Z',
          'ended_at': '0001-01-01T00:00:00Z',
          'created_at': '0001-01-01T00:00:00Z',
          'updated_at': '0001-01-01T00:00:00Z',
          'plan_details': {
            'id': '',
            'name': '',
            'description': '',
            'benefits': null,
            'fee': 0,
            'max_channels': 0,
            'max_users': 0,
            'max_notifications': 0,
            'can_upgrade_notifications': false,
            'can_add_unlimited_channels': false,
            'can_add_unlimited_users': false,
            'is_for_individuals': false,
            'is_for_small_business': false,
            'is_for_large_enterprise': false,
            'unlimited_ai_co_workers': false,
            'create_your_own_ai_co_workers': false,
            'ai_credits_purchasable': false,
            'max_call_duration': 0,
            'max_buzz_participants': 0,
            'max_active_calls': 0,
            'call_records_available': false,
            'transcript_available': false,
            'advanced_controls': false,
            'advanced_controls_user': false,
            'created_at': '0001-01-01T00:00:00Z',
            'credits': 0,
            'updated_at': '0001-01-01T00:00:00Z',
          },
        },
        'organisation_slug': 'mock-org',
        'user_role': {'role_id': '', 'role_name': ''},
      },
      'phone': '',
      'profile_updated': true,
      'updated_at': '1778386691',
      'user_id': '00000000-0000-0000-0000-000000000001',
      'username': 'mockuser',
    },
  };

  static Map<String, dynamic> get mockLoginResponse => _mockLoginResponse;
}
