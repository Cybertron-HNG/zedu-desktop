import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('OrganizationProfile.initials', () {
    test('returns ZO when name is empty or only whitespace', () {
      const orgEmpty = OrganizationProfile(
        id: '1',
        name: '',
        natureOfBusiness: 'Tech',
        country: 'Nigeria',
      );
      expect(orgEmpty.initials, 'ZO');

      const orgSpaces = OrganizationProfile(
        id: '2',
        name: '   ',
        natureOfBusiness: 'Tech',
        country: 'Nigeria',
      );
      expect(orgSpaces.initials, 'ZO');
    });

    test('extracts single letter uppercase for single-word name', () {
      const org = OrganizationProfile(
        id: '1',
        name: 'acme',
        natureOfBusiness: 'Tech',
        country: 'Nigeria',
      );
      expect(org.initials, 'A');
    });

    test('extracts first and last word initials for multi-word name', () {
      const org = OrganizationProfile(
        id: '1',
        name: 'zedu desktop workspace',
        natureOfBusiness: 'Tech',
        country: 'Nigeria',
      );
      expect(org.initials, 'ZW');
    });

    test(
      'handles organization names starting with an emoji without splitting surrogate pairs',
      () {
        const orgEmojiSingle = OrganizationProfile(
          id: '1',
          name: '🚀',
          natureOfBusiness: 'Space',
          country: 'Nigeria',
        );
        expect(orgEmojiSingle.initials, '🚀');

        const orgEmojiMulti = OrganizationProfile(
          id: '2',
          name: '🚀 Acme Rockets',
          natureOfBusiness: 'Space',
          country: 'Nigeria',
        );
        expect(orgEmojiMulti.initials, '🚀R');

        const orgEmojiLast = OrganizationProfile(
          id: '3',
          name: 'Acme 🚀',
          natureOfBusiness: 'Space',
          country: 'Nigeria',
        );
        expect(orgEmojiLast.initials, 'A🚀');
      },
    );

    test('handles multi-byte unicode and flag emojis correctly', () {
      const orgFlag = OrganizationProfile(
        id: '1',
        name: '🇳🇬 Nigeria Labs',
        natureOfBusiness: 'Tech',
        country: 'Nigeria',
      );
      expect(orgFlag.initials, '🇳🇬L');
    });
  });
}
