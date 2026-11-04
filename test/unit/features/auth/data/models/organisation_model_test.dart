import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

Map<String, dynamic> _json({Map<String, dynamic> overrides = const {}}) => {
  'id': 'org-1',
  'name': 'Acme',
  'description': 'A workspace',
  'email': 'team@acme.test',
  'type': 'company',
  'location': 'Lagos',
  'country': 'NG',
  'owner_id': 'user-1',
  'logo_url': 'https://example.test/logo.png',
  'credit_balance': 0,
  'channels_count': 0,
  'total_messages_count': 0,
  'org_roles': <dynamic>[],
  'pinned': false,
  'Users': null,
  'created_at': '2026-01-01T00:00:00Z',
  'updated_at': '2026-01-01T00:00:00Z',
  'channels': null,
  'subscription_plan_id': 'plan-1',
  'stripe_customer_id': 'cus_1',
  'org_plan_id': 'org-plan-1',
  'organisation_plan': <String, dynamic>{'plan_details': <String, dynamic>{}},
  'organisation_slug': 'acme',
  'user_role': <String, dynamic>{'role_id': 'r1', 'role_name': 'Owner'},
  ...overrides,
};

void main() {
  group('OrganisationModel.fromJson', () {
    test('reads the billing and logo fields when they are set', () {
      final model = OrganisationModel.fromJson(_json());

      expect(model.logoUrl, 'https://example.test/logo.png');
      expect(model.subscriptionPlanId, 'plan-1');
      expect(model.stripeCustomerId, 'cus_1');
      expect(model.orgPlanId, 'org-plan-1');
    });

    test('parses an organisation with no Stripe or plan ids', () {
      final model = OrganisationModel.fromJson(
        _json(
          overrides: {
            'logo_url': null,
            'subscription_plan_id': null,
            'stripe_customer_id': null,
            'org_plan_id': null,
          },
        ),
      );

      expect(model.logoUrl, '');
      expect(model.subscriptionPlanId, '');
      expect(model.stripeCustomerId, '');
      expect(model.orgPlanId, '');
    });
  });
}
