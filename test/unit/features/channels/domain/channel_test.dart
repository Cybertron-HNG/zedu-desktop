import '../../../../helpers/helpers.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('Channel.fromJson', () {
    test('reads the id from channels_id, as the API sends it', () {
      final channel = Channel.fromJson({
        'channels_id': '01a12568-b82e-735c-96bb-00475e765f69',
        'name': 'general',
        'organisation_id': 'org-1',
        'owner_id': 'user-1',
      });

      expect(channel.id, '01a12568-b82e-735c-96bb-00475e765f69');
    });

    test('falls back to id, as written by toJson', () {
      final original = Channel(
        id: 'channel-1',
        name: 'general',
        description: '',
        organisationId: 'org-1',
        ownerId: 'user-1',
      );

      expect(Channel.fromJson(original.toJson()).id, 'channel-1');
    });
  });
}
