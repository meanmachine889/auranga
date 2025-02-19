import 'package:latlong2/latlong.dart';
import '../Utils/HereApiService.dart';
import '../Utils/LocationService.dart';
import '../Utils/PolylineDecoder.dart';

class HomeViewModel {
  final LocationService _locationService = LocationService();
  final HereApiService _hereApiService = HereApiService();

  Future<LatLng> fetchUserLocation() async {
    try {
      return await _locationService.getCurrentLocation();
    } catch (e) {
      return LatLng(17.3850, 78.4867); // Default to Hyderabad
    }
  }

  Future<List<Map<String, dynamic>>> fetchSuggestions(String query, LatLng currentLocation) async {
    if (query.isEmpty) return [];
    return await _hereApiService.fetchSuggestions(query, currentLocation);
  }

  Future<Map<String, dynamic>> fetchRoute(LatLng origin, LatLng destination) async {
    final result = await _hereApiService.fetchRoute(origin, destination);

    // Decode polyline and summary
    final decodedPolyline = PolylineDecoder.decode(result['polyline']);
    final routeCoordinates = decodedPolyline.map((coord) {
      return LatLng(coord['latitude']!, coord['longitude']!);
    }).toList();

    final summary = result['summary'];
    final routeSummary = 'Distance: ${(summary['length'] / 1000).toStringAsFixed(2)} km, '
        'Time: ${(summary['duration'] / 60).toStringAsFixed(0)} mins';

    return {
      'routeCoordinates': routeCoordinates,
      'routeSummary': routeSummary,
    };
  }
}
