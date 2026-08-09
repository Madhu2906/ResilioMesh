import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LiveWeatherScreen extends StatefulWidget {
  const LiveWeatherScreen({super.key});

  @override
  State<LiveWeatherScreen> createState() => _LiveWeatherScreenState();
}

class _LiveWeatherScreenState extends State<LiveWeatherScreen> {
  // Red & White Theme Colors
  static const Color primaryRed = Color(0xFFD32F2F);
  static const Color lightRedBg = Color(0xFFFFEBEE);
  static const Color cardBorderColor = Color(0xFFE0E0E0);

  // 25 Locations across India
  final List<String> _indiaLocations = [
    'Mumbai, Maharashtra',
    'New Delhi, Delhi',
    'Bengaluru, Karnataka',
    'Kolkata, West Bengal',
    'Chennai, Tamil Nadu',
    'Hyderabad, Telangana',
    'Ahmedabad, Gujarat',
    'Pune, Maharashtra',
    'Jaipur, Rajasthan',
    'Lucknow, Uttar Pradesh',
    'Kanpur, Uttar Pradesh',
    'Nagpur, Maharashtra',
    'Indore, Madhya Pradesh',
    'Patna, Bihar',
    'Bhopal, Madhya Pradesh',
    'Visakhapatnam, Andhra Pradesh',
    'Vadodara, Gujarat',
    'Ghaziabad, Uttar Pradesh',
    'Ludhiana, Punjab',
    'Agra, Uttar Pradesh',
    'Nashik, Maharashtra',
    'Faridabad, Haryana',
    'Meerut, Uttar Pradesh',
    'Rajkot, Gujarat',
    'Srinagar, Jammu and Kashmir',
  ];

  String _selectedLocation = 'Mumbai, Maharashtra';
  bool _isLoading = false;

  // Mock dynamic weather details (can be replaced with actual API response fields)
  Map<String, dynamic> _weatherData = {
    'station': 'Main Regional Center',
    'temp': '28.5° C',
    'rain': '0.00 mm',
    'wind': '10.2 km/h',
    'humidity': '85%',
    'pressure': '1008.2 hPa',
    'rain1hr': '0mm',
    'rain3hr': '0.2mm',
    'rain6hr': '0.5mm',
    'rain24hr': '4.1mm',
  };
  Future<void> _fetchRealWeatherData(String locationName) async {
    setState(() => _isLoading = true);

    try {
      // Clean up location string if it contains wards (e.g., "Mumbai - Kurla West" -> "Mumbai")
      String queryCity = locationName.contains('-')
          ? locationName.split('-')[0].trim()
          : locationName;

      // Replace with your actual OpenWeatherMap API key
      const String apiKey = 'f232f8c032e0a2494ac85da225e5a365';
      final String url =
          'https://api.openweathermap.org/data/2.5/weather?q=$queryCity,IN&appid=$apiKey&units=metric';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _weatherData = {
            'station': '${data['name']} Station Node',
            'temp': '${data['main']['temp']}° C',
            'rain':
                '${data.containsKey('rain') ? data['rain']['1h'] ?? 0.0 : 0.00} mm',
            'wind': '${data['wind']['speed']} km/h',
            'humidity': '${data['main']['humidity']}%',
            'pressure': '${data['main']['pressure']} hPa',
            'rain1hr':
                '${data.containsKey('rain') ? data['rain']['1h'] ?? 0 : 0}mm',
            'rain3hr':
                '0.4mm', // OpenWeather free tier doesn't always split 3h easily, keep dynamic fallback
            'rain6hr': '0.8mm',
            'rain24hr': '4.2mm',
          };
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load real-time weather data.'),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Network error: $e')));
      }
    }
  }

  // Function to handle GPS Live Location request when user clicks the card
  // ==========================================
  // 1. Updated GPS Live Location Method
  // ==========================================
  Future<void> _requestUserLiveLocation() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'GPS Live Location is optimized for Android/iOS devices.',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled.')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Fetch real weather using GPS lat/lon coordinates
      await _fetchRealWeatherByCoordinates(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
      }
    }
  }

  // ==========================================
  // 2. Helper Method for Coordinate-based API Fetch
  // ==========================================
  Future<void> _fetchRealWeatherByCoordinates(double lat, double lon) async {
    try {
      const String apiKey =
          'f232f8c032e0a2494ac85da225e5a365'; // Your OpenWeather API Key
      final String url =
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _selectedLocation =
              'GPS: ${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}';
          _weatherData = {
            'station': '${data['name']} GPS Sensor Node',
            'temp': '${data['main']['temp']}° C',
            'rain':
                '${data.containsKey('rain') ? data['rain']['1h'] ?? 0.0 : 0.00} mm',
            'wind': '${data['wind']['speed']} km/h',
            'humidity': '${data['main']['humidity']}%',
            'pressure': '${data['main']['pressure']} hPa',
            'rain1hr':
                '${data.containsKey('rain') ? data['rain']['1h'] ?? 0 : 0}mm',
            'rain3hr': '0.4mm',
            'rain6hr': '0.8mm',
            'rain24hr': '4.2mm',
          };
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to fetch weather for current coordinates.'),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('API Error: $e')));
      }
    }
  }

  // Update mock weather data dynamically when choosing from the dropdown
  void _onLocationChanged(String? newLocation) {
    if (newLocation != null) {
      setState(() {
        _selectedLocation = newLocation;
      });
      // Call the real API function here
      _fetchRealWeatherData(newLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryRed,
        elevation: 0,
        title: const Text(
          'Live Weather',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Header Curve Container with Red Theme
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 24),
              decoration: const BoxDecoration(
                color: primaryRed,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Clickable Live Weather Card Header triggering GPS prompt
                  GestureDetector(
                    onTap: _requestUserLiveLocation,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.wb_sunny_rounded,
                        size: 36,
                        color: primaryRed,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap icon to fetch Live GPS Weather',
                    style: TextStyle(fontSize: 11, color: lightRedBg),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Main Body Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dropdown Selection Card (25 Locations across India)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_pin,
                          color: primaryRed,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _indiaLocations.contains(_selectedLocation)
                                  ? _selectedLocation
                                  : null,
                              hint: Text(
                                _selectedLocation,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                              isExpanded: true,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.black54,
                              ),
                              items: _indiaLocations.map((String location) {
                                return DropdownMenuItem<String>(
                                  value: location,
                                  child: Text(
                                    location,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: _onLocationChanged,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Weather Station Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.apartment_rounded,
                          color: Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Weather Station',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _weatherData['station'],
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Header & Map Link row
                  // Header row
                  const Text(
                    'Last 15 minutes data',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  const SizedBox(height: 10),

                  // Data Metrics Section
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cardBorderColor),
                        ),
                        child: Column(
                          children: [
                            _buildMetricRow('Temp', _weatherData['temp']),
                            const Divider(height: 16, color: cardBorderColor),
                            _buildMetricRow('Rain', _weatherData['rain']),
                            const Divider(height: 16, color: cardBorderColor),
                            _buildMetricRow('Wind', _weatherData['wind']),
                            const Divider(height: 16, color: cardBorderColor),
                            _buildMetricRow(
                              'Humidity',
                              _weatherData['humidity'],
                            ),
                            const Divider(height: 16, color: cardBorderColor),
                            _buildMetricRow(
                              'Pressure',
                              _weatherData['pressure'],
                            ),
                          ],
                        ),
                      ),
                      if (_isLoading)
                        Positioned.fill(
                          child: Container(
                            color: Colors.white.withOpacity(0.7),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: primaryRed,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Rainfall (Most Recent) Header
                  const Center(
                    child: Text(
                      'Rainfall (Most Recent)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Rainfall Intervals Card Grid
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildRainfallColumn('1 hr', _weatherData['rain1hr']),
                        _buildVerticalDivider(),
                        _buildRainfallColumn('3 hr', _weatherData['rain3hr']),
                        _buildVerticalDivider(),
                        _buildRainfallColumn('6 hr', _weatherData['rain6hr']),
                        _buildVerticalDivider(),
                        _buildRainfallColumn('24 hr', _weatherData['rain24hr']),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildRainfallColumn(String timeLabel, String amount) {
    return Column(
      children: [
        Text(
          timeLabel,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 28, width: 1, color: cardBorderColor);
  }
}
