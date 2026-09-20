import 'dart:async';

import '../../core/utils/geo.dart' as geo;
import '../../models/green_space.dart';
import '../../models/walk_record.dart';

/// Stateful GPS activity tracker responsible for distance, pace, splits,
/// elevation, calorie, and arrival detection while recording a walk/run.
class WalkTracker {
  static const double _minMoveSpeedMps = 0.5;
  static const double _minSegmentMeters = 2.0;

  GreenSpace? _destination;
  WalkActivityType _activityType = WalkActivityType.walk;
  StreamSubscription<GeoPoint>? _subscription;
  Timer? _timer;

  final List<GeoPoint> _path = [];
  final List<ActivitySplit> _splits = [];

  DateTime? _startedAt;
  DateTime? _endedAt;
  DateTime? _lastFixAt;
  DateTime? _movingStart;
  Duration _accumulatedMoving = Duration.zero;
  GeoPoint? _last;
  GeoPoint? _splitStart;
  double _distanceMeters = 0;
  double _splitElevation = 0;
  double _elevationGainMeters = 0;
  int _currentPaceSecondsPerKm = 0;
  int _nextSplitNumber = 1;
  bool _isPaused = false;
  bool _arrived = false;
  bool _disposed = false;

  /// Called on every new position fix.
  void Function(GeoPoint point)? onPosition;

  /// Called once when the user enters the destination arrival zone.
  void Function(GreenSpace destination)? onArrived;

  /// Called when a kilometer split is completed.
  void Function(ActivitySplit split)? onSplitCompleted;

  /// Called whenever tracker state (pause/resume) changes.
  void Function()? onStatusChanged;

  double get distanceMeters => _distanceMeters;

  double get elevationGainMeters => _elevationGainMeters;

  int get caloriesBurned => _estimateCalories();

  int get currentPaceSecondsPerKm => _currentPaceSecondsPerKm;

  bool get isPaused => _isPaused;

  bool get isTracking => _subscription != null;

  List<GeoPoint> get path => List.unmodifiable(_path);

  List<ActivitySplit> get splits => List.unmodifiable(_splits);

  Duration get movingDuration {
    if (_isPaused) return _accumulatedMoving;
    if (_movingStart != null) {
      return _accumulatedMoving + (DateTime.now().difference(_movingStart!));
    }
    return _accumulatedMoving;
  }

  int get avgPaceSecondsPerKm {
    final distKm = _distanceMeters / 1000;
    if (distKm <= 0) return 0;
    return (movingDuration.inSeconds / distKm).round();
  }

  void start(
    GreenSpace? destination, {
    required WalkActivityType activityType,
    required Stream<GeoPoint> positionStream,
    GeoPoint? initial,
  }) {
    _destination = destination;
    _activityType = activityType;
    _startedAt = DateTime.now();
    _movingStart = DateTime.now();

    if (initial != null && _path.isEmpty) {
      _onFix(initial);
    }

    _subscription = positionStream.listen(_onFix, onError: (Object _) {});

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      onStatusChanged?.call();
    });
  }

  void _onFix(GeoPoint p) {
    if (_disposed || _isPaused) return;

    final now = DateTime.now();
    final previous = _last;

    if (previous != null) {
      final segMeters = geo.distanceMeters(
        previous.latitude,
        previous.longitude,
        p.latitude,
        p.longitude,
      );
      final dt = now.difference(_lastFixAt!).inSeconds;
      if (dt > 0) {
        final speedMps = segMeters / dt;
        final isMoving = speedMps >= _minMoveSpeedMps;
        if (isMoving) {
          _movingStart ??= now;
        } else if (_movingStart != null) {
          _accumulatedMoving += now.difference(_movingStart!);
          _movingStart = null;
        }

        // Only count real movement: fast enough and clear of GPS noise.
        if (isMoving && segMeters >= _minSegmentMeters) {
          _distanceMeters += segMeters;
          _currentPaceSecondsPerKm = (dt / (segMeters / 1000)).round();

          final altDelta = p.altitude - previous.altitude;
          if (altDelta > 0 && altDelta.isFinite) {
            _elevationGainMeters += altDelta;
          }

          _path.add(p);
          onPosition?.call(p);
          _checkSplit(p, now);
        }
      }
    } else {
      _movingStart = now;
      _path.add(p);
      onPosition?.call(p);
    }

    _last = p;
    _lastFixAt = now;

    _checkArrival(p);

    if (_disposed) return;
  }

  void _checkArrival(GeoPoint p) {
    final destination = _destination;
    if (destination == null || _arrived) return;
    final dist = geo.distanceMeters(
      destination.latitude,
      destination.longitude,
      p.latitude,
      p.longitude,
    );
    if (dist <= 500) {
      _arrived = true;
      onArrived?.call(destination);
    }
  }

  void _checkSplit(GeoPoint p, DateTime now) {
    final splitStart = _splitStart;
    if (splitStart == null) {
      _splitStart = p;
      _splitElevation = 0;
    } else {
      final altDelta = p.altitude - splitStart.altitude;
      if (altDelta > 0 && altDelta.isFinite) {
        _splitElevation += altDelta;
      }
    }

    final splitTarget = _nextSplitNumber * 1000.0;
    if (_distanceMeters >= splitTarget) {
      final currentSplitStart = _splitStart!;
      final splitDuration = now.difference(currentSplitStart.timestamp);
      final splitDistance = _distanceMeters - (splitTarget - 1000);
      final pace = _distanceMeters > 0
          ? (splitDuration.inSeconds / (splitDistance / 1000)).round()
          : 0;

      final split = ActivitySplit(
        splitNumber: _nextSplitNumber,
        duration: splitDuration,
        distanceMeters: splitDistance,
        avgPaceSecondsPerKm: pace,
        elevationGainMeters: _splitElevation,
      );
      _splits.add(split);
      _nextSplitNumber++;
      _splitStart = p;
      _splitElevation = 0;
      onSplitCompleted?.call(split);
    }
  }

  int _estimateCalories() {
    const weightKg = 70.0;
    final met = switch (_activityType) {
      WalkActivityType.walk => 3.5,
      WalkActivityType.run => 9.8,
      WalkActivityType.hike => 6.0,
      WalkActivityType.trail => 5.5,
    };
    final hours = movingDuration.inSeconds / 3600.0;
    return (met * weightKg * hours).round();
  }

  void pause() {
    if (_isPaused) return;
    _isPaused = true;
    if (_movingStart != null) {
      _accumulatedMoving += DateTime.now().difference(_movingStart!);
      _movingStart = null;
    }
    _last = null;
    _lastFixAt = null;
    onStatusChanged?.call();
  }

  void resume() {
    if (!_isPaused) return;
    _isPaused = false;
    _movingStart = DateTime.now();
    onStatusChanged?.call();
  }

  WalkRecord? stop({String userId = 'user-1', String activityTitle = ''}) {
    if (_disposed) return null;
    _endedAt = DateTime.now();
    if (_movingStart != null) {
      _accumulatedMoving += _endedAt!.difference(_movingStart!);
      _movingStart = null;
    }
    _subscription?.cancel();
    _subscription = null;
    _timer?.cancel();
    _timer = null;

    if (_path.isEmpty) return null;

    return WalkRecord(
      id: 'walk-${_startedAt!.millisecondsSinceEpoch}',
      userId: userId,
      destination: _destination,
      activityType: _activityType,
      title: activityTitle,
      startedAt: _startedAt!,
      endedAt: _endedAt!,
      movingDuration: _accumulatedMoving,
      path: _path,
      splits: _splits,
      elevationGainMeters: _elevationGainMeters,
      caloriesBurned: caloriesBurned,
      arrived: _arrived,
    );
  }

  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _subscription = null;
    _timer?.cancel();
    _timer = null;
  }
}
