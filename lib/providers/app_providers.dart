import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/notification_service.dart';
import '../core/services/pdf_export_service.dart';
import '../data/local_store.dart';
import '../data/seed_data.dart';
import '../models/app_user.dart';
import '../models/green_space.dart';
import '../models/visit.dart';

final localStoreProvider = Provider<LocalStore>((ref) {
  throw UnimplementedError('localStoreProvider must be overridden in main()');
});

final greenSpacesProvider = Provider<List<GreenSpace>>((ref) => matiGreenSpaces);

class PdfExportController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> run({
    required AppUser user,
    required List<Visit> visits,
  }) async {
    state = true;
    try {
      await PdfExportService().exportVisitSummary(user: user, visits: visits);
    } finally {
      state = false;
    }
  }
}

final pdfExportInProgressProvider =
    NotifierProvider<PdfExportController, bool>(PdfExportController.new);

class DailyReminderController extends Notifier<bool> {
  @override
  bool build() => ref.watch(localStoreProvider).dailyReminderEnabled;

  Future<void> setEnabled(bool value) async {
    await ref.read(localStoreProvider).setDailyReminderEnabled(value);
    state = value;
    if (value) {
      await NotificationService.instance.requestPermission();
      await NotificationService.instance.scheduleDailyReminder();
    } else {
      await NotificationService.instance.cancelAll();
    }
  }
}

final dailyReminderProvider =
    NotifierProvider<DailyReminderController, bool>(
  DailyReminderController.new,
);