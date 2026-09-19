import '../../models/pss4.dart';

int computePss4Score(List<int> rawAnswers) {
  var total = 0;
  for (var i = 0; i < pss4Items.length; i++) {
    final raw = rawAnswers[i];
    total += pss4Items[i].reversed ? 4 - raw : raw;
  }
  return total;
}

int stressReductionScore(int preScore, int postScore) => preScore - postScore;

String interpretStressReduction(int score) {
  if (score >= 8) return 'Substantial Improvement';
  if (score >= 4) return 'Moderate Improvement';
  if (score >= 1) return 'Slight Improvement';
  if (score == 0) return 'No Change';
  if (score >= -3) return 'Slight Decline';
  return 'Notable Decline';
}

String describeStressReduction(int score) {
  if (score >= 8) {
    return 'Marked reduction in perceived stress after the activity.';
  }
  if (score >= 4) {
    return 'Noticeable reduction in perceived stress.';
  }
  if (score >= 1) {
    return 'Small but positive change in perceived stress.';
  }
  if (score == 0) {
    return 'No measurable difference before and after the activity.';
  }
  if (score >= -3) {
    return 'Perceived stress increased slightly after the activity.';
  }
  return 'Marked increase in perceived stress after the activity.';
}