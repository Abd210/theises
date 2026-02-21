import 'dart:math';

/// Kaaba coordinates (Mecca, Saudi Arabia).
const double _kaabaLat = 21.4225;
const double _kaabaLon = 39.8262;

double _toRad(double deg) => deg * pi / 180.0;
double _toDeg(double rad) => rad * 180.0 / pi;

/// Compute bearing from North to the Kaaba (0–360°, 1 decimal).
///
/// Formula:
///   Δlon = kaabaLon - userLon
///   y = sin(Δlon) * cos(kaabaLat)
///   x = cos(userLat)*sin(kaabaLat) - sin(userLat)*cos(kaabaLat)*cos(Δlon)
///   bearing = atan2(y, x)  →  degrees  →  normalize 0..360
double computeQiblaDegrees(double userLat, double userLon) {
  final uLatR = _toRad(userLat);
  final kLatR = _toRad(_kaabaLat);
  final dLonR = _toRad(_kaabaLon - userLon);

  final y = sin(dLonR) * cos(kLatR);
  final x = cos(uLatR) * sin(kLatR) - sin(uLatR) * cos(kLatR) * cos(dLonR);
  final bearing = _toDeg(atan2(y, x));

  // Normalize to 0..360 with 1 decimal
  final normalized = (bearing + 360) % 360;
  return (normalized * 10).roundToDouble() / 10;
}
