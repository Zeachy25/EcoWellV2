import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/responsive.dart';
import '../../core/utils/stress_scoring.dart';
import '../../models/green_space.dart';
import '../../models/pss4.dart';
import '../../providers/active_visit_provider.dart';
import '../../providers/app_providers.dart';

enum AssessmentMode { pre, post }

class AssessmentScreen extends ConsumerStatefulWidget {
  final AssessmentMode mode;
  final String spaceId;

  const AssessmentScreen({
    super.key,
    required this.mode,
    required this.spaceId,
  });

  @override
  ConsumerState<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends ConsumerState<AssessmentScreen> {
  final List<int?> _answers = List<int?>.filled(pss4Items.length, null);
  int? _quietRating;
  bool _submitting = false;
  _Result? _result;

  GreenSpace? get _space {
    for (final space in ref.read(greenSpacesProvider)) {
      if (space.id == widget.spaceId) return space;
    }
    return null;
  }

  bool get _isPre => widget.mode == AssessmentMode.pre;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(activeVisitProvider.notifier);
      final active = ref.read(activeVisitProvider);
      if (_isPre && active == null) {
        final space = _space;
        if (space != null) controller.beginVisit(space);
      }
    });
  }

  bool get _canSubmit {
    if (_answers.any((a) => a == null)) return false;
    if (!_isPre && _quietRating == null) return false;
    return true;
  }

  Future<void> _submit() async {
    if (!_canSubmit || _submitting) return;
    setState(() => _submitting = true);
    final answers = _answers.map((a) => a!).toList();

    if (_isPre) {
      ref.read(activeVisitProvider.notifier).savePreAssessment(answers);
      if (mounted) {
        context.go('/home');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pre-visit stress recorded. Enjoy your time at ${_space?.name ?? 'the green space'}!',
            ),
          ),
        );
      }
    } else {
      final active = ref.read(activeVisitProvider);
      if (active == null || active.preScore == null) {
        if (mounted) {
          context.go('/home');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No active visit found. Please check in first.'),
            ),
          );
        }
        setState(() => _submitting = false);
        return;
      }
      final postScore = computePss4Score(answers);
      final result = _Result(
        preScore: active.preScore!,
        postScore: postScore,
        score: stressReductionScore(active.preScore!, postScore),
      );
      await ref.read(activeVisitProvider.notifier).completeVisit(
            postAnswers: answers,
            quietRating: _quietRating!,
          );
      if (mounted) {
        setState(() {
          _result = result;
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return _ResultView(result: _result!, space: _space);
    }

    final space = _space;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isPre ? 'Pre-Visit Stress Check' : 'Post-Visit Stress Check'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(Responsive.size(context, 20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (space != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.eco, color: Colors.green),
                    title: Text(space.name),
                    subtitle: Text(space.category),
                  ),
                ),
              SizedBox(height: Responsive.size(context, 16)),
              Text(
                _isPre
                    ? 'Rate how you felt during the past week.'
                    : 'Rate how you feel right now after your visit.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: Responsive.size(context, 8)),
              Text(
                'Perceived Stress Scale (PSS-4) - 0 = Never, 4 = Very Often',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              SizedBox(height: Responsive.size(context, 16)),
              for (var i = 0; i < pss4Items.length; i++) ...[
                _QuestionCard(
                  index: i,
                  item: pss4Items[i],
                  selected: _answers[i],
                  onChanged: (value) => setState(() => _answers[i] = value),
                ),
                SizedBox(height: Responsive.size(context, 12)),
              ],
              if (!_isPre) ...[
                SizedBox(height: Responsive.size(context, 8)),
                _QuietScoreSelector(
                  rating: _quietRating,
                  onChanged: (value) => setState(() => _quietRating = value),
                ),
              ],
              SizedBox(height: Responsive.size(context, 24)),
              FilledButton(
                onPressed: _canSubmit && !_submitting ? _submit : null,
                child: _submitting
                    ? SizedBox(
                        height: Responsive.size(context, 20),
                        width: Responsive.size(context, 20),
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isPre ? 'Save Pre-Visit Check' : 'Complete & View Result'),
              ),
              SizedBox(height: Responsive.size(context, 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final Pss4Item item;
  final int? selected;
  final ValueChanged<int> onChanged;

  const _QuestionCard({
    required this.index,
    required this.item,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(Responsive.size(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Q${index + 1}. ${item.text}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: Responsive.size(context, 8)),
            RadioGroup<int>(
              groupValue: selected,
              onChanged: (value) {
                if (value != null) onChanged(value);
              },
              child: Column(
                children: [
                  for (var value = 0; value <= 4; value++)
                    RadioListTile<int>(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      title: Text(
                        '$value - ${pss4ScaleLabels[value]}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      value: value,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuietScoreSelector extends StatelessWidget {
  final int? rating;
  final ValueChanged<int> onChanged;

  const _QuietScoreSelector({required this.rating, required this.onChanged});

  static const _labels = [
    'Very noisy / crowded',
    'Noisy / busy',
    'Moderate',
    'Quiet / peaceful',
    'Very quiet / serene',
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(Responsive.size(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quiet Score',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const Text('How quiet and peaceful did this place feel?'),
            SizedBox(height: Responsive.size(context, 8)),
            RadioGroup<int>(
              groupValue: rating,
              onChanged: (value) {
                if (value != null) onChanged(value);
              },
              child: Column(
                children: [
                  for (var value = 1; value <= 5; value++)
                    RadioListTile<int>(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      title: Text(
                        '$value - ${_labels[value - 1]}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      value: value,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Result {
  final int preScore;
  final int postScore;
  final int score;

  const _Result({
    required this.preScore,
    required this.postScore,
    required this.score,
  });
}

class _ResultView extends StatelessWidget {
  final _Result result;
  final GreenSpace? space;

  const _ResultView({required this.result, required this.space});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final positive = result.score >= 1;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visit Result'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(Responsive.size(context, 24)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                positive ? Icons.emoji_nature : Icons.sentiment_neutral,
                size: Responsive.size(context, 72),
                color: positive ? Colors.green : scheme.tertiary,
              ),
              SizedBox(height: Responsive.size(context, 16)),
              Text(
                'Stress Reduction Score',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: Responsive.size(context, 8)),
              Text(
                '${result.score >= 0 ? '+' : ''}${result.score}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: positive ? Colors.green : scheme.error,
                    ),
              ),
              SizedBox(height: Responsive.size(context, 8)),
              Text(
                interpretStressReduction(result.score),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: positive ? Colors.green : scheme.error,
                    ),
              ),
              SizedBox(height: Responsive.size(context, 8)),
              Text(
                describeStressReduction(result.score),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: Responsive.size(context, 24)),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(Responsive.size(context, 16)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ScoreChip(label: 'Pre', value: result.preScore),
                      _ScoreChip(label: 'Post', value: result.postScore),
                      _ScoreChip(label: 'Reduction', value: result.score),
                    ],
                  ),
                ),
              ),
              SizedBox(height: Responsive.size(context, 32)),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String label;
  final int value;

  const _ScoreChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}