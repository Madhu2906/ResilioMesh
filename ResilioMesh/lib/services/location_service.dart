import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService {
  // Update this URL with your backend IP/Domain
  static const String _backendUrl = 'https://13jr54g7-8080.inc1.devtunnels.ms/api/users/update-device';

  /// Requests permissions and syncs FCM token + GPS location to Spring Boot backend
  static Future<void> syncUserLocationAndToken() async {
    try {
      // 1. Check & Request Location Permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint("⚠️ Location permissions are denied.");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint("⚠️ Location permissions are permanently denied.");
        return;
      }

      // 2. Fetch current high-accuracy GPS coordinates
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 3. Get Firebase FCM Token
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint("⚠️ FCM Token is null or empty.");
        return;
      }

      // 4. Send payload to Spring Boot Backend
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fcmToken': fcmToken,
          'latitude': position.latitude,
          'longitude': position.longitude,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Location & FCM Token synced with backend: (${position.latitude}, ${position.longitude})");
      } else {
        debugPrint("❌ Failed to sync with backend. Status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error in syncUserLocationAndToken: $e");
    }
  }

  /// (Optional) Continuous background tracking listener whenever location changes
  static void listenToLocationChanges() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100, // Trigger sync only after moving 100 meters
    );

    Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      syncUserLocationAndToken();
    });
  }
}