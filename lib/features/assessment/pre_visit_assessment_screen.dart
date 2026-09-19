import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/pss4.dart';
import '../../providers/active_visit_provider.dart';
import '../../providers/app_providers.dart';
import '../shared/ecowell_app_bar.dart';

class PreVisitAssessmentScreen extends ConsumerStatefulWidget {
  final String spaceId;

  const PreVisitAssessmentScreen({super.key, required this.spaceId});

  @override
  ConsumerState<PreVisitAssessmentScreen> createState() => _PreVisitAssessmentScreenState();
}

class _PreVisitAssessmentScreenState extends ConsumerState<PreVisitAssessmentScreen> {
  final List<int?> _answers = List<int?>.filled(pss4Items.length, null);
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const EcoWellAppBar(
        title: 'Pre-Visit Stress Assessment',
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
                  // Green space info card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.mintLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.mintSoft),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.nature_people_rounded, color: AppColors.forestDark, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                space.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.forestDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Baseline stress check before entering nature',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'In the last month, how often have you felt...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
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
                          // Radio options
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

            // Bottom CTA: "Begin My Visit"
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
                          final answers = _answers.map((a) => a!).toList();
                          final controller = ref.read(activeVisitProvider.notifier);
                          controller.beginVisit(space);
                          controller.savePreAssessment(answers);

                          if (mounted) {
                            context.pushReplacement('/active-visit');
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    _isComplete ? 'Begin My Visit' : 'Complete All 4 Questions (${_answers.where((a) => a != null).length}/4)',
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
