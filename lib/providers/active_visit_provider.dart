import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/notification_service.dart';
import '../core/utils/stress_scoring.dart';
import '../models/green_space.dart';
import '../models/visit.dart';
import 'visits_provider.dart';

class ActiveVisit {
  final String id;
  final GreenSpace greenSpace;
  final DateTime startTime;
  final List<int>? preAnswers;
  final int? preScore;

  const ActiveVisit({
    required this.id,
    required this.greenSpace,
    required this.startTime,
    this.preAnswers,
    this.preScore,
  });

  bool get preCompleted => preScore != null;
}

class ActiveVisitController extends Notifier<ActiveVisit?> {
  @override
  ActiveVisit? build() => null;

  void beginVisit(GreenSpace space) {
    state = ActiveVisit(
      id: 'visit-${DateTime.now().millisecondsSinceEpoch}',
      greenSpace: space,
      startTime: DateTime.now(),
    );
  }

  void savePreAssessment(List<int> answers) {
    final current = state;
    if (current == null) return;
    state = ActiveVisit(
      id: current.id,
      greenSpace: current.greenSpace,
      startTime: current.startTime,
      preAnswers: answers,
      preScore: computePss4Score(answers),
    );
  }

  Future<void> completeVisit({
    required List<int> postAnswers,
    required int quietRating,
  }) async {
    final current = state;
    if (current == null || current.preScore == null) return;
    final postScore = computePss4Score(postAnswers);
    final visit = Visit(
      id: current.id,
      greenSpaceId: current.greenSpace.id,
      greenSpaceName: current.greenSpace.name,
      latitude: current.greenSpace.latitude,
      longitude: current.greenSpace.longitude,
      startTime: current.startTime,
      endTime: DateTime.now(),
      preScore: current.preScore!,
      postScore: postScore,
      stressReduction: stressReductionScore(current.preScore!, postScore),
      quietRating: quietRating,
      preAnswers: current.preAnswers!,
      postAnswers: postAnswers,
    );
    await ref.read(visitsProvider.notifier).addVisit(visit);
    await NotificationService.instance.scheduleFollowUp(
      const Duration(days: 2),
    );
    state = null;
  }

  void cancel() {
    state = null;
  }

  void clear() {
    state = null;
  }
}

final activeVisitProvider =
    NotifierProvider<ActiveVisitController, ActiveVisit?>(ActiveVisitController.new);