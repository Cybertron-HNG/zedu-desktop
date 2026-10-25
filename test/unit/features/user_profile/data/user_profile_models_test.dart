import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('ProfileAccountModel', () {
    test('maps account json to entity fields', () {
      final account = ProfileAccountModel.fromJson(const {
        'name': 'Anonymous user',
        'email': 'anonymoususer@email.com',
        'timezone': 'Africa/Lagos',
        'avatar_url': 'https://example.com/avatar.png',
      });

      expect(account.name, 'Anonymous user');
      expect(account.email, 'anonymoususer@email.com');
      expect(account.timezone, 'Africa/Lagos');
      expect(account.initials, 'AU');
      expect(account.avatarUrl, 'https://example.com/avatar.png');
    });
  });

  group('NotificationPreferencesModel', () {
    test('maps notification mode and desktop/email preferences', () {
      final preferences = NotificationPreferencesModel.fromJson(const {
        'mode': 'mentions_only',
        'from_time': '9:00 AM',
        'to_time': '5:00 PM',
        'use_desktop_settings': true,
        'email_notifications': true,
      });

      expect(preferences.mode, NotificationMode.mentionsOnly);
      expect(preferences.fromTime, '9:00 AM');
      expect(preferences.toTime, '5:00 PM');
      expect(preferences.useDesktopSettings, isTrue);
      expect(preferences.emailNotifications, isTrue);
    });
  });

  group('TeamMemberModel', () {
    test('maps pending members from json', () {
      final member = TeamMemberModel.fromJson(const {
        'id': 'member-2',
        'email': 'invitee@zedu.chat',
        'role': 'Manager',
        'date_joined': 'Pending',
        'status': 'pending',
      });

      expect(member.id, 'member-2');
      expect(member.email, 'invitee@zedu.chat');
      expect(member.role, 'Manager');
      expect(member.status, TeamMemberStatus.pending);
    });
  });

  group('RolePermissionModel', () {
    test('maps the organisation roles response', () {
      final role = RolePermissionModel.fromJson(const {
        'id': 'role-1',
        'name': 'Manager',
        'description': 'Read, write, approve',
        'permissions': {
          'permission_list': {
            'can_view_channels': true,
            'can_view_billing': false,
          },
        },
      });

      expect(role.id, 'role-1');
      expect(role.role, 'Manager');
      expect(role.description, 'Read, write, approve');
      expect(role.permissions, ['can_view_channels']);
    });

    test('keeps the mock shape with a role name and a permission list', () {
      final role = RolePermissionModel.fromJson(const {
        'role': 'Guess',
        'description': 'Read-only access',
        'permissions': ['View channels'],
      });

      expect(role.role, 'Guess');
      expect(role.permissions, ['View channels']);
    });
  });
}
