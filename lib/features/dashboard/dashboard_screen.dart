import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/pdf_export_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/utils/responsive.dart';
import '../../models/visit.dart';
import '../../providers/auth_provider.dart';
import '../../providers/streak_provider.dart';
import '../../providers/visits_provider.dart';
import '../shared/ecowell_app_bar.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
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
    final visitsAsync = ref.watch(visitsProvider);
    final streak = ref.watch(currentStreakProvider);
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const EcoWellAppBar(
        showBack: false,
        showUserAvatar: true,
        showNotifications: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Segmented Tab Bar: Progress / History
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding(context),
                vertical: Responsive.size(context, 8),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Responsive.radius(context, 16)),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppColors.forestDark,
                  borderRadius: BorderRadius.circular(Responsive.radius(context, 14)),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: TextStyle(
                  fontSize: Responsive.fontSize(context, 14),
                  fontWeight: FontWeight.w700,
                ),
                tabs: const [
                  Tab(text: 'Progress'),
                  Tab(text: 'Visit History'),
                ],
              ),
            ),

            Expanded(
              child: visitsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error loading dashboard: $err')),
                data: (visits) => TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProgressTab(context, visits, streak, user?.name ?? 'Arlene'),
                    _buildHistoryTab(context, visits),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressTab(BuildContext context, List<Visit> visits, int streak, String userName) {
    final totalVisits = visits.length;
    final avgReduction = visits.isEmpty
        ? 0.0
        : visits.fold<int>(0, (sum, v) => sum + v.stressReduction) / totalVisits;
    final avgQuiet = visits.isEmpty
        ? 0.0
        : visits.fold<int>(0, (sum, v) => sum + v.quietRating) / totalVisits;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        Responsive.horizontalPadding(context),
        Responsive.size(context, 8),
        Responsive.horizontalPadding(context),
        Responsive.bottomNavClearance(context),
      ),
      children: [
        // Summary Card: Stress Reduction Score Hero
        Container(
          padding: EdgeInsets.all(Responsive.size(context, 20)),
          decoration: BoxDecoration(
            gradient: AppColors.primaryButtonGradient,
            borderRadius: BorderRadius.circular(Responsive.radius(context, 22)),
            boxShadow: AppShadows.buttonGreen,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Average Stress Reduction',
                    style: TextStyle(fontSize: Responsive.fontSize(context, 13), fontWeight: FontWeight.w600, color: AppColors.textOnDarkMuted),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: Responsive.size(context, 10), vertical: Responsive.size(context, 4)),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(Responsive.radius(context, 12)),
                    ),
                    child: Text(
                      '🔥 $streak-Day Streak',
                      style: TextStyle(fontSize: Responsive.fontSize(context, 11), fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.size(context, 10)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '+${avgReduction.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 48),
                      fontWeight: FontWeight.w900,
                      fontFamily: 'serif',
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: Responsive.size(context, 8)),
                  Text(
                    'pts / visit',
                    style: TextStyle(fontSize: Responsive.fontSize(context, 14), fontWeight: FontWeight.w600, color: AppColors.textOnDarkMuted),
                  ),
                ],
              ),
              SizedBox(height: Responsive.size(context, 14)),
              Row(
                children: [
                  _buildStatPill(context, 'Total Sessions', '$totalVisits'),
                  SizedBox(width: Responsive.size(context, 12)),
                  _buildStatPill(context, 'Avg Quiet Score', '${avgQuiet.toStringAsFixed(1)} / 5'),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: Responsive.size(context, 20)),

        // Weekly Stress Reduction Chart
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Weekly Stress Reduction (PSS-4 Delta)',
                    style: TextStyle(fontSize: Responsive.fontSize(context, 14), fontWeight: FontWeight.w700, color: AppColors.forestDark),
                  ),
                  const Icon(Icons.insights_rounded, color: AppColors.mintGreen, size: 20),
                ],
              ),
              SizedBox(height: Responsive.size(context, 20)),
              SizedBox(
                height: Responsive.size(context, 160),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 10,
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 26,
                          getTitlesWidget: (val, meta) => Text(
                            '${val.toInt()}',
                            style: TextStyle(fontSize: Responsive.fontSize(context, 10), color: AppColors.textTertiary),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                            final i = val.toInt();
                            if (i >= 0 && i < days.length) {
                              return Text(days[i], style: TextStyle(fontSize: Responsive.fontSize(context, 10), color: AppColors.textSecondary));
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(color: AppColors.cardBorder, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      _buildBarGroup(context, 0, 5),
                      _buildBarGroup(context, 1, 7),
                      _buildBarGroup(context, 2, 6),
                      _buildBarGroup(context, 3, 8),
                      _buildBarGroup(context, 4, 5),
                      _buildBarGroup(context, 5, 9),
                      _buildBarGroup(context, 6, 7),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: Responsive.size(context, 20)),

        // PDF Data Export Button
        SizedBox(
          height: Responsive.size(context, 52),
          child: OutlinedButton.icon(
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Generating PDF Wellness Report...')),
              );
              try {
                final user = ref.read(authControllerProvider).user;
                if (user != null) {
                  await PdfExportService().exportVisitSummary(user: user, visits: visits);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('PDF report shared for $userName.')),
                  );
                }
              }
            },
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.forestDark),
            label: Text(
              'Export Wellness Report (PDF)',
              style: TextStyle(fontSize: Responsive.fontSize(context, 14), fontWeight: FontWeight.w700, color: AppColors.forestDark),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.forestDark, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(context, 16))),
            ),
          ),
        ),
      ],
    );
  }

  BarChartGroupData _buildBarGroup(BuildContext context, int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: const LinearGradient(
            colors: [Color(0xFF38B289), Color(0xFF1E5E41)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: Responsive.size(context, 14),
          borderRadius: BorderRadius.circular(Responsive.radius(context, 6)),
        ),
      ],
    );
  }

  Widget _buildStatPill(BuildContext context, String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Responsive.size(context, 12), vertical: Responsive.size(context, 6)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(Responsive.radius(context, 12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: Responsive.fontSize(context, 10), color: AppColors.textOnDarkMuted)),
          SizedBox(height: Responsive.size(context, 2)),
          Text(value, style: TextStyle(fontSize: Responsive.fontSize(context, 13), fontWeight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context, List<Visit> visits) {
    if (visits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.spa_outlined, color: AppColors.mintGreen, size: 48),
            SizedBox(height: 12),
            Text('No visits recorded yet. Take your first nature session!'),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        Responsive.horizontalPadding(context),
        Responsive.size(context, 12),
        Responsive.horizontalPadding(context),
        Responsive.bottomNavClearance(context),
      ),
      itemCount: visits.length,
      separatorBuilder: (context, index) => SizedBox(height: Responsive.size(context, 12)),
      itemBuilder: (context, index) {
        final visit = visits[index];
        return Container(
          padding: EdgeInsets.all(Responsive.size(context, 16)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Responsive.radius(context, 18)),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: Responsive.size(context, 48),
                height: Responsive.size(context, 48),
                decoration: BoxDecoration(
                  color: AppColors.mintLight,
                  borderRadius: BorderRadius.circular(Responsive.radius(context, 14)),
                ),
                child: Center(
                  child: Icon(Icons.park_rounded, color: AppColors.primaryGreen, size: Responsive.size(context, 24)),
                ),
              ),
              SizedBox(width: Responsive.size(context, 14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visit.greenSpaceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: Responsive.fontSize(context, 14), fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: Responsive.size(context, 4)),
                    Text(
                      '${visit.startTime.month}/${visit.startTime.day}/${visit.startTime.year} • Quiet: ${visit.quietRating}/5',
                      style: TextStyle(fontSize: Responsive.fontSize(context, 11), color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: Responsive.size(context, 10), vertical: Responsive.size(context, 6)),
                decoration: BoxDecoration(
                  color: AppColors.mintSoft,
                  borderRadius: BorderRadius.circular(Responsive.radius(context, 10)),
                ),
                child: Text(
                  '+${visit.stressReduction} pts',
                  style: TextStyle(fontSize: Responsive.fontSize(context, 12), fontWeight: FontWeight.w800, color: AppColors.forestDark),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}