import 'dart:async';
import 'package:get/get.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/supabase_notification_repository.dart';

class NotificationController extends GetxController {
  final NotificationRepository _repo = Get.find<NotificationRepository>();
  final AuthRepository _authRepo = Get.find<AuthRepository>();

  final notifications = <NotificationModel>[].obs;
  final unreadCount = 0.obs;
  StreamSubscription? _notificationSubscription;

  @override
  void onInit() {
    super.onInit();
    _subscribeToNotifications();
  }

  @override
  void onClose() {
    _notificationSubscription?.cancel();
    super.onClose();
  }

  void _subscribeToNotifications() {
    final currentUser = _authRepo.currentUser.value;
    if (currentUser == null) return;

    _notificationSubscription?.cancel();

    if (_repo is SupabaseNotificationRepository) {
      _notificationSubscription = _repo
          .getNotificationStream(currentUser.id)
          .listen((data) {
            notifications.assignAll(data);
            _updateUnreadCount();
          });
    } else {
      loadNotifications();
    }
  }

  void loadNotifications() {
    notifications.value = _repo.getNotifications();
    _updateUnreadCount();
  }

  void addNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? userId,
    String? route,
    Map<String, dynamic>? arguments,
  }) {
    final currentUserId = userId ?? _authRepo.currentUser.value?.id ?? 'system';

    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: currentUserId,
      title: title,
      body: body,
      type: type,
      timestamp: DateTime.now(),
      route: route,
      arguments: arguments,
    );
    _repo.addNotification(notification);

    if (_repo is! SupabaseNotificationRepository) {
      loadNotifications();
    }
  }

  void markAsRead(String id) {
    _repo.markAsRead(id);
    if (_repo is! SupabaseNotificationRepository) {
      loadNotifications();
    }
  }

  void markAllAsRead() {
    _repo.markAllAsRead();
    if (_repo is! SupabaseNotificationRepository) {
      loadNotifications();
    }
  }

  void clearAll() {
    _repo.clearAll();
    if (_repo is! SupabaseNotificationRepository) {
      loadNotifications();
    }
  }

  void _updateUnreadCount() {
    unreadCount.value = notifications.where((n) => !n.isRead).length;
  }
}
