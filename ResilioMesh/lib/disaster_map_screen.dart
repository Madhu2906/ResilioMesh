import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// ==========================================
// DISASTER EVENT MODEL
// ==========================================
class DisasterEvent {
  final String title;
  final String category;
  final LatLng location;
  final String locationName;
  final String severity; // High, Moderate, Low
  final String time;
  final IconData icon;
  final Color color;
  final bool isRealData;

  DisasterEvent({
    required this.title,
    required this.category,
    required this.location,
    required this.locationName,
    required this.severity,
    required this.time,
    required this.icon,
    required this.color,
    this.isRealData = false,
  });
}

// ==========================================
// MAIN MAP SCREEN
// ==========================================
class DisasterMapScreen extends StatefulWidget {
  const DisasterMapScreen({super.key});

  @override
  State<DisasterMapScreen> createState() => _DisasterMapScreenState();
}

class _DisasterMapScreenState extends State<DisasterMapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng _centerLocation = const LatLng(20.5937, 78.9629); // Center of India
  LatLng? _userLocation;
  bool _isLoading = false;
  String _selectedFilter = 'All';

  // RESTORED: Original India Disaster Data
  final List<DisasterEvent> _allDisasters = [
    DisasterEvent(
      title: 'Urban Waterlogging Alert',
      category: 'Flood',
      location: const LatLng(19.0760, 72.8777),
      locationName: 'Mumbai, Maharashtra',
      severity: 'High',
      time: '10 mins ago',
      icon: Icons.water_damage_rounded,
      color: Colors.blue,
      isRealData: false,
    ),
    DisasterEvent(
      title: 'Severe Riverine Flood Alert',
      category: 'Flood',
      location: const LatLng(26.1445, 91.7362),
      locationName: 'Guwahati, Assam',
      severity: 'High',
      time: '30 mins ago',
      icon: Icons.water_damage_rounded,
      color: Colors.blue,
      isRealData: false,
    ),
    DisasterEvent(
      title: 'Coastal Depression Warning',
      category: 'Cyclone',
      location: const LatLng(20.2961, 85.8245),
      locationName: 'Bhubaneswar, Odisha',
      severity: 'Moderate',
      time: '1 hour ago',
      icon: Icons.air_rounded,
      color: Colors.cyan,
      isRealData: false,
    ),
    DisasterEvent(
      title: 'Mild Seismic Tremor (Mag 3.4)',
      category: 'Earthquake',
      location: const LatLng(30.3165, 78.0322),
      locationName: 'Dehradun, Uttarakhand',
      severity: 'Low',
      time: '2 hours ago',
      icon: Icons.terrain_rounded,
      color: Colors.brown,
      isRealData: false,
    ),
    DisasterEvent(
      title: 'Commercial Storage Fire',
      category: 'Fire',
      location: const LatLng(28.6139, 77.2090),
      locationName: 'New Delhi, Delhi',
      severity: 'High',
      time: '15 mins ago',
      icon: Icons.local_fire_department_rounded,
      color: Colors.orange,
      isRealData: false,
    ),
    DisasterEvent(
      title: 'Industrial Gas Leakage Alert',
      category: 'Chemical',
      location: const LatLng(17.6868, 83.2185),
      locationName: 'Visakhapatnam, Andhra Pradesh',
      severity: 'Moderate',
      time: '45 mins ago',
      icon: Icons.science_rounded,
      color: Colors.purple,
      isRealData: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _getUserCurrentLocation();
    _fetchRealDisasters();
  }

  // Fetch real live events from USGS & NASA EONET without touching static list formatting
  Future<void> _fetchRealDisasters() async {
    List<DisasterEvent> fetchedRealEvents = [];

    // 1. Fetch Live Earthquakes from USGS API
    try {
      final usgsUrl = Uri.parse(
          'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_day.geojson');
      final response = await http.get(usgsUrl);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List features = data['features'] ?? [];

        for (var feature in features) {
          final props = feature['properties'];
          final coords = feature['geometry']['coordinates'];
          double lon = (coords[0] as num).toDouble();
          double lat = (coords[1] as num).toDouble();
          double mag = (props['mag'] as num?)?.toDouble() ?? 3.0;

          fetchedRealEvents.add(
            DisasterEvent(
              title: 'Live Earthquake (M $mag)',
              category: 'Earthquake',
              location: LatLng(lat, lon),
              locationName: props['place'] ?? 'Global Region',
              severity: mag >= 5.0 ? 'High' : (mag >= 3.5 ? 'Moderate' : 'Low'),
              time: 'Just now',
              icon: Icons.terrain_rounded,
              color: Colors.redAccent,
              isRealData: true,
            ),
          );
        }
      }
    } catch (_) {}

    // 2. Fetch Live Events from NASA EONET API
    try {
      final nasaUrl = Uri.parse(
          'https://eonet.gsfc.nasa.gov/api/v3/events?status=open&limit=15');
      final response = await http.get(nasaUrl);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List events = data['events'] ?? [];

        for (var event in events) {
          final title = event['title'] ?? 'Natural Disaster';
          final categories = event['categories'] as List?;
          String categoryName = 'General';
          IconData icon = Icons.warning_rounded;
          Color color = Colors.purple;

          if (categories != null && categories.isNotEmpty) {
            String catId = categories[0]['id'] ?? '';
            if (catId.toLowerCase().contains('fire')) {
              categoryName = 'Fire';
              icon = Icons.local_fire_department_rounded;
              color = Colors.orange;
            } else if (catId.toLowerCase().contains('storm')) {
              categoryName = 'Cyclone';
              icon = Icons.air_rounded;
              color = Colors.cyan;
            } else if (catId.toLowerCase().contains('flood')) {
              categoryName = 'Flood';
              icon = Icons.water_damage_rounded;
              color = Colors.blue;
            }
          }

          final geometries = event['geometry'] as List?;
          if (geometries != null && geometries.isNotEmpty) {
            final coords = geometries.last['coordinates'] as List?;
            if (coords != null && coords.length >= 2) {
              double lon = (coords[0] as num).toDouble();
              double lat = (coords[1] as num).toDouble();

              fetchedRealEvents.add(
                DisasterEvent(
                  title: title,
                  category: categoryName,
                  location: LatLng(lat, lon),
                  locationName: 'NASA Global Feed',
                  severity: 'Moderate',
                  time: 'Live',
                  icon: icon,
                  color: color,
                  isRealData: true,
                ),
              );
            }
          }
        }
      }
    } catch (_) {}

    if (mounted && fetchedRealEvents.isNotEmpty) {
      setState(() {
        _allDisasters.addAll(fetchedRealEvents);
      });
    }
  }

  // Get GPS Location for India
  Future<void> _getUserCurrentLocation() async {
    setState(() => _isLoading = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('Please enable GPS Location services');
      setState(() => _isLoading = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Location permission denied');
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar('Location permissions are permanently denied');
      setState(() => _isLoading = false);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _centerLocation = _userLocation!;
        _isLoading = false;
      });

      _mapController.move(_userLocation!, 11.0);
    } catch (e) {
      _showSnackBar('Could not fetch location');
      setState(() => _isLoading = false);
    }
  }

  // Free OpenStreetMap Geocoding Search (Restricted to India)
  Future<void> _searchLocationInIndia(String query) async {
    if (query.trim().isEmpty) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=$query, India&countrycodes=in&limit=1');

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'ResilioMesh_Disaster_App',
      });

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          double lat = double.parse(data[0]['lat']);
          double lon = double.parse(data[0]['lon']);
          LatLng searchedPos = LatLng(lat, lon);

          setState(() {
            _centerLocation = searchedPos;
            _isLoading = false;
          });

          _mapController.move(searchedPos, 12.0);
        } else {
          _showSnackBar('Location not found in India');
          setState(() => _isLoading = false);
        }
      } else {
        _showSnackBar('Search service error');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showSnackBar('Search failed. Check network');
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
    );
  }

  void _showDisasterDetails(DisasterEvent event) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: event.color.withOpacity(0.2),
                    child: Icon(event.icon, color: event.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          event.locationName,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: event.severity == 'High'
                          ? Colors.red.shade100
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${event.severity} Risk',
                      style: TextStyle(
                        color: event.severity == 'High'
                            ? Colors.red.shade900
                            : Colors.orange.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Category: ${event.category}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('Reported: ${event.time}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Acknowledge Alert'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5252),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<DisasterEvent> filteredDisasters = _selectedFilter == 'All'
        ? _allDisasters
        : _allDisasters
            .where((e) =>
                e.category.toLowerCase() == _selectedFilter.toLowerCase())
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disaster Map',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFF5252),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // OpenStreetMap Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centerLocation,
              initialZoom: 5.2,
              minZoom: 3.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.resiliomesh',
              ),
              MarkerLayer(
                markers: [
                  // Current User Location Marker
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 50,
                      height: 50,
                      child: Tooltip(
                        message: "Your Location",
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.my_location_rounded,
                            color: Colors.blueAccent,
                            size: 28,
                          ),
                        ),
                      ),
                    ),

                  // Disaster Location Markers
                  ...filteredDisasters.map((event) {
                    return Marker(
                      point: event.location,
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => _showDisasterDetails(event),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: event.color, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              )
                            ],
                          ),
                          child: Icon(
                            event.icon,
                            color: event.color,
                            size: 22,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // Top Search Bar
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _searchLocationInIndia,
                      decoration: const InputDecoration(
                        hintText: 'Search (e.g. Surat, Assam)',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward,
                        color: Color(0xFFFF5252)),
                    onPressed: () =>
                        _searchLocationInIndia(_searchController.text),
                  ),
                ],
              ),
            ),
          ),

          // Filter Chips Row
          Positioned(
            top: 72,
            left: 14,
            right: 14,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Flood', 'Fire', 'Cyclone', 'Earthquake']
                    .map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      selectedColor: const Color(0xFFFF5252),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: Colors.white,
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            const Positioned(
              top: 130,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text('Fetching location...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),

      // My Location GPS Floating Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _getUserCurrentLocation,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFFF5252),
        icon: const Icon(Icons.my_location),
        label: const Text('My Location',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}