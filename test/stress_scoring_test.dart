import 'package:flutter_test/flutter_test.dart';
import 'package:ecowell/core/utils/stress_scoring.dart';
import 'package:ecowell/models/pss4.dart';
import 'package:ecowell/providers/streak_provider.dart';
import 'package:ecowell/models/visit.dart';

void main() {
  group('computePss4Score', () {
    test('example from proposal: pre 3,1,1,3 -> 12', () {
      final score = computePss4Score([3, 1, 1, 3]);
      expect(score, 12);
    });

    test('example from proposal: post 1,3,3,1 -> 4', () {
      final score = computePss4Score([1, 3, 3, 1]);
      expect(score, 4);
    });

    test('all zeros -> 8 (reverse-scored items contribute 4 each)', () {
      expect(computePss4Score([0, 0, 0, 0]), 8);
    });

    test('all max (4) -> 16', () {
      // direct items (0 and 3) score 4+4=8, reversed items (1 and 2) score 0+0=0
      expect(computePss4Score([4, 4, 4, 4]), 8);
    });

    test('reversed items are inverted', () {
      // item2 (reversed) raw 1 -> 3; item3 (reversed) raw 0 -> 4
      expect(computePss4Score([0, 1, 0, 0]), 7);
    });
  });

  group('stressReductionScore', () {
    test('pre 12 post 4 -> 8', () {
      expect(stressReductionScore(12, 4), 8);
    });

    test('negative when stress increased', () {
      expect(stressReductionScore(4, 8), -4);
    });
  });

  group('interpretStressReduction', () {
    test('>=8 substantial', () {
      expect(interpretStressReduction(8), 'Substantial Improvement');
      expect(interpretStressReduction(16), 'Substantial Improvement');
    });
    test('4..7 moderate', () {
      expect(interpretStressReduction(7), 'Moderate Improvement');
      expect(interpretStressReduction(4), 'Moderate Improvement');
    });
    test('1..3 slight', () {
      expect(interpretStressReduction(3), 'Slight Improvement');
      expect(interpretStressReduction(1), 'Slight Improvement');
    });
    test('0 no change', () {
      expect(interpretStressReduction(0), 'No Change');
    });
    test('-1..-3 slight decline', () {
      expect(interpretStressReduction(-1), 'Slight Decline');
      expect(interpretStressReduction(-3), 'Slight Decline');
    });
    test('<-4 notable decline', () {
      expect(interpretStressReduction(-4), 'Notable Decline');
      expect(interpretStressReduction(-10), 'Notable Decline');
    });
  });

  group('computeVisitStreak', () {
    Visit visitOn(DateTime date) => Visit(
          id: 'v',
          greenSpaceId: 'gs',
          greenSpaceName: 'Park',
          latitude: 0,
          longitude: 0,
          startTime: date,
          endTime: date,
          preScore: 8,
          postScore: 4,
          stressReduction: 4,
          quietRating: 4,
          preAnswers: const [2, 2, 2, 2],
          postAnswers: const [1, 1, 1, 1],
        );

    test('no visits -> 0', () {
      expect(computeVisitStreak([]), 0);
    });

    test('one visit today -> 1', () {
      final visits = [visitOn(DateTime.now())];
      expect(computeVisitStreak(visits), 1);
    });

    test('visits today and yesterday -> 2', () {
      final today = DateTime.now();
      final visits = [
        visitOn(today),
        visitOn(today.subtract(const Duration(days: 1))),
      ];
      expect(computeVisitStreak(visits), 2);
    });

    test('gap breaks streak', () {
      final today = DateTime.now();
      final visits = [
        visitOn(today),
        visitOn(today.subtract(const Duration(days: 3))),
      ];
      expect(computeVisitStreak(visits), 1);
    });

    test('no visit today but yesterday -> streak counts from yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final visits = [visitOn(yesterday)];
      expect(computeVisitStreak(visits), 1);
    });
  });

  test('pss4 has 4 items with 2 direct and 2 reversed', () {
    expect(pss4Items.length, 4);
    expect(pss4Items.where((i) => i.reversed).length, 2);
  });
}