import 'package:farm_tap/core/places/uganda_districts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Why the district could not be found from the phone's location.
enum LocationProblem { off, denied, notFound }

/// Finds the district the phone is in (B06 "Use my location"). Asks for
/// location permission the first time.
class LocationService {
  const new();

  /// The district, or the reason there is none.
  Future<(String?, LocationProblem?)> currentDistrict() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return (null, LocationProblem.off);
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return (null, LocationProblem.denied);
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      final marks = await Geocoding().placemarkFromCoordinates(p.latitude, p.longitude);
      final district = matchDistrict([
        for (final m in marks) ...[m.subAdministrativeArea, m.administrativeArea, m.locality, m.subLocality],
      ]);
      return district == null ? (null, LocationProblem.notFound) : (district, null);
    } on Object {
      return (null, LocationProblem.notFound);
    }
  }
}
