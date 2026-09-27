import 'package:flutter_test/flutter_test.dart';

import 'package:ecowell/data/services/device_heading_service.dart';

void main() {
  group('DeviceHeadingService.resolve', () {
    test('prefers the compass heading when available', () {
      final heading = DeviceHeadingService.resolve(
        compassAvailable: true,
        compassHeading: 120,
        gpsCourseDegrees: 45,
        speedMetersPerSecond: 1.5,
      );

      expect(heading, closeTo(120, 1e-9));
    });

    test('normalizes compass headings into the 0..360 range', () {
      expect(
        DeviceHeadingService.resolve(
          compassAvailable: true,
          compassHeading: -30,
          gpsCourseDegrees: 0,
          speedMetersPerSecond: 0,
        ),
        closeTo(330, 1e-9),
      );
      expect(
        DeviceHeadingService.resolve(
          compassAvailable: true,
          compassHeading: 400,
          gpsCourseDegrees: 0,
          speedMetersPerSecond: 0,
        ),
        closeTo(40, 1e-9),
      );
    });

    test('falls back to GPS course only while walking fast enough', () {
      final stationary = DeviceHeadingService.resolve(
        compassAvailable: false,
        compassHeading: null,
        gpsCourseDegrees: 90,
        speedMetersPerSecond: 0.4,
      );
      final moving = DeviceHeadingService.resolve(
        compassAvailable: false,
        compassHeading: null,
        gpsCourseDegrees: 90,
        speedMetersPerSecond: 0.9,
      );

      expect(stationary, isNull);
      expect(moving, closeTo(90, 1e-9));
    });

    test('returns null when no reliable direction exists', () {
      expect(
        DeviceHeadingService.resolve(
          compassAvailable: false,
          compassHeading: null,
          gpsCourseDegrees: null,
          speedMetersPerSecond: 0,
        ),
        isNull,
      );
    });
  });
}