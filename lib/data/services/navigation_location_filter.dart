import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../../core/utils/geo.dart';

class NavigationLocationFilterConfig {
  const NavigationLocationFilterConfig({
    this.maxAccuracyMeters = 65,
    this.maxJumpMeters = 80,
    this.maxSpeedMetersPerSecond = 18,
    this.maxTimestampAge = const Duration(seconds: 90),
    this.maxHeadingAccuracyDegrees = 45,
    this.minHeadingSpeedMetersPerSecond = 0.8,
    this.maxHeadingFlipDegrees = 120,
    this.headingStaleAfter = const Duration(seconds: 5),
    this.positionSmoothingFactor = 0.7,
    this.headingSmoothingFactor = 0.35,
    this.speedSmoothingFactor = 0.2,
  });

  final double maxAccuracyMeters;
  final double maxJumpMeters;
  final double maxSpeedMetersPerSecond;
  final Duration maxTimestampAge;
  final double maxHeadingAccuracyDegrees;
  final double minHeadingSpeedMetersPerSecond;
  final double maxHeadingFlipDegrees;
  final Duration headingStaleAfter;
  final double positionSmoothingFactor;
  final double headingSmoothingFactor;
  final double speedSmoothingFactor;
}

class NavigationLocation {
  const NavigationLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.speedMetersPerSecond,
    required this.headingDegrees,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final double speedMetersPerSecond;
  final double? headingDegrees;
  final DateTime timestamp;
}

class NavigationLocationFilter {
  NavigationLocationFilter({NavigationLocationFilterConfig? config})
    : _config = config ?? const NavigationLocationFilterConfig();

  final NavigationLocationFilterConfig _config;
  NavigationLocation? _lastAccepted;
  DateTime? _lastTimestamp;
  double? _heading;
  double? _flipCandidate;
  DateTime? _lastHeadingAcceptedAt;
  double? _speed;

  NavigationLocation? get lastAccepted => _lastAccepted;

  NavigationLocation? add(Position position) {
    if (!_validPosition(position)) return null;

    final timestamp = position.timestamp;
    if (_lastTimestamp != null && !timestamp.isAfter(_lastTimestamp!)) {
      return null;
    }

    final previous = _lastAccepted;
    if (previous != null) {
      final elapsedSeconds =
          timestamp.difference(previous.timestamp).inMilliseconds / 1000;
      if (elapsedSeconds <= 0) return null;
      final movement = distanceMeters(
        previous.latitude,
        previous.longitude,
        position.latitude,
        position.longitude,
      );
      final allowedMovement =
          _config.maxJumpMeters +
          _config.maxSpeedMetersPerSecond * elapsedSeconds +
          math.max(position.accuracy, previous.accuracyMeters) * 0.75;
      if (movement > allowedMovement) return null;
    }

    _lastTimestamp = timestamp;
    final smoothing = _config.positionSmoothingFactor.clamp(0.0, 1.0);
    final latitude = previous == null
        ? position.latitude
        : previous.latitude +
              (position.latitude - previous.latitude) * smoothing;
    final longitude = previous == null
        ? position.longitude
        : previous.longitude +
              (position.longitude - previous.longitude) * smoothing;

    final speed = _smoothSpeed(position.speed);
    final heading = _smoothHeading(
      position.heading,
      position.headingAccuracy,
      position.speed,
    );

    final result = NavigationLocation(
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: math.max(0, position.accuracy),
      speedMetersPerSecond: speed,
      headingDegrees: heading,
      timestamp: timestamp,
    );
    _lastAccepted = result;
    return result;
  }

  void reset() {
    _lastAccepted = null;
    _lastTimestamp = null;
    _heading = null;
    _flipCandidate = null;
    _lastHeadingAcceptedAt = null;
    _speed = null;
  }

  bool _validPosition(Position position) {
    if (!position.latitude.isFinite ||
        !position.longitude.isFinite ||
        position.latitude < -90 ||
        position.latitude > 90 ||
        position.longitude < -180 ||
        position.longitude > 180) {
      return false;
    }
    if (!position.accuracy.isFinite ||
        position.accuracy < 0 ||
        position.accuracy > _config.maxAccuracyMeters) {
      return false;
    }
    final age = DateTime.now().difference(position.timestamp);
    if (age > _config.maxTimestampAge || age < -_config.maxTimestampAge) {
      return false;
    }
    return true;
  }

  double _smoothSpeed(double rawSpeed) {
    if (!rawSpeed.isFinite || rawSpeed < 0 || rawSpeed > 30) {
      return _speed ?? 0;
    }
    final factor = _config.speedSmoothingFactor.clamp(0.0, 1.0);
    _speed = _speed == null
        ? rawSpeed
        : _speed! + (rawSpeed - _speed!) * factor;
    return _speed!;
  }

  double? _smoothHeading(
    double rawHeading,
    double rawAccuracy,
    double rawSpeed,
  ) {
    final now = DateTime.now();
    final moving =
        rawSpeed.isFinite && rawSpeed >= _config.minHeadingSpeedMetersPerSecond;
    if (!moving) {
      final lastRate = _lastHeadingAcceptedAt;
      if (lastRate != null &&
          now.difference(lastRate) > _config.headingStaleAfter) {
        _heading = null;
        _flipCandidate = null;
      }
      return _heading;
    }

    final rawValid =
        rawHeading.isFinite &&
        rawHeading >= 0 &&
        rawHeading <= 360 &&
        rawAccuracy.isFinite &&
        rawAccuracy >= 0 &&
        rawAccuracy <= _config.maxHeadingAccuracyDegrees;
    if (!rawValid) return _heading;

    final target = _normalizeBearing(rawHeading);
    final previous = _heading;
    if (previous == null) {
      _heading = target;
      _flipCandidate = null;
      _lastHeadingAcceptedAt = now;
      return _heading;
    }

    final delta = _angleDelta(previous, target).abs();
    if (delta > _config.maxHeadingFlipDegrees) {
      final pending = _flipCandidate;
      if (pending == null) {
        _flipCandidate = target;
        return _heading;
      }
      if (_angleDelta(pending, target).abs() <= _config.maxHeadingFlipDegrees) {
        _heading = target;
        _flipCandidate = null;
        _lastHeadingAcceptedAt = now;
        return _heading;
      }
      return _heading;
    }

    _flipCandidate = null;
    final factor = _config.headingSmoothingFactor.clamp(0.0, 1.0);
    _heading = _normalizeBearing(previous + _angleDelta(previous, target) * factor);
    _lastHeadingAcceptedAt = now;
    return _heading;
  }

  double _angleDelta(double from, double to) {
    return ((to - from + 540) % 360) - 180;
  }

  double _normalizeBearing(double value) {
    final normalized = value % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }
}
