import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/walk_record.dart';

class WalksController extends Notifier<List<WalkRecord>> {
  @override
  List<WalkRecord> build() => [];

  void addRecord(WalkRecord record) {
    state = [record, ...state];
  }
}

final walksProvider =
    NotifierProvider<WalksController, List<WalkRecord>>(WalksController.new);