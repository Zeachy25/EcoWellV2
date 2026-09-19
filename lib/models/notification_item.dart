enum NotificationCategory { all, reminder, community, weather }

class NotificationItem {
  final String id;
  final String title;
  final String description;
  final NotificationCategory category;
  final DateTime timestamp;
  final bool isRead;
  final String? actionRoute;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.timestamp,
    this.isRead = false,
    this.actionRoute,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      description: description,
      category: category,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute,
    );
  }
}
