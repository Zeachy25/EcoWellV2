import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String date(DateTime d) => DateFormat('MMM d, yyyy').format(d);

  static String dateTime(DateTime d) => DateFormat('MMM d, yyyy h:mm a').format(d);

  static String day(DateTime d) => DateFormat('EEE').format(d);

  static String distance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}