import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/notification_item.dart';
import '../../providers/notifications_provider.dart';
import '../shared/ecowell_app_bar.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationCategory _filter = NotificationCategory.all;

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    final filtered = notifications.where((n) {
      if (_filter == NotificationCategory.all) return true;
      return n.category == _filter;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const EcoWellAppBar(
        title: 'Smart Notifications',
        showBack: true,
        showNotifications: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter categories
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding(context),
                vertical: Responsive.size(context, 8),
              ),
              child: Row(
                children: [
                  _buildFilterChip(context, 'All', NotificationCategory.all),
                  SizedBox(width: Responsive.size(context, 8)),
                  _buildFilterChip(context, 'Reminders', NotificationCategory.reminder),
                  SizedBox(width: Responsive.size(context, 8)),
                  _buildFilterChip(context, 'Community', NotificationCategory.community),
                  SizedBox(width: Responsive.size(context, 8)),
                  _buildFilterChip(context, 'Weather', NotificationCategory.weather),
                ],
              ),
            ),

            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none_rounded, color: AppColors.textTertiary, size: Responsive.size(context, 48)),
                          SizedBox(height: Responsive.size(context, 12)),
                          const Text('No notifications in this category.'),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.all(Responsive.size(context, 16)),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => SizedBox(height: Responsive.size(context, 10)),
                      itemBuilder: (context, index) {
                        final notif = filtered[index];
                        return _buildNotificationCard(context, notif);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, NotificationCategory cat) {
    final isSelected = _filter == cat;
    return GestureDetector(
      onTap: () => setState(() => _filter = cat),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: Responsive.size(context, 12), vertical: Responsive.size(context, 6)),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.forestDark : Colors.white,
          borderRadius: BorderRadius.circular(Responsive.radius(context, 16)),
          border: Border.all(color: isSelected ? AppColors.forestDark : AppColors.cardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: Responsive.fontSize(context, 12),
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationItem notif) {
    return GestureDetector(
      onTap: () {
        ref.read(notificationsProvider.notifier).markAsRead(notif.id);
        if (notif.actionRoute != null) {
          context.push(notif.actionRoute!);
        }
      },
      child: Container(
        padding: EdgeInsets.all(Responsive.size(context, 14)),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(Responsive.radius(context, 16)),
          border: Border.all(
            color: notif.isRead ? AppColors.cardBorder : AppColors.inputBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getCategoryColor(notif.category).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(_getCategoryIcon(notif.category), color: _getCategoryColor(notif.category), size: Responsive.size(context, 18)),
            ),
            SizedBox(width: Responsive.size(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.title,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 14),
                      fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: Responsive.size(context, 4)),
                  Text(
                    notif.description,
                    style: TextStyle(fontSize: Responsive.fontSize(context, 12), color: AppColors.textSecondary, height: 1.3),
                  ),
                ],
              ),
            ),
            if (!notif.isRead)
              Container(
                margin: const EdgeInsets.only(left: 6, top: 4),
                width: Responsive.size(context, 8),
                height: Responsive.size(context, 8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.streakOrange,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(NotificationCategory cat) {
    switch (cat) {
      case NotificationCategory.reminder:
        return AppColors.mintGreen;
      case NotificationCategory.community:
        return AppColors.streakOrange;
      case NotificationCategory.weather:
        return const Color(0xFF0096C7);
      case NotificationCategory.all:
        return AppColors.forestDark;
    }
  }

  IconData _getCategoryIcon(NotificationCategory cat) {
    switch (cat) {
      case NotificationCategory.reminder:
        return Icons.spa_rounded;
      case NotificationCategory.community:
        return Icons.favorite_rounded;
      case NotificationCategory.weather:
        return Icons.wb_sunny_rounded;
      case NotificationCategory.all:
        return Icons.notifications_rounded;
    }
  }
}