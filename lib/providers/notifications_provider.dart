import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/seed_data.dart';
import '../models/notification_item.dart';

class NotificationsNotifier extends Notifier<List<NotificationItem>> {
  @override
  List<NotificationItem> build() {
    return seedNotifications;
  }

  void markAsRead(String id) {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(isRead: true);
      }
      return item;
    }).toList();
  }

  void markAllAsRead() {
    state = state.map((item) => item.copyWith(isRead: true)).toList();
  }

  void addNotification(NotificationItem item) {
    state = [item, ...state];
  }
}

final notificationsProvider = NotifierProvider<NotificationsNotifier, List<NotificationItem>>(
  NotificationsNotifier.new,
);

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsProvider);
  return notifs.where((n) => !n.isRead).length;
});
