import 'dart:math' show Random;

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

final groupDmRepositoryProvider = Provider<GroupDmRepository>((ref) {
  return GroupDmRepository(locator<ApiBaseService>());
});

/// The signed-in user's id, left out of a group's member list.
final groupDmUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authNotifierProvider.select((s) => s.user?.id));
});

/// Group DMs on the server (`/organisations/{org}/group-dms`), so a group is
/// shared with its members and still there after a restart.
class GroupDmRepository {
  GroupDmRepository(this._apiClient);

  final ApiBaseService _apiClient;

  /// Creates a group DM with [memberIds]; the server adds the signed-in user.
  Future<GroupDM> create({
    required String orgId,
    required List<String> memberIds,
    String? currentUserId,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      path: '/organisations/$orgId/group-dms',
      data: {'participants': memberIds, 'chat_type': 'user'},
    );
    final data = response.data['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid group DM response.');
    }
    final group = groupDmFromJson(data, currentUserId: currentUserId);
    if (group == null) {
      throw const FormatException('Invalid group DM response.');
    }
    return group;
  }

  /// Rows per page when listing group DMs.
  static const pageSize = 100;

  /// Stops paging after this many pages, so a misbehaving server can't keep
  /// the app loading forever.
  static const maxPages = 20;

  /// The signed-in user's group DMs in [orgId], from every page. The endpoint
  /// also returns one-to-one DMs: only rows marked `channel_type: group_dm`
  /// are kept, so a row without a type is never shown as a group.
  Future<List<GroupDM>> list({
    required String orgId,
    String? currentUserId,
  }) async {
    final groups = <GroupDM>[];
    for (var page = 1; page <= maxPages; page++) {
      final response = await _apiClient.get<Map<String, dynamic>>(
        path: '/organisations/$orgId/group-dms',
        queryParameters: {'page': page, 'limit': pageSize},
      );
      final raw = response.data['data'];
      final rows = (raw is List ? raw : const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList();
      groups.addAll(
        rows
            .where((json) => json['channel_type'] == 'group_dm')
            .map((json) => groupDmFromJson(json, currentUserId: currentUserId))
            .whereType<GroupDM>(),
      );
      // A short page is the last one.
      if (rows.length < pageSize) break;
    }
    return groups;
  }

  /// Posts [content] to the group so the other members receive it.
  Future<void> sendMessage(String channelId, String content) async {
    await _apiClient.post<Map<String, dynamic>>(
      path: '/group-dms/channels/$channelId/threads',
      // The server requires a thread_id; a new message starts its own thread.
      data: {'content': content, 'thread_id': _newUuidV7()},
    );
  }

  /// Builds a [GroupDM] from a server group, leaving out the signed-in user
  /// from its members. Null when the group has no channel id.
  static GroupDM? groupDmFromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final channelId = json['channel_id'];
    if (channelId is! String || channelId.isEmpty) return null;

    final rawParticipants = json['participants'];
    final members =
        (rawParticipants is List ? rawParticipants : const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(_memberFromJson)
            .whereType<TeamMember>()
            .where((member) => member.id != currentUserId)
            .toList();

    return GroupDM(id: channelId, name: groupDmName(members), members: members);
  }

  static TeamMember? _memberFromJson(Map<String, dynamic> json) {
    final id = json['user_id'];
    if (id is! String || id.isEmpty) return null;
    String? text(String key) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    return TeamMember(
      id: id,
      email: text('email') ?? '',
      role: 'member',
      dateJoined: '',
      status: TeamMemberStatus.active,
      name:
          text('display_name') ??
          text('full_name') ??
          text('username') ??
          text('email')?.split('@').first,
      avatarUrl: text('avatar_url') ?? text('default_avatar_url'),
    );
  }

  String _newUuidV7() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final ms = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < 6; i++) {
      bytes[i] = (ms >> (8 * (5 - i))) & 0xff;
    }
    bytes[6] = (bytes[6] & 0x0f) | 0x70;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

/// The group's name: its members' names, comma separated.
String groupDmName(List<TeamMember> members) {
  return members.map((m) => m.name ?? m.email.split('@').first).join(', ');
}
