import 'dart:convert';

import 'package:zedu/core/core.dart';

class ChatStorageService {
  final SecureStorageService _storage;

  ChatStorageService(this._storage);

  Future<void> saveMessages(String groupDmId, List<String> messages) async {
    final key = 'chat_messages_$groupDmId';
    await _storage.writeData(key, jsonEncode(messages));
  }

  Future<List<String>> getCachedMessages(String groupDmId) async {
    final key = 'chat_messages_$groupDmId';
    final data = await _storage.readData(key);
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data) as List<dynamic>;
      return decoded.map((e) => e.toString()).toList();
    }
    return [];
  }

  Future<void> appendMessage(String groupDmId, String message) async {
    final messages = await getCachedMessages(groupDmId);
    messages.add(message);
    await saveMessages(groupDmId, messages);
  }
}

final chatStorageProvider = Provider<ChatStorageService>((ref) {
  return ChatStorageService(locator<SecureStorageService>());
});
