import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';
import 'ecowell_logo.dart';

class EcoWellAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBack;
  final bool showUserAvatar;
  final bool showNotifications;
  final bool showSettings;
  final VoidCallback? onBack;

  const EcoWellAppBar({
    super.key,
    this.title,
    this.showBack = false,
    this.showUserAvatar = false,
    this.showNotifications = true,
    this.showSettings = true,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final appBarHeight = Responsive.size(context, 60);
    final iconSize = Responsive.size(context, 22);
    final avatarRadius = Responsive.size(context, 16);
    final iconBtnSize = Responsive.size(context, 40);

    return SafeArea(
      child: Container(
        height: appBarHeight,
        padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalPadding(context)),
        child: Row(
          children: [
            if (showBack)
              IconButton(
                constraints: BoxConstraints(
                  minWidth: iconBtnSize,
                  minHeight: iconBtnSize,
                ),
                padding: EdgeInsets.zero,
                icon: Icon(Icons.arrow_back, color: AppColors.forestDark, size: iconSize),
                onPressed: onBack ?? () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              )
            else
              EcoWellLogo(size: iconSize),
            if (title != null && showBack) ...[
              SizedBox(width: Responsive.size(context, 8)),
              Flexible(
                child: Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 18),
                    fontWeight: FontWeight.w700,
                    fontFamily: 'serif',
                    color: AppColors.forestDark,
                  ),
                ),
              ),
            ],
            const Spacer(),
            if (showUserAvatar && user != null) ...[
              Tooltip(
                message: 'Profile',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push('/profile'),
                  child: SizedBox(
                    width: iconBtnSize,
                    height: iconBtnSize,
                    child: Center(
                      child: CircleAvatar(
                        radius: avatarRadius,
                        backgroundColor: AppColors.mintSoft,
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'A',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 14),
                            fontWeight: FontWeight.w700,
                            color: AppColors.forestDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: Responsive.size(context, 8)),
            ],
            if (showSettings)
              IconButton(
                constraints: BoxConstraints(
                  minWidth: iconBtnSize,
                  minHeight: iconBtnSize,
                ),
                padding: EdgeInsets.zero,
                icon: Icon(Icons.settings_outlined, color: AppColors.forestDark, size: iconSize),
                tooltip: 'Settings',
                onPressed: () => context.push('/profile'),
              ),
            if (showNotifications)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    constraints: BoxConstraints(
                      minWidth: iconBtnSize,
                      minHeight: iconBtnSize,
                    ),
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.notifications_none_rounded, color: AppColors.forestDark, size: Responsive.size(context, 24)),
                    tooltip: 'Notifications',
                    onPressed: () => context.push('/notifications'),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.all(Responsive.size(context, 4)),
                        decoration: const BoxDecoration(
                          color: AppColors.streakOrange,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Responsive.fontSize(context, 10),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
