// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import 'notification_repository.dart';

class SupabaseNotificationRepository extends NotificationRepository {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  List<NotificationModel> getNotifications() {
    return super.getNotifications();
  }

  Stream<List<NotificationModel>> getNotificationStream(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map(
          (maps) => maps.map((map) => NotificationModel.fromJson(map)).toList(),
        );
  }

  @override
  void addNotification(NotificationModel notification) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': notification.userId,
        'title': notification.title,
        'body': notification.body,
        'type': notification.type.name,
        'is_read': notification.isRead,
      });
    } catch (e) {
      print('Error adding notification: $e');
    }
  }

  @override
  void markAsRead(String id) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  @override
  void markAllAsRead() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id);
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  @override
  void clearAll() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('notifications').delete().eq('user_id', user.id);
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }
}
