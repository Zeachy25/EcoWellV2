import 'dart:async';

import 'package:flutter_compass/flutter_compass.dart';

class DeviceHeadingService {
  DeviceHeadingService() {
    _subscription = FlutterCompass.events?.listen(
      _onEvent,
      onError: (_) {},
      onDone: () {},
    );
  }

  static const Duration _emitInterval = Duration(milliseconds: 66);
  static const double _smoothing = 0.45;

  StreamSubscription<CompassEvent>? _subscription;
  final StreamController<double> _controller =
      StreamController<double>.broadcast();
  double? _smoothed;
  double? _heading;
  bool _available = false;
  DateTime _lastEmittedAt = DateTime.fromMillisecondsSinceEpoch(0);

  Stream<double> get headings => _controller.stream;

  double? get heading => _heading;

  bool get available => _available;

  void _onEvent(CompassEvent event) {
    final raw = event.heading;
    if (raw == null || !raw.isFinite) return;
    _available = true;
    final value = _normalize(raw);
    final previous = _smoothed;
    _smoothed = previous == null ? value : _smoothArc(previous, value);
    _heading = _smoothed;
    final now = DateTime.now();
    if (now.difference(_lastEmittedAt) >= _emitInterval) {
      _lastEmittedAt = now;
      if (!_controller.isClosed) _controller.add(_smoothed!);
    }
  }

  double _smoothArc(double current, double target) {
    final delta = ((target - current + 540) % 360) - 180;
    return _normalize(current + delta * _smoothing);
  }

  double _normalize(double value) => (value % 360 + 360) % 360;

  static double? resolve({
    required bool compassAvailable,
    required double? compassHeading,
    required double? gpsCourseDegrees,
    required double speedMetersPerSecond,
    double minCourseSpeedMetersPerSecond = 0.8,
  }) {
    if (compassAvailable &&
        compassHeading != null &&
        compassHeading.isFinite) {
      return (compassHeading % 360 + 360) % 360;
    }
    if (speedMetersPerSecond >= minCourseSpeedMetersPerSecond &&
        gpsCourseDegrees != null &&
        gpsCourseDegrees.isFinite) {
      return (gpsCourseDegrees % 360 + 360) % 360;
    }
    return null;
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    if (!_controller.isClosed) _controller.close();
  }
}