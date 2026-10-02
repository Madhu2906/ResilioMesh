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
  final String severity; 
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
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destController = TextEditingController();

  LatLng _centerLocation = const LatLng(20.5937, 78.9629); // Center of India
  LatLng? _userLocation;
  bool _isLoading = false;
  String _selectedFilter = 'All';
  bool _showRoutePanel = false;
  bool _isRouteMinimized = false; // Controls mini view state
  List<LatLng> _routePoints = [];

  // REAL LANDSLIDE SUSCEPTIBILITY HAZARD BELTS (Polygons)
  final List<Polygon> _landslideProneZones = [
    // Western Ghats Belt (Wayanad, Idukki, Konkan, Mahabaleshwar)
    Polygon(
      points: const [
        LatLng(18.5000, 73.3000),
        LatLng(16.0000, 74.2000),
        LatLng(11.5000, 76.5000),
        LatLng(9.5000, 77.1000),
        LatLng(10.0000, 76.3000),
        LatLng(14.0000, 74.4000),
        LatLng(18.0000, 72.9000),
      ],
      color: Colors.amber.withOpacity(0.25),
      borderColor: Colors.amber.shade900,
      borderStrokeWidth: 2.0,
    ),
    // Northwest Himalayan Belt (Uttarakhand & Himachal Corridor)
    Polygon(
      points: const [
        LatLng(32.5000, 76.0000),
        LatLng(31.8000, 78.6000),
        LatLng(30.0000, 80.2000),
        LatLng(29.3000, 79.5000),
        LatLng(30.2000, 77.8000),
        LatLng(32.0000, 75.8000),
      ],
      color: Colors.deepOrange.withOpacity(0.25),
      borderColor: Colors.red.shade900,
      borderStrokeWidth: 2.0,
    ),
    // Sikkim & North West Bengal / Teesta Valley Corridor
    Polygon(
      points: const [
        LatLng(27.8000, 88.0000),
        LatLng(27.9000, 88.9000),
        LatLng(26.8000, 88.8000),
        LatLng(26.7000, 88.2000),
      ],
      color: Colors.amber.withOpacity(0.30),
      borderColor: Colors.amber.shade900,
      borderStrokeWidth: 2.0,
    ),
  ];

  // Active Disasters Array
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
    ),
  ];

  @override
  void initState() {
    super.initState();
    _getUserCurrentLocation();
    _fetchRealEarthquakes();
    _fetchRealNasaLandslides();
  }

  // Real Earthquake API (USGS)
  Future<void> _fetchRealEarthquakes() async {
    try {
      final url = Uri.parse('https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_day.geojson');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List features = data['features'] ?? [];
        List<DisasterEvent> fetched = [];

        for (var feature in features) {
          final props = feature['properties'];
          final coords = feature['geometry']['coordinates'];
          double lon = (coords[0] as num).toDouble();
          double lat = (coords[1] as num).toDouble();
          double mag = (props['mag'] as num?)?.toDouble() ?? 3.0;

          fetched.add(
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

        if (mounted && fetched.isNotEmpty) {
          setState(() {
            _allDisasters.addAll(fetched);
          });
        }
      }
    } catch (_) {}
  }

  // Real NASA COOLR Landslide API Points
  Future<void> _fetchRealNasaLandslides() async {
    try {
      final nasaUrl = Uri.parse(
          'https://gis.earthdata.nasa.gov/gis05/rest/services/Landslides/COOLR_Events_Points/FeatureServer/0/query?where=1%3D1&outFields=event_title,location_description,landslide_category,event_date,trigger&outSR=4326&f=json&resultRecordCount=100');

      final response = await http.get(nasaUrl);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List features = data['features'] ?? [];
        List<DisasterEvent> realLandslides = [];

        for (var f in features) {
          final attr = f['attributes'];
          final geom = f['geometry'];

          if (geom != null && geom['y'] != null && geom['x'] != null) {
            double lat = (geom['y'] as num).toDouble();
            double lon = (geom['x'] as num).toDouble();

            realLandslides.add(
              DisasterEvent(
                title: attr['event_title'] ?? 'Real Landslide Incident',
                category: 'Landslide',
                location: LatLng(lat, lon),
                locationName: attr['location_description'] ?? 'Hazard Area',
                severity: 'High',
                time: attr['event_date'] != null
                    ? DateTime.fromMillisecondsSinceEpoch(attr['event_date'])
                        .toString()
                        .split(' ')[0]
                    : 'Reported Incident',
                icon: Icons.warning_amber_rounded,
                color: Colors.amber.shade900,
                isRealData: true,
              ),
            );
          }
        }

        if (mounted && realLandslides.isNotEmpty) {
          setState(() {
            _allDisasters.addAll(realLandslides);
          });
        }
      }
    } catch (_) {}
  }

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
      _showSnackBar('Location permissions permanently denied');
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

  Future<LatLng?> _geocodeAddress(String query) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=$query, India&limit=1');
    try {
      final response = await http.get(url, headers: {'User-Agent': 'ResilioMesh_App'});
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return LatLng(double.parse(data[0]['lat']), double.parse(data[0]['lon']));
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _searchLocationInIndia(String query) async {
    if (query.trim().isEmpty) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    LatLng? pos = await _geocodeAddress(query);
    if (pos != null) {
      setState(() {
        _centerLocation = pos;
        _isLoading = false;
      });
      _mapController.move(pos, 12.0);
    } else {
      _showSnackBar('Location not found in India');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _calculateRoute() async {
    if (_startController.text.trim().isEmpty || _destController.text.trim().isEmpty) {
      _showSnackBar('Enter both Start and Destination places');
      return;
    }

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    LatLng? start;
    if (_startController.text.trim().toLowerCase() == 'my location' ||
        _startController.text.trim().toLowerCase() == 'current location') {
      if (_userLocation == null) {
        await _getUserCurrentLocation();
      }
      start = _userLocation;
    } else {
      start = await _geocodeAddress(_startController.text);
    }

    LatLng? destination = await _geocodeAddress(_destController.text);

    if (start == null || destination == null) {
      _showSnackBar('Could not find starting or destination location');
      setState(() => _isLoading = false);
      return;
    }

    final osrmUrl = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson');

    try {
      final response = await http.get(osrmUrl);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List coordinates = data['routes'][0]['geometry']['coordinates'];

        setState(() {
          _routePoints = coordinates
              .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
              .toList();
          _isLoading = false;
          _isRouteMinimized = true; // Auto-minimize upon finding route
        });

        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints([start, destination]),
            padding: const EdgeInsets.all(60),
          ),
        );
      } else {
        _showSnackBar('Route service unavailable');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showSnackBar('Failed to calculate route');
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
    // Show real landslides when route active OR filter matches
    List<DisasterEvent> filteredDisasters = _allDisasters.where((event) {
      if (event.category == 'Landslide' && _routePoints.isEmpty) {
        return false;
      }
      if (_selectedFilter == 'All') return true;
      return event.category.toLowerCase() == _selectedFilter.toLowerCase();
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disaster Map',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFFFF5252),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showRoutePanel ? Icons.search : Icons.directions),
            tooltip: _showRoutePanel ? 'Standard Search' : 'Directions',
            onPressed: () {
              setState(() {
                _showRoutePanel = !_showRoutePanel;
                _isRouteMinimized = false;
              });
            },
          )
        ],
      ),
      body: Stack(
        children: [
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

              // LANDSLIDE-PRONE HAZARD ZONES (Polygons render when route is active)
              if (_routePoints.isNotEmpty)
                PolygonLayer(polygons: _landslideProneZones),

              // ROUTE POLYLINE
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.0,
                      color: Colors.blueAccent,
                    ),
                  ],
                ),

              // MARKER LAYER
              MarkerLayer(
                markers: [
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 50,
                      height: 50,
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

                  ...filteredDisasters.map((event) {
                    return Marker(
                      point: event.location,
                      width: 42,
                      height: 42,
                      child: GestureDetector(
                        onTap: () => _showDisasterDetails(event),
                        child: Container(
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
                            size: 20,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // Top Navigation Stack
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_showRoutePanel)
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              onSubmitted: _searchLocationInIndia,
                              decoration: const InputDecoration(
                                hintText: 'Search city or area in India...',
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

                if (_showRoutePanel && _isRouteMinimized)
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.directions, color: Color(0xFFFF5252)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _destController.text.isNotEmpty
                                  ? 'To: ${_destController.text}'
                                  : 'Route Active',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.unfold_more, color: Colors.grey),
                            tooltip: 'Expand Route Settings',
                            onPressed: () {
                              setState(() {
                                _isRouteMinimized = false;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            tooltip: 'Clear Route',
                            onPressed: () {
                              setState(() {
                                _routePoints.clear();
                                _startController.clear();
                                _destController.clear();
                                _isRouteMinimized = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_showRoutePanel && !_isRouteMinimized)
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _startController,
                            decoration: InputDecoration(
                              hintText: 'Start Location',
                              prefixIcon: const Icon(Icons.my_location,
                                  color: Colors.blue),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.gps_fixed,
                                    color: Colors.blueAccent),
                                tooltip: 'Use Current Location',
                                onPressed: () async {
                                  if (_userLocation == null) {
                                    await _getUserCurrentLocation();
                                  }
                                  if (_userLocation != null) {
                                    setState(() {
                                      _startController.text = 'My Location';
                                    });
                                  }
                                },
                              ),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 8),

                          TextField(
                            controller: _destController,
                            decoration: const InputDecoration(
                              hintText: 'Destination (e.g. Shimla)',
                              prefixIcon:
                                  Icon(Icons.location_on, color: Colors.red),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _calculateRoute,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF5252),
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.directions),
                                  label: const Text('Find Route'),
                                ),
                              ),
                              if (_routePoints.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.unfold_less, color: Colors.grey),
                                  tooltip: 'Minimize',
                                  onPressed: () {
                                    setState(() {
                                      _isRouteMinimized = true;
                                    });
                                  },
                                ),
                              ],
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                tooltip: 'Clear route & search',
                                onPressed: () {
                                  setState(() {
                                    _routePoints.clear();
                                    _startController.clear();
                                    _destController.clear();
                                    _isRouteMinimized = false;
                                  });
                                },
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Flood', 'Fire', 'Cyclone', 'Earthquake']
                        .map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          selectedColor: const Color(0xFFFF5252),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
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
              ],
            ),
          ),

          if (_isLoading)
            const Positioned(
              bottom: 80,
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
                        Text('Processing request...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),

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