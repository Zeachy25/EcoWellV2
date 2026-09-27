import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:ecowell/features/shared/fence_overlay.dart';
import 'package:ecowell/models/geo_fence.dart';
import 'package:ecowell/models/green_space.dart';

GreenSpace _space({List<GeoCoord>? vertices, double radius = 150}) {
  return GreenSpace(
    id: 'space-1',
    name: 'Test Space',
    description: '',
    category: 'Park',
    address: '',
    latitude: 7.2,
    longitude: 125.4,
    radiusMeters: radius,
    amenities: const [],
    polygonVertices: vertices,
  );
}

void main() {
  group('FenceOverlay', () {
    test('circleFor builds a circle for a circular fence', () {
      final circle = FenceOverlay.circleFor(_space());

      expect(circle, isNotNull);
      expect(circle!.radius, 150);
      expect(circle.center, const LatLng(7.2, 125.4));
      expect(circle.circleId, const CircleId('destination-zone'));
    });

    test('circleFor returns null for a polygon fence', () {
      final space = _space(
        vertices: const [
          GeoCoord(7.2, 125.4),
          GeoCoord(7.3, 125.4),
          GeoCoord(7.25, 125.5),
        ],
      );

      expect(space.fence, isA<PolygonFence>());
      expect(FenceOverlay.circleFor(space), isNull);
    });

    test('polygonFor closes the ring by repeating the first vertex', () {
      final space = _space(
        vertices: const [
          GeoCoord(7.2, 125.4),
          GeoCoord(7.3, 125.4),
          GeoCoord(7.25, 125.5),
        ],
      );

      final polygon = FenceOverlay.polygonFor(space);

      expect(polygon, isNotNull);
      expect(polygon!.points.length, 4);
      expect(polygon.points.first, polygon.points.last);
    });

    test('polygonFor returns null for a circular fence', () {
      expect(FenceOverlay.polygonFor(_space()), isNull);
    });

    test('polygonFor returns null when the fence has no vertices', () {
      const space = GreenSpace(
        id: 'empty',
        name: 'Empty',
        description: '',
        category: 'Park',
        address: '',
        latitude: 7.2,
        longitude: 125.4,
        radiusMeters: 0,
        amenities: [],
        polygonVertices: [],
      );

      expect(FenceOverlay.polygonFor(space), isNull);
    });

    test('honors custom id, colors, width, and tap handling', () {
      var tapped = 0;
      final circle = FenceOverlay.circleFor(
        _space(),
        id: 'geofence-1',
        fillColor: const Color(0x3390EEB0),
        strokeColor: const Color(0xFF2E7D32),
        strokeWidth: 3,
        onTap: () => tapped++,
        consumeTapEvents: true,
      );

      expect(circle, isNotNull);
      expect(circle!.circleId, const CircleId('geofence-1'));
      expect(circle.strokeWidth, 3);
      expect(circle.consumeTapEvents, isTrue);
      circle.onTap?.call();
expect(tapped, 1);
    });
  });
}
