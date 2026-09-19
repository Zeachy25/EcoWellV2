import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/stress_scoring.dart';
import '../../models/pss4.dart';
import '../../models/visit.dart';
import '../../providers/active_visit_provider.dart';
import '../../providers/app_providers.dart';
import '../../providers/visits_provider.dart';
import '../shared/ecowell_app_bar.dart';

class PostVisitAssessmentScreen extends ConsumerStatefulWidget {
  final String spaceId;

  const PostVisitAssessmentScreen({super.key, required this.spaceId});

  @override
  ConsumerState<PostVisitAssessmentScreen> createState() => _PostVisitAssessmentScreenState();
}

class _PostVisitAssessmentScreenState extends ConsumerState<PostVisitAssessmentScreen> {
  final List<int?> _answers = List<int?>.filled(pss4Items.length, null);
  int _quietScore = 5;
  bool _submitting = false;

  final List<String> _optionLabels = const [
    '0 - Never',
    '1 - Almost Never',
    '2 - Sometimes',
    '3 - Fairly Often',
    '4 - Very Often',
  ];

  bool get _isComplete => _answers.every((a) => a != null);

  @override
  Widget build(BuildContext context) {
    final spaces = ref.watch(greenSpacesProvider);
    final space = spaces.firstWhere(
      (s) => s.id == widget.spaceId,
      orElse: () => spaces.first,
    );
    final active = ref.watch(activeVisitProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const EcoWellAppBar(
        title: 'Post-Visit Stress Assessment',
        showBack: true,
        showNotifications: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Space & Duration summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.mintLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.mintSoft),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Visit Completed at ${space.name}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.forestDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Let\'s measure how your stress levels changed after this nature session.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Quiet Score Rating for this visit
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How peaceful was this green space today?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Your Quiet Score feedback helps fellow nature seekers.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final score = index + 1;
                            final isSelected = score <= _quietScore;
                            return GestureDetector(
                              onTap: () => setState(() => _quietScore = score),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(
                                  isSelected ? Icons.star : Icons.star_border,
                                  color: AppColors.goldStar,
                                  size: 34,
                                ),
                              ),
                            );
                          }),
                        ),
                        Center(
                          child: Text(
                            '$_quietScore / 5 Quiet Rating',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.forestDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Right now, how do you feel...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.forestDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // PSS-4 Questionnaire Items
                  ...List.generate(pss4Items.length, (qIndex) {
                    final item = pss4Items[qIndex];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _answers[qIndex] != null ? AppColors.inputBorder : AppColors.cardBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 11,
                                backgroundColor: AppColors.forestDark,
                                child: Text(
                                  '${qIndex + 1}',
                                  style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.text,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Radio choices
                          ...List.generate(5, (optIndex) {
                            final isSelected = _answers[qIndex] == optIndex;
                            return GestureDetector(
                              onTap: () {
                                setState(() => _answers[qIndex] = optIndex);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.mintLight : AppColors.inputFill,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? AppColors.mintGreen : AppColors.cardBorder,
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                      color: isSelected ? AppColors.primaryGreen : AppColors.textTertiary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _optionLabels[optIndex],
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? AppColors.forestDark : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Submit Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isComplete && !_submitting
                      ? () async {
                          setState(() => _submitting = true);
                          final postAnswers = _answers.map((a) => a!).toList();
                          final preScore = active?.preScore ?? 12;
                          final postScore = computePss4Score(postAnswers);
                          final reduction = stressReductionScore(preScore, postScore);

                          final visit = Visit(
                            id: 'visit-${DateTime.now().millisecondsSinceEpoch}',
                            greenSpaceId: space.id,
                            greenSpaceName: space.name,
                            latitude: space.latitude,
                            longitude: space.longitude,
                            startTime: DateTime.now().subtract(const Duration(minutes: 35)),
                            endTime: DateTime.now(),
                            preScore: preScore,
                            postScore: postScore,
                            stressReduction: reduction,
                            quietRating: _quietScore,
                            preAnswers: active?.preAnswers ?? [3, 3, 3, 3],
                            postAnswers: postAnswers,
                          );

                          await ref.read(visitsProvider.notifier).addVisit(visit);
                          ref.read(activeVisitProvider.notifier).clear();

                          if (!context.mounted) return;
                          context.pushReplacement(
                            '/stress-result?pre=$preScore&post=$postScore&reduction=$reduction&spaceName=${Uri.encodeComponent(space.name)}',
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    _isComplete ? 'Save Visit & Calculate Score' : 'Complete All Questions (${_answers.where((a) => a != null).length}/4)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
