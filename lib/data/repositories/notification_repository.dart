import 'package:get_storage/get_storage.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final _storage = GetStorage();
  final String _key = 'notifications';

  List<NotificationModel> getNotifications() {
    final List<dynamic>? data = _storage.read(_key);
    if (data == null) return [];
    return data.map((e) => NotificationModel.fromJson(e)).toList();
  }

  void saveNotifications(List<NotificationModel> notifications) {
    _storage.write(_key, notifications.map((e) => e.toJson()).toList());
  }

  void addNotification(NotificationModel notification) {
    final notifications = getNotifications();
    notifications.insert(0, notification);
    saveNotifications(notifications);
  }

  void markAsRead(String id) {
    final notifications = getNotifications();
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index].isRead = true;
      saveNotifications(notifications);
    }
  }

  void markAllAsRead() {
    final notifications = getNotifications();
    for (var n in notifications) {
      n.isRead = true;
    }
    saveNotifications(notifications);
  }

  void clearAll() {
    _storage.write(_key, []);
  }
}
