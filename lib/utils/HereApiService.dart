import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class HereApiService {
  final String apiKey = 'h9m7PLc5iO6Brf-NblDd5y0NYomr9eOANvGnJr05Izc';

  Future<List<Map<String, dynamic>>> fetchSuggestions(String query, LatLng currentLocation) async {
    final url = Uri.parse(
      'https://autosuggest.search.hereapi.com/v1/autosuggest?apiKey=$apiKey&q=$query&at=${currentLocation.latitude},${currentLocation.longitude}',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['items'] as List).map((item) {
          return {
            'name': item['title'],
            'latitude': item['position']['lat'],
            'longitude': item['position']['lng'],
          };
        }).toList();
      } else {
        throw Exception('Error fetching suggestions: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching suggestions: $e');
    }
  }

  Future<Map<String, dynamic>> fetchRoute(LatLng origin, LatLng destination) async {
    final url = Uri.parse(
      'https://router.hereapi.com/v8/routes?transportMode=car&origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&return=polyline,summary,actions&apiKey=$apiKey',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final polyline = data['routes'][0]['sections'][0]['polyline'];
        final summary = data['routes'][0]['sections'][0]['summary'];
        return {'polyline': polyline, 'summary': summary};
      } else {
        throw Exception('Error fetching route: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching route: $e');
    }
  }
}
