import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/utils/geo.dart';
import '../../data/services/location_tracking_service.dart';
import '../../data/services/navigation_location_filter.dart';
import '../../data/services/route_service.dart';
import '../../models/geo_fence.dart';
import '../../models/green_space.dart';
import 'route_progress.dart';

typedef LiveRouteFetcher = OrsRouteFetcher;

enum LiveNavigationPhase {
  idle,
  starting,
  navigating,
  rerouting,
  arrived,
  stopped,
  error,
}

class LiveNavigationConfig {
  const LiveNavigationConfig({
    this.offRouteThresholdMeters = 30,
    this.offRouteConfirmationSeconds = 5,
    this.offRouteConfirmationUpdates = 3,
    this.rerouteCooldown = const Duration(seconds: 8),
    this.arrivalRadiusMeters = 35,
    this.arrivalProgress = 0.95,
  });

  final double offRouteThresholdMeters;
  final int offRouteConfirmationSeconds;
  final int offRouteConfirmationUpdates;
  final Duration rerouteCooldown;
  final double arrivalRadiusMeters;
  final double arrivalProgress;
}

class LiveNavigationState {
  const LiveNavigationState({
    this.phase = LiveNavigationPhase.idle,
    this.position,
    this.route,
    this.fallbackRoute,
    this.routeMatch,
    this.nextStep,
    this.remainingDistanceMeters,
    this.etaSeconds,
    this.distanceToRouteMeters,
    this.progress,
    this.routeLoading = false,
    this.rerouting = false,
    this.offRoute = false,
    this.arrived = false,
    this.message,
    this.errorMessage,
  });

  final LiveNavigationPhase phase;
  final NavigationLocation? position;
  final OrsRoute? route;
  final List<LatLng>? fallbackRoute;
  final RouteMatch? routeMatch;
  final OrsRouteStep? nextStep;
  final double? remainingDistanceMeters;
  final double? etaSeconds;
  final double? distanceToRouteMeters;
  final double? progress;
  final bool routeLoading;
  final bool rerouting;
  final bool offRoute;
  final bool arrived;
  final String? message;
  final String? errorMessage;

  LiveNavigationState copyWith({
    LiveNavigationPhase? phase,
    NavigationLocation? position,
    bool clearPosition = false,
    OrsRoute? route,
    bool clearRoute = false,
    List<LatLng>? fallbackRoute,
    bool clearFallbackRoute = false,
    RouteMatch? routeMatch,
    bool clearRouteMatch = false,
    OrsRouteStep? nextStep,
    bool clearNextStep = false,
    double? remainingDistanceMeters,
    bool clearRemainingDistance = false,
    double? etaSeconds,
    bool clearEta = false,
    double? distanceToRouteMeters,
    bool clearDistanceToRoute = false,
    double? progress,
    bool clearProgress = false,
    bool? routeLoading,
    bool? rerouting,
    bool? offRoute,
    bool? arrived,
    String? message,
    bool clearMessage = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LiveNavigationState(
      phase: phase ?? this.phase,
      position: clearPosition ? null : position ?? this.position,
      route: clearRoute ? null : route ?? this.route,
      fallbackRoute: clearFallbackRoute
          ? null
          : fallbackRoute ?? this.fallbackRoute,
      routeMatch: clearRouteMatch ? null : routeMatch ?? this.routeMatch,
      nextStep: clearNextStep ? null : nextStep ?? this.nextStep,
      remainingDistanceMeters: clearRemainingDistance
          ? null
          : remainingDistanceMeters ?? this.remainingDistanceMeters,
      etaSeconds: clearEta ? null : etaSeconds ?? this.etaSeconds,
      distanceToRouteMeters: clearDistanceToRoute
          ? null
          : distanceToRouteMeters ?? this.distanceToRouteMeters,
      progress: clearProgress ? null : progress ?? this.progress,
      routeLoading: routeLoading ?? this.routeLoading,
      rerouting: rerouting ?? this.rerouting,
      offRoute: offRoute ?? this.offRoute,
      arrived: arrived ?? this.arrived,
      message: message ?? (clearMessage ? null : this.message),
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class LiveNavigationSession {
  LiveNavigationSession({
    required this.destination,
    required this.locationService,
    NavigationLocationFilter? locationFilter,
    LiveNavigationConfig? config,
    LiveRouteFetcher? routeFetcher,
  }) : _locationFilter = locationFilter ?? NavigationLocationFilter(),
       _config = config ?? const LiveNavigationConfig(),
       _routeFetcher =
           routeFetcher ??
           (({
             required double originLat,
             required double originLng,
             required double destLat,
             required double destLng,
           }) => fetchRoute(
             originLat: originLat,
             originLng: originLng,
             destLat: destLat,
             destLng: destLng,
             profile: OrsProfile.footWalking,
             preference: OrsPreference.recommended,
           ));

  final GreenSpace destination;
  final LocationTrackingService locationService;
  final NavigationLocationFilter _locationFilter;
  final LiveNavigationConfig _config;
  final LiveRouteFetcher _routeFetcher;
  final StreamController<LiveNavigationState> _stateController =
      StreamController<LiveNavigationState>.broadcast();

  StreamSubscription<Position>? _positionSubscription;
  LiveNavigationState _state = const LiveNavigationState();
  NavigationLocation? _lastLocation;
  OrsRoute? _route;
  List<LatLng>? _fallbackRoute;
  RouteMatcher? _routeMatcher;
  RouteMatcher? _fallbackMatcher;
  RouteMatch? _lastMatch;
  bool _active = false;
  bool _started = false;
  LocationTrackingLease? _lease;
  bool _initialRouteRequested = false;
  bool _routeRequestInFlight = false;
  bool _arrivalStopStarted = false;
  int _lifecycleSerial = 0;
  int _requestSerial = 0;
  int _offRouteUpdateCount = 0;
  DateTime? _offRouteSince;
  DateTime? _nextRerouteAt;
  double? _smoothedSpeed;
  double? _smoothedEta;

  Stream<LiveNavigationState> get states => _stateController.stream;
  LiveNavigationState get state => _state;

  void _resetForStart() {
    _active = false;
    _started = false;
    _lease = null;
    _arrivalStopStarted = false;
    _initialRouteRequested = false;
    _routeRequestInFlight = false;
    _requestSerial++;
    _route = null;
    _fallbackRoute = null;
    _routeMatcher = null;
    _fallbackMatcher = null;
    _lastMatch = null;
    _lastLocation = null;
    _offRouteUpdateCount = 0;
    _offRouteSince = null;
    _nextRerouteAt = null;
    _smoothedSpeed = null;
    _smoothedEta = null;
    _locationFilter.reset();
    _state = const LiveNavigationState();
  }

  Future<void> start() async {
    if (_started) return;
    final lifecycle = ++_lifecycleSerial;
    _resetForStart();
    _started = true;
    _active = true;
    _arrivalStopStarted = false;
    _emit(
      _state.copyWith(
        phase: LiveNavigationPhase.starting,
        message: 'Acquiring your location…',
      ),
    );

    final acquisition = await locationService.acquireWithLease();
    final lease = acquisition.lease;
    if (!_active || lifecycle != _lifecycleSerial) {
      if (lease != null) await locationService.release(lease);
      return;
    }
    if (acquisition.status != LocationTrackingStatus.started || lease == null) {
      _active = false;
      _started = false;
      _emit(
        _state.copyWith(
          phase: LiveNavigationPhase.error,
          routeLoading: false,
          errorMessage: _statusMessage(acquisition.status),
        ),
      );
      return;
    }

    _lease = lease;
    late final StreamSubscription<Position> subscription;
    subscription = locationService.positions.listen(
      (position) {
        if (identical(_positionSubscription, subscription)) {
          _onPosition(position);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (identical(_positionSubscription, subscription)) {
          _onLocationStreamFailure(subscription);
        }
      },
      onDone: () {
        if (identical(_positionSubscription, subscription)) {
          _onLocationStreamFailure(subscription);
        }
      },
    );
    _positionSubscription = subscription;
    final lastPosition = locationService.lastPosition;
    if (lastPosition != null) _onPosition(lastPosition);
  }

  Future<void> stop({bool emitStopped = true}) async {
    if (!_active && _lease == null && !_started) return;
    final lifecycle = ++_lifecycleSerial;
    final wasArrived = _state.arrived;
    _active = false;
    _started = false;
    _requestSerial++;
    _routeRequestInFlight = false;
    _locationFilter.reset();

    final subscription = _positionSubscription;
    _positionSubscription = null;
    final lease = _lease;
    _lease = null;
    await subscription?.cancel();
    if (lease != null) await locationService.release(lease);

    if (lifecycle != _lifecycleSerial) return;

    _route = null;
    _fallbackRoute = null;
    _routeMatcher = null;
    _fallbackMatcher = null;
    _lastMatch = null;
    _lastLocation = null;
    _offRouteUpdateCount = 0;
    _offRouteSince = null;
    _nextRerouteAt = null;
    _smoothedSpeed = null;
    _smoothedEta = null;

    if (emitStopped && !wasArrived) {
      _emit(const LiveNavigationState(phase: LiveNavigationPhase.stopped));
    }
  }

  void _onPosition(Position position) {
    if (!_active) return;
    final filtered = _locationFilter.add(position);
    if (filtered == null) return;
    _lastLocation = filtered;
    if (filtered.speedMetersPerSecond >= 0.5) {
      _smoothedSpeed = _smoothedSpeed == null
          ? filtered.speedMetersPerSecond
          : _smoothedSpeed! +
                (filtered.speedMetersPerSecond - _smoothedSpeed!) * 0.2;
    } else {
      _smoothedSpeed = 0;
    }
    _emit(_state.copyWith(position: filtered));

    if (!_initialRouteRequested) {
      _initialRouteRequested = true;
      unawaited(_requestRoute(filtered, isReroute: false));
      return;
    }
    if (_routeRequestInFlight) return;
    if (_route != null && _routeMatcher != null) {
      _processRoutePosition(filtered);
    } else if (_fallbackRoute != null) {
      _updateFallbackMetrics(filtered);
    }
  }

  void _onLocationStreamFailure(StreamSubscription<Position> subscription) {
    if (!_active || !identical(_positionSubscription, subscription)) return;
    _emit(
      _state.copyWith(
        phase: LiveNavigationPhase.error,
        errorMessage: 'Location updates stopped unexpectedly.',
      ),
    );
    unawaited(stop(emitStopped: false));
  }

  Future<void> _requestRoute(
    NavigationLocation origin, {
    required bool isReroute,
  }) async {
    if (!_active || _routeRequestInFlight) return;
    _routeRequestInFlight = true;
    final serial = ++_requestSerial;
    _emit(
      _state.copyWith(
        phase: isReroute
            ? LiveNavigationPhase.rerouting
            : LiveNavigationPhase.starting,
        routeLoading: !isReroute,
        rerouting: isReroute,
        clearMessage: isReroute,
        message: isReroute ? 'Finding a new route…' : 'Planning your route…',
      ),
    );

    try {
      final route = await _routeFetcher(
        originLat: origin.latitude,
        originLng: origin.longitude,
        destLat: destination.latitude,
        destLng: destination.longitude,
      );
      if (!_active || serial != _requestSerial) return;
      _routeRequestInFlight = false;

      if (route == null || route.points.length < 2) {
        if (isReroute) {
          _nextRerouteAt = DateTime.now().add(_config.rerouteCooldown);
          _emit(
            _state.copyWith(
              phase: LiveNavigationPhase.navigating,
              routeLoading: false,
              rerouting: false,
              offRoute: true,
              errorMessage: 'Could not refresh the route. Retrying later.',
              clearMessage: true,
            ),
          );
        } else {
          _installFallbackRoute(origin);
        }
        return;
      }

      _route = route;
      _routeMatcher = RouteMatcher(
        route.points,
        routeDistanceMeters: route.distanceMeters,
      );
      _fallbackRoute = null;
      _fallbackMatcher = null;
      _lastMatch = null;
      _offRouteSince = null;
      _offRouteUpdateCount = 0;
      _nextRerouteAt = null;
      _emit(
        _state.copyWith(
          phase: LiveNavigationPhase.navigating,
          route: route,
          clearFallbackRoute: true,
          routeLoading: false,
          rerouting: false,
          offRoute: false,
          clearRouteMatch: true,
          clearNextStep: true,
          clearRemainingDistance: true,
          clearEta: true,
          clearDistanceToRoute: true,
          clearProgress: true,
          clearMessage: true,
          clearError: true,
        ),
      );
      final current = _lastLocation;
      if (current != null) {
        _processRoutePosition(current, checkOffRoute: !isReroute);
      }
    } catch (_) {
      if (!_active || serial != _requestSerial) return;
      _routeRequestInFlight = false;
      if (isReroute) {
        _nextRerouteAt = DateTime.now().add(_config.rerouteCooldown);
        _emit(
          _state.copyWith(
            phase: LiveNavigationPhase.navigating,
            routeLoading: false,
            rerouting: false,
            offRoute: true,
            errorMessage: 'Could not refresh the route. Retrying later.',
            clearMessage: true,
          ),
        );
      } else {
        _installFallbackRoute(origin);
      }
    }
  }

  void _installFallbackRoute(NavigationLocation origin) {
    _fallbackRoute = straightLineRoute(
      originLat: origin.latitude,
      originLng: origin.longitude,
      destLat: destination.latitude,
      destLng: destination.longitude,
    );
    _fallbackMatcher = RouteMatcher(_fallbackRoute!);
    _lastMatch = null;
    _emit(
      _state.copyWith(
        phase: LiveNavigationPhase.navigating,
        routeLoading: false,
        rerouting: false,
        clearRoute: true,
        fallbackRoute: _fallbackRoute,
        clearRouteMatch: true,
        clearNextStep: true,
        clearRemainingDistance: true,
        clearEta: true,
        clearDistanceToRoute: true,
        clearProgress: true,
        offRoute: false,
        clearMessage: true,
        errorMessage: 'Route service unavailable. Showing a direct line.',
      ),
    );
    _updateFallbackMetrics(origin);
  }

  void _processRoutePosition(
    NavigationLocation location, {
    bool checkOffRoute = true,
  }) {
    final route = _route;
    final matcher = _routeMatcher;
    if (route == null || matcher == null) return;
    final match = matcher.match(
      LatLng(location.latitude, location.longitude),
      previous: _lastMatch,
    );
    if (match == null) return;
    _lastMatch = match;

    final offRoute =
        match.distanceToRouteMeters > _config.offRouteThresholdMeters;
    final eta = _calculateEta(match);
    final nextStep = _nextStep(route, match.distanceAlongRouteMeters);
    final arrived = _hasArrived(location, match);
    _emit(
      _state.copyWith(
        phase: arrived
            ? LiveNavigationPhase.arrived
            : LiveNavigationPhase.navigating,
        position: location,
        routeMatch: match,
        nextStep: nextStep,
        clearNextStep: nextStep == null,
        remainingDistanceMeters: match.remainingDistanceMeters,
        etaSeconds: eta,
        distanceToRouteMeters: match.distanceToRouteMeters,
        progress: match.progress,
        offRoute: offRoute,
        arrived: arrived,
        clearError: !offRoute,
        clearMessage: true,
      ),
    );

    if (arrived) {
      unawaited(_stopAfterArrival());
      return;
    }
    if (checkOffRoute) _checkOffRoute(location, offRoute);
  }

  void _checkOffRoute(NavigationLocation location, bool offRoute) {
    if (!offRoute) {
      _offRouteSince = null;
      _offRouteUpdateCount = 0;
      return;
    }
    final now = DateTime.now();
    _offRouteSince ??= now;
    _offRouteUpdateCount++;
    final confirmedFor = now.difference(_offRouteSince!).inSeconds;
    final canRequest = _nextRerouteAt == null || !now.isBefore(_nextRerouteAt!);
    if (confirmedFor >= _config.offRouteConfirmationSeconds &&
        _offRouteUpdateCount >= _config.offRouteConfirmationUpdates &&
        canRequest) {
      unawaited(_requestRoute(location, isReroute: true));
    }
  }

  void _updateFallbackMetrics(NavigationLocation location) {
    final match = _fallbackMatcher?.match(
      LatLng(location.latitude, location.longitude),
      previous: _lastMatch,
    );
    if (match != null) _lastMatch = match;
    final directRemaining = distanceMeters(
      location.latitude,
      location.longitude,
      destination.latitude,
      destination.longitude,
    );
    final remaining = match?.remainingDistanceMeters ?? directRemaining;
    final routeAverageSpeed = 1.3;
    final targetEta = remaining / routeAverageSpeed;
    _smoothedEta = _smoothedEta == null
        ? targetEta
        : _smoothedEta! + (targetEta - _smoothedEta!) * 0.2;
    final arrived = _hasArrived(location, match);
    _emit(
      _state.copyWith(
        phase: arrived
            ? LiveNavigationPhase.arrived
            : LiveNavigationPhase.navigating,
        position: location,
        routeMatch: match,
        clearRouteMatch: match == null,
        nextStep: null,
        clearNextStep: true,
        remainingDistanceMeters: remaining,
        etaSeconds: _smoothedEta,
        distanceToRouteMeters: match?.distanceToRouteMeters,
        clearDistanceToRoute: match == null,
        progress: match?.progress,
        clearProgress: match == null,
        offRoute: false,
        arrived: arrived,
        clearMessage: true,
      ),
    );
    if (arrived) unawaited(_stopAfterArrival());
  }

  double? _calculateEta(RouteMatch match) {
    final route = _route;
    if (route == null) return null;
    final routeBasedEta =
        route.durationSeconds > 0 && match.routeDistanceMeters > 0
        ? route.durationSeconds *
              match.remainingDistanceMeters /
              match.routeDistanceMeters
        : null;
    final speed = _smoothedSpeed;
    final speedBasedEta =
        speed != null && speed >= 0.5 && match.remainingDistanceMeters > 0
        ? match.remainingDistanceMeters / speed
        : null;
    var target = speedBasedEta ?? routeBasedEta;
    if (target == null) return null;
    if (speedBasedEta != null && routeBasedEta != null) {
      target = speedBasedEta * 0.65 + routeBasedEta * 0.35;
    }
    target = target.clamp(30, 14400).toDouble();
    _smoothedEta = _smoothedEta == null
        ? target
        : _smoothedEta! + (target - _smoothedEta!) * 0.25;
    return _smoothedEta;
  }

  OrsRouteStep? _nextStep(OrsRoute route, double distanceAlong) {
    if (route.steps.isEmpty) return null;
    var stepStart = 0.0;
    for (final step in route.steps) {
      final stepEnd = stepStart + step.distanceMeters;
      if (stepEnd >= distanceAlong - 15) return step;
      stepStart = stepEnd;
    }
    return route.steps.last;
  }

  bool _hasArrived(NavigationLocation location, RouteMatch? match) {
    final destinationDistance = distanceMeters(
      location.latitude,
      location.longitude,
      destination.latitude,
      destination.longitude,
    );
    final fence = destination.fence;
    final withinArrivalZone = fence is PolygonFence
        ? true
        : destinationDistance <= _config.arrivalRadiusMeters;
    return fence.contains(location.latitude, location.longitude) &&
        withinArrivalZone &&
        (match == null || match.progress >= _config.arrivalProgress);
  }

  Future<void> _stopAfterArrival() async {
    if (_arrivalStopStarted) return;
    _arrivalStopStarted = true;
    final lifecycle = ++_lifecycleSerial;
    _active = false;
    _started = false;
    _requestSerial++;
    _routeRequestInFlight = false;
    _locationFilter.reset();
    final subscription = _positionSubscription;
    _positionSubscription = null;
    final lease = _lease;
    _lease = null;
    await subscription?.cancel();
    if (lease != null) await locationService.release(lease);
    if (lifecycle != _lifecycleSerial) return;
    _emit(
      _state.copyWith(
        phase: LiveNavigationPhase.arrived,
        arrived: true,
        routeLoading: false,
        rerouting: false,
        message: 'You have arrived.',
      ),
    );
  }

  String _statusMessage(LocationTrackingStatus status) {
    return switch (status) {
      LocationTrackingStatus.permissionDenied =>
        'Location permission is required for live navigation.',
      LocationTrackingStatus.serviceDisabled =>
        'Turn on location services to start navigation.',
      LocationTrackingStatus.error =>
        'Unable to start location tracking. Please try again.',
      LocationTrackingStatus.started => '',
    };
  }

  void _emit(LiveNavigationState next) {
    _state = next;
    if (!_stateController.isClosed) _stateController.add(next);
  }

  void dispose() {
    unawaited(stop());
    unawaited(_stateController.close());
  }
}
