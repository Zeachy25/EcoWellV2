import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/visit.dart';
import 'app_providers.dart';

final sampleSeedVisits = <Visit>[
  Visit(
    id: 'visit-seed-1',
    greenSpaceId: 'gs-001',
    greenSpaceName: 'Guang-guang Mangrove Park & Nursery',
    latitude: 6.9009,
    longitude: 126.2685,
    startTime: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    endTime: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
    preScore: 12,
    postScore: 5,
    stressReduction: 7,
    quietRating: 5,
    preAnswers: [3, 3, 3, 3],
    postAnswers: [1, 2, 1, 1],
  ),
  Visit(
    id: 'visit-seed-2',
    greenSpaceId: 'gs-002',
    greenSpaceName: 'Dahican Beach',
    latitude: 6.9091,
    longitude: 126.2657,
    startTime: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
    endTime: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
    preScore: 10,
    postScore: 4,
    stressReduction: 6,
    quietRating: 4,
    preAnswers: [3, 2, 3, 2],
    postAnswers: [1, 1, 1, 1],
  ),
  Visit(
    id: 'visit-seed-3',
    greenSpaceId: 'gs-005',
    greenSpaceName: 'Pujada Bay Lookout',
    latitude: 6.9390,
    longitude: 126.2750,
    startTime: DateTime.now().subtract(const Duration(days: 3, hours: 5)),
    endTime: DateTime.now().subtract(const Duration(days: 3, hours: 4)),
    preScore: 11,
    postScore: 6,
    stressReduction: 5,
    quietRating: 5,
    preAnswers: [3, 3, 2, 3],
    postAnswers: [2, 1, 2, 1],
  ),
  Visit(
    id: 'visit-seed-4',
    greenSpaceId: 'gs-008',
    greenSpaceName: 'Mayo Bay Park',
    latitude: 6.9300,
    longitude: 126.2820,
    startTime: DateTime.now().subtract(const Duration(days: 4, hours: 6)),
    endTime: DateTime.now().subtract(const Duration(days: 4, hours: 5)),
    preScore: 9,
    postScore: 4,
    stressReduction: 5,
    quietRating: 4,
    preAnswers: [2, 3, 2, 2],
    postAnswers: [1, 1, 1, 1],
  ),
  Visit(
    id: 'visit-seed-5',
    greenSpaceId: 'gs-001',
    greenSpaceName: 'Guang-guang Mangrove Park & Nursery',
    latitude: 6.9009,
    longitude: 126.2685,
    startTime: DateTime.now().subtract(const Duration(days: 5, hours: 3)),
    endTime: DateTime.now().subtract(const Duration(days: 5, hours: 2)),
    preScore: 13,
    postScore: 5,
    stressReduction: 8,
    quietRating: 5,
    preAnswers: [3, 4, 3, 3],
    postAnswers: [1, 2, 1, 1],
  ),
];

class VisitsController extends AsyncNotifier<List<Visit>> {
  @override
  Future<List<Visit>> build() async {
    final visits = ref.watch(localStoreProvider).getVisits();
    if (visits.isEmpty) {
      return sampleSeedVisits;
    }
    return List<Visit>.of(visits)..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  Future<void> addVisit(Visit visit) async {
    final store = ref.read(localStoreProvider);
    final current = [visit, ...?state.value]
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    state = AsyncData(current);
    await store.saveVisits(current);
  }
}

final visitsProvider =
    AsyncNotifierProvider<VisitsController, List<Visit>>(VisitsController.new);