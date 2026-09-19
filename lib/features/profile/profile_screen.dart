import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/utils/responsive.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/streak_provider.dart';
import '../../providers/visits_provider.dart';
import '../shared/ecowell_app_bar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final streak = ref.watch(currentStreakProvider);
    final visitsAsync = ref.watch(visitsProvider);
    final reminderEnabled = ref.watch(dailyReminderProvider);
    final visits = visitsAsync.value ?? [];

    final totalVisits = visits.length;
    final avgReduction = visits.isEmpty
        ? 0.0
        : visits.fold<int>(0, (sum, v) => sum + v.stressReduction) / totalVisits;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const EcoWellAppBar(
        showBack: true,
        showNotifications: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            Responsive.horizontalPadding(context),
            Responsive.size(context, 8),
            Responsive.horizontalPadding(context),
            Responsive.bottomNavClearance(context),
          ),
          children: [
            // User Profile Card
            Container(
              padding: EdgeInsets.all(Responsive.size(context, 20)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Responsive.radius(context, 22)),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: Responsive.size(context, 38),
                    backgroundColor: AppColors.mintSoft,
                    child: Text(
                      user?.name.isNotEmpty ?? false ? user!.name[0].toUpperCase() : 'A',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 32),
                        fontWeight: FontWeight.w900,
                        fontFamily: 'serif',
                        color: AppColors.forestDark,
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.size(context, 12)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user?.name ?? 'Arlene Rollorata',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 18),
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(width: Responsive.size(context, 6)),
                      Icon(Icons.check_circle, color: AppColors.streakOrange, size: Responsive.size(context, 16)),
                    ],
                  ),
                  SizedBox(height: Responsive.size(context, 2)),
                  Text(
                    user?.handle ?? '@arlenerollorata',
                    style: TextStyle(fontSize: Responsive.fontSize(context, 12), color: AppColors.textTertiary),
                  ),
                  SizedBox(height: Responsive.size(context, 8)),
                  Text(
                    user?.bio ?? 'Nature enthusiast & mindfulness practitioner in Mati City 🌿',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: Responsive.fontSize(context, 13), color: AppColors.textSecondary),
                  ),
                  SizedBox(height: Responsive.size(context, 18)),
                  const Divider(color: AppColors.cardBorder),
                  SizedBox(height: Responsive.size(context, 10)),

                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildProfileStat('Visits', '$totalVisits'),
                      _buildProfileStat('Streak', '$streak Days'),
                      _buildProfileStat('Avg Reduction', '+${avgReduction.toStringAsFixed(1)}'),
                      _buildProfileStat('Followers', user?.followersCount ?? '1.2k'),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: Responsive.size(context, 20)),

            // Settings & Preferences Card
            Container(
              padding: EdgeInsets.all(Responsive.size(context, 18)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Responsive.radius(context, 20)),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings & Reminders',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 16),
                      fontWeight: FontWeight.w800,
                      fontFamily: 'serif',
                      color: AppColors.forestDark,
                    ),
                  ),
                  SizedBox(height: Responsive.size(context, 12)),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Daily Nature Walk Reminder', style: TextStyle(fontSize: Responsive.fontSize(context, 14), fontWeight: FontWeight.w600)),
                    subtitle: Text('Smart reminder based on optimal Mati weather', style: TextStyle(fontSize: Responsive.fontSize(context, 12), color: AppColors.textSecondary)),
                    value: reminderEnabled,
                    activeTrackColor: AppColors.primaryGreen,
                    onChanged: (val) async {
                      await ref.read(dailyReminderProvider.notifier).setEnabled(val);
                    },
                  ),
                  const Divider(color: AppColors.cardBorder),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.forestDark),
                    title: Text('Download Wellness Data (PDF)', style: TextStyle(fontSize: Responsive.fontSize(context, 14), fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () => context.push('/dashboard'),
                  ),
                  const Divider(color: AppColors.cardBorder),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history_rounded, color: AppColors.forestDark),
                    title: Text('View Full Visit History', style: TextStyle(fontSize: Responsive.fontSize(context, 14), fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () => context.push('/visit-history'),
                  ),
                ],
              ),
            ),

            SizedBox(height: Responsive.size(context, 24)),

            // Logout Button
            SizedBox(
              height: Responsive.size(context, 48),
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Log Out'),
                      content: const Text('Are you sure you want to log out?'),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Log Out', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    await ref.read(authControllerProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  }
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
                label: Text(
                  'Log Out',
                  style: TextStyle(fontSize: Responsive.fontSize(context, 14), fontWeight: FontWeight.w700, color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFFCDD2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(context, 14))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: Responsive.fontSize(context, 16),
            fontWeight: FontWeight.w800,
            color: AppColors.forestDark,
          ),
        ),
        SizedBox(height: Responsive.size(context, 2)),
        Text(
          label,
          style: TextStyle(fontSize: Responsive.fontSize(context, 11), color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
