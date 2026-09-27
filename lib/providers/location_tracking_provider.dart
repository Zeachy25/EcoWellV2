import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/location_tracking_service.dart';

final locationTrackingServiceProvider = Provider<LocationTrackingService>((
  ref,
) {
  final service = LocationTrackingService();
  ref.onDispose(service.dispose);
  return service;
});
