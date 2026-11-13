import 'package:autoaid/services/location_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('distance between identical points is zero', () {
    const p = LatLng(30.0444, 31.2357);
    expect(LocationService.distanceKm(p, p), 0);
  });

  test('about 111 km per degree of latitude', () {
    final km = LocationService.distanceKm(
        const LatLng(30, 31), const LatLng(31, 31));
    expect(km, closeTo(111, 2));
  });

  test('ETA is at least one minute and grows with distance', () {
    expect(LocationService.etaMinutes(0), 1);
    expect(LocationService.etaMinutes(40), 60);
    expect(LocationService.etaMinutes(20), 30);
  });
}
