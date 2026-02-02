// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/chat_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/call_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/supabase_chat_repository.dart';

class ChatController extends GetxController {
  final ChatRepository _chatRepo = Get.find<ChatRepository>();
  final AuthRepository _authRepo = Get.find<AuthRepository>();

  String? projectId;

  var messages = <ChatMessage>[].obs;
  final messageController = TextEditingController();
  StreamSubscription? _messageSubscription;

  var currentCall = Rxn<CallModel>();

  @override
  void onClose() {
    _messageSubscription?.cancel();
    super.onClose();
  }

  void initChat(String id) {
    projectId = id;
    _subscribeToMessages();
  }

  void _subscribeToMessages() {
    if (projectId == null) return;

    _messageSubscription?.cancel();

    if (_chatRepo is SupabaseChatRepository) {
      _messageSubscription = _chatRepo.getMessageStream(projectId!).listen((
        msgs,
      ) {
        messages.assignAll(msgs);
      });
    } else {
      loadMessages();
    }
  }

  void loadMessages() {
    if (projectId == null) return;
    var msgs = _chatRepo.getMessages(projectId!);
    msgs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    messages.assignAll(msgs);
  }

  void sendMessage({
    ChatMessageType type = ChatMessageType.text,
    String? attachmentUrl,
  }) async {
    final text = messageController.text.trim();
    if (text.isEmpty && attachmentUrl == null && type != ChatMessageType.call)
      return;

    final currentUser = _authRepo.currentUser.value;
    if (currentUser == null || projectId == null) return;

    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      projectId: projectId!,
      senderId: currentUser.id,
      message: text,
      timestamp: DateTime.now(),
      type: type,
      attachmentUrl: attachmentUrl,
    );

    await _chatRepo.sendMessage(newMessage);
    messageController.clear();
    if (_chatRepo is! SupabaseChatRepository) {
      loadMessages();
    }
  }

  void sendCodeSnippet(String code) {
    messageController.text = code;
    sendMessage(type: ChatMessageType.code);
  }

  void startCall(CallType type) {
    final currentUser = _authRepo.currentUser.value;
    if (currentUser == null || projectId == null) return;

    final receiverName = currentUser.role == UserRole.client
        ? 'Developer'
        : 'Client';

    final call = CallModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      callerId: currentUser.id,
      callerName: currentUser.name,
      receiverId: 'other_user_id', 
      receiverName: receiverName,
      type: type,
      timestamp: DateTime.now(),
    );

    currentCall.value = call;

    messageController.text =
        '${type == CallType.voice ? "Voice" : "Video"} call started';
    sendMessage(type: ChatMessageType.call);
  }

  void endCall() {
    if (currentCall.value != null) {
      final text =
          'Call ended (${DateTime.now().difference(currentCall.value!.timestamp).inMinutes}m)';
      messageController.text = text;
      sendMessage(type: ChatMessageType.call);
      currentCall.value = null;
    }
  }

  bool isMe(String senderId) {
    return _authRepo.currentUser.value?.id == senderId;
  }
}
