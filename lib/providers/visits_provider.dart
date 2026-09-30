import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/visit.dart';
import 'app_providers.dart';

class VisitsController extends AsyncNotifier<List<Visit>> {
  @override
  Future<List<Visit>> build() async {
    final visits = ref.watch(localStoreProvider).getVisits();
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