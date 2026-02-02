import 'package:get/get.dart';
import '../models/chat_model.dart';
import '../providers/mock_database.dart';

class ChatRepository extends GetxService {
  final MockDatabase _db = MockDatabase();
  final String _key = 'chat_messages';

  List<ChatMessage> getMessages(String projectId) {
    List<ChatMessage> allMessages = _db.getList(_key, ChatMessage.fromJson);
    return allMessages.where((m) => m.projectId == projectId).toList();
  }

  Future<void> sendMessage(ChatMessage message) async {
    List<ChatMessage> allMessages = _db.getList(_key, ChatMessage.fromJson);
    allMessages.add(message);
    _db.saveList(_key, allMessages, (m) => m.toJson());
  }

  Stream<List<ChatMessage>> getMessageStream(String projectId) {
    return Stream.value(getMessages(projectId));
  }
}
