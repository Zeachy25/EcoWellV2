import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../models/visit.dart';
import '../../providers/visits_provider.dart';
import '../shared/ecowell_app_bar.dart';

class VisitHistoryScreen extends ConsumerWidget {
  const VisitHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsAsync = ref.watch(visitsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const EcoWellAppBar(
        title: 'Full Visit History',
        showBack: true,
        showNotifications: false,
      ),
      body: SafeArea(
        child: visitsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (visits) {
            if (visits.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.nature_people_outlined, color: AppColors.mintGreen, size: 54),
                    SizedBox(height: 12),
                    Text('No visit history recorded yet.'),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: visits.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final visit = visits[index];
                return _buildVisitHistoryCard(context, visit);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildVisitHistoryCard(BuildContext context, Visit visit) {
    final durationMins = visit.endTime.difference(visit.startTime).inMinutes.abs();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  visit.greenSpaceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'serif', color: AppColors.forestDark),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.mintLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${visit.stressReduction} Stress Reduction',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primaryGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${visit.startTime.month}/${visit.startTime.day}/${visit.startTime.year} • $durationMins min visit • Quiet: ${visit.quietRating}/5 ⭐',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMiniMetric('Pre PSS-4', '${visit.preScore}'),
              const SizedBox(width: 16),
              _buildMiniMetric('Post PSS-4', '${visit.postScore}'),
              const SizedBox(width: 16),
              _buildMiniMetric('Quiet Score', '${visit.quietRating}/5'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }
}
