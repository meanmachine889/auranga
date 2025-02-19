import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:geolocator/geolocator.dart'; // Import Geolocator for real-time location updates
import '../Models/HomeViewModel.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeViewModel _viewModel = HomeViewModel();

  LatLng? currentLocation;
  String destination = '';
  LatLng? selectedDestination;
  List<Map<String, dynamic>> destinationSuggestions = [];
  List<LatLng> routeCoordinates = [];
  String? routeSummary;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRealTimeLocation();
  }

  void _fetchRealTimeLocation() {
    Geolocator.getPositionStream(locationSettings:
    LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10))
        .listen((Position position) {
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
      });
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    if (currentLocation == null) return;
    final suggestions = await _viewModel.fetchSuggestions(query, currentLocation!);
    setState(() {
      destinationSuggestions = suggestions;
    });
  }

  Future<void> _fetchRoute(LatLng destination) async {
    if (currentLocation == null) return;

    setState(() {
      isLoading = true;
      selectedDestination = destination;
    });

    final routeData = await _viewModel.fetchRoute(currentLocation!, destination);

    setState(() {
      routeCoordinates = routeData['routeCoordinates'];
      routeSummary = routeData['routeSummary'];
      isLoading = false;
    });
  }

  Future<void> _startNavigation() async {
    if (selectedDestination == null) return;

    try {
      final availableMaps = await MapLauncher.installedMaps;
      if (availableMaps.isNotEmpty) {
        await MapLauncher.showDirections(
          mapType: MapType.google,
          destination: Coords(
            selectedDestination!.latitude,
            selectedDestination!.longitude,
          ),
          destinationTitle: "Destination",
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No compatible map app found for navigation')),
        );
      }
    } catch (e) {
      print("Error starting navigation: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Real-time Navigation")),
      body: Stack(
        children: [
          currentLocation == null
              ? Center(child: CircularProgressIndicator())
              : FlutterMap(
            options: MapOptions(
              initialCenter: currentLocation!,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: currentLocation!,
                    color: Colors.blue.withOpacity(0.9),
                    radius: 10,
                  ),
                ],
              ),
              if (routeCoordinates.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routeCoordinates,
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Column(
              children: [
                TextField(
                  onChanged: (value) {
                    setState(() {
                      destination = value;
                    });
                    _fetchSuggestions(value);
                  },
                  decoration: InputDecoration(
                    hintText: "Enter destination",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
                if (destinationSuggestions.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 10),
                    child: Material(
                      elevation: 5,
                      borderRadius: BorderRadius.circular(8),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: destinationSuggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = destinationSuggestions[index];
                          return ListTile(
                            title: Text(suggestion['name']),
                            onTap: () {
                              final LatLng destination = LatLng(
                                suggestion['latitude'],
                                suggestion['longitude'],
                              );
                              _fetchRoute(destination);
                            },
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (routeSummary != null)
            Positioned(
              bottom: 60,
              left: 10,
              right: 10,
              child: Container(
                padding: EdgeInsets.all(10),
                color: Colors.white,
                child: Text(routeSummary!),
              ),
            ),
          if (selectedDestination != null)
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: ElevatedButton(
                onPressed: _startNavigation,
                child: Text("Start Navigation"),
              ),
            ),
          if (isLoading)
            Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
