import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/device_heading_service.dart';

final deviceHeadingProvider = Provider<DeviceHeadingService>((ref) {
  final service = DeviceHeadingService();
  ref.onDispose(service.dispose);
  return service;
});