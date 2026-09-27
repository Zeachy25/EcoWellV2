import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/utils/geo.dart';

class RouteMatch {
  const RouteMatch({
    required this.segmentIndex,
    required this.segmentFraction,
    required this.snappedPoint,
    required this.distanceToRouteMeters,
    required this.distanceAlongRouteMeters,
    required this.routeDistanceMeters,
    required this.remainingDistanceMeters,
    required this.progress,
    required this.bearingDegrees,
  });

  final int segmentIndex;
  final double segmentFraction;
  final LatLng snappedPoint;
  final double distanceToRouteMeters;
  final double distanceAlongRouteMeters;
  final double routeDistanceMeters;
  final double remainingDistanceMeters;
  final double progress;
  final double bearingDegrees;
}

class RouteMatcher {
  RouteMatcher(List<LatLng> points, {double? routeDistanceMeters})
    : _points = List<LatLng>.unmodifiable(points),
      _routeDistanceMeters =
          routeDistanceMeters != null && routeDistanceMeters > 0
          ? routeDistanceMeters
          : _geometryDistance(points);

  final List<LatLng> _points;
  final double _routeDistanceMeters;
  late final List<double> _cumulativeDistances = _buildCumulativeDistances();

  List<LatLng> get points => _points;
  double get routeDistanceMeters => _routeDistanceMeters;

  RouteMatch? match(LatLng position, {RouteMatch? previous}) {
    if (_points.length < 2) return null;

    RouteMatch? local;
    if (previous != null && previous.segmentIndex < _points.length - 1) {
      final start = math.max(0, previous.segmentIndex - 8);
      final end = math.min(_points.length - 2, previous.segmentIndex + 30);
      local = _nearest(position, start, end);
    }

    if (local != null &&
        local.distanceToRouteMeters <=
            math.max(80, previous!.distanceToRouteMeters + 60)) {
      return local;
    }

    final global = _nearest(position, 0, _points.length - 2);
    if (global == null) return local;
    if (local != null &&
        global.distanceAlongRouteMeters - local.distanceAlongRouteMeters >
            100) {
      return local;
    }
    return global;
  }

  RouteMatch? _nearest(LatLng position, int start, int end) {
    RouteMatch? best;
    for (var index = start; index <= end; index++) {
      final first = _points[index];
      final second = _points[index + 1];
      final projected = _project(position, first, second);
      final candidate = RouteMatch(
        segmentIndex: index,
        segmentFraction: projected.fraction,
        snappedPoint: projected.point,
        distanceToRouteMeters: distanceMeters(
          position.latitude,
          position.longitude,
          projected.point.latitude,
          projected.point.longitude,
        ),
        distanceAlongRouteMeters:
            _cumulativeDistances[index] +
            _segmentDistance(first, second) * projected.fraction,
        routeDistanceMeters: _routeDistanceMeters,
        remainingDistanceMeters: 0,
        progress: 0,
        bearingDegrees: _segmentBearing(first, second),
      );
      if (best == null ||
          candidate.distanceToRouteMeters < best.distanceToRouteMeters) {
        best = candidate.copyWith(
          remainingDistanceMeters: math.max(
            0,
            _routeDistanceMeters - candidate.distanceAlongRouteMeters,
          ),
          progress: _routeDistanceMeters <= 0
              ? 1
              : (candidate.distanceAlongRouteMeters / _routeDistanceMeters)
                    .clamp(0.0, 1.0)
                    .toDouble(),
        );
      }
    }
    return best;
  }

  _Projection _project(LatLng point, LatLng first, LatLng second) {
    final referenceLatitude =
        (first.latitude + second.latitude + point.latitude) / 3;
    final latitudeScale = 111320.0;
    final longitudeScale =
        111320.0 * math.cos(referenceLatitude * math.pi / 180.0);
    final ax = (first.longitude * longitudeScale);
    final ay = (first.latitude * latitudeScale);
    final bx = (second.longitude * longitudeScale);
    final by = (second.latitude * latitudeScale);
    final px = point.longitude * longitudeScale;
    final py = point.latitude * latitudeScale;
    final dx = bx - ax;
    final dy = by - ay;
    final lengthSquared = dx * dx + dy * dy;
    if (lengthSquared <= 0) return _Projection(0, first);
    final fraction = (((px - ax) * dx + (py - ay) * dy) / lengthSquared)
        .clamp(0.0, 1.0)
        .toDouble();
    return _Projection(
      fraction,
      LatLng(
        first.latitude + (second.latitude - first.latitude) * fraction,
        first.longitude + (second.longitude - first.longitude) * fraction,
      ),
    );
  }

  List<double> _buildCumulativeDistances() {
    final cumulative = List<double>.filled(_points.length, 0);
    for (var index = 1; index < _points.length; index++) {
      cumulative[index] =
          cumulative[index - 1] +
          _segmentDistance(_points[index - 1], _points[index]);
    }
    return cumulative;
  }

  double _segmentDistance(LatLng first, LatLng second) {
    return distanceMeters(
      first.latitude,
      first.longitude,
      second.latitude,
      second.longitude,
    );
  }

  double _segmentBearing(LatLng first, LatLng second) {
    final latitude1 = first.latitude * math.pi / 180;
    final latitude2 = second.latitude * math.pi / 180;
    final deltaLongitude = (second.longitude - first.longitude) * math.pi / 180;
    final y = math.sin(deltaLongitude) * math.cos(latitude2);
    final x =
        math.cos(latitude1) * math.sin(latitude2) -
        math.sin(latitude1) * math.cos(latitude2) * math.cos(deltaLongitude);
    return normalizeBearing(math.atan2(y, x) * 180 / math.pi);
  }

  static double _geometryDistance(List<LatLng> points) {
    var total = 0.0;
    for (var index = 1; index < points.length; index++) {
      total += distanceMeters(
        points[index - 1].latitude,
        points[index - 1].longitude,
        points[index].latitude,
        points[index].longitude,
      );
    }
    return total;
  }
}

class _Projection {
  const _Projection(this.fraction, this.point);

  final double fraction;
  final LatLng point;
}

extension on RouteMatch {
  RouteMatch copyWith({double? remainingDistanceMeters, double? progress}) {
    return RouteMatch(
      segmentIndex: segmentIndex,
      segmentFraction: segmentFraction,
      snappedPoint: snappedPoint,
      distanceToRouteMeters: distanceToRouteMeters,
      distanceAlongRouteMeters: distanceAlongRouteMeters,
      routeDistanceMeters: routeDistanceMeters,
      remainingDistanceMeters:
          remainingDistanceMeters ?? this.remainingDistanceMeters,
      progress: progress ?? this.progress,
      bearingDegrees: bearingDegrees,
    );
  }
}

double normalizeBearing(double value) {
  final normalized = value % 360;
  return normalized < 0 ? normalized + 360 : normalized;
}

List<LatLng> completedRoutePoints(List<LatLng> routePoints, RouteMatch match) {
  final result = <LatLng>[];
  for (var index = 0; index <= match.segmentIndex; index++) {
    result.add(routePoints[index]);
  }
  result.add(match.snappedPoint);
  return result;
}

List<LatLng> remainingRoutePoints(List<LatLng> routePoints, RouteMatch match) {
  final result = <LatLng>[match.snappedPoint];
  for (
    var index = match.segmentIndex + 1;
    index < routePoints.length;
    index++
  ) {
    result.add(routePoints[index]);
  }
  return result;
}
