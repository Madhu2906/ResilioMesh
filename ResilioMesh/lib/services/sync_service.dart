import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../database/database_helper.dart';

class SyncService {
  static final SyncService instance = SyncService._init();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Spring Boot REST Backend Endpoints
  static const String _backendBaseUrl = 'https://13jr54g7-8080.inc1.devtunnels.ms';
  static const String _syncEndpoint = '$_backendBaseUrl/api/v1/sos/sync';
  static const String _uploadEndpoint = '$_backendBaseUrl/api/v1/reports/upload';

  SyncService._init();

  /// Initializes real-time connectivity listener to auto-sync when online
  void initialize() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) async {
      bool isOnline = results.contains(ConnectivityResult.wifi) ||
                      results.contains(ConnectivityResult.mobile);

      if (isOnline) {
        print("Network restored. Triggering auto-sync to backend...");
        await syncPendingReports();
      }
    });
  }

  /// Syncs all unsynced SQLite reports (and associated media files) to Spring Boot
  Future<void> syncPendingReports() async {
    final pendingReports = await DatabaseHelper.instance.getUnsyncedReports();
    if (pendingReports.isEmpty) {
      print("No pending reports to sync.");
      return;
    }

    print("Syncing ${pendingReports.length} pending reports to backend...");

    for (var reportMap in pendingReports) {
      try {
        final Map<String, dynamic> report = Map<String, dynamic>.from(reportMap);
        final String rawMediaPaths = report['mediaPaths'] ?? '';

        // Check if there are local files attached that need to be uploaded
        List<String> mediaList = rawMediaPaths
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        // If local binary files exist, send as Multipart upload
        bool hasLocalFiles = mediaList.any((path) => File(path).existsSync());

        bool success = false;
        if (hasLocalFiles) {
          success = await uploadReportWithFiles(report, mediaList);
        } else {
          success = await uploadJsonReport(report);
        }

        if (success) {
          print("Report ${report['reportId']} successfully synced to backend.");
        }
      } catch (e) {
        print("Failed to sync individual report: $e");
      }
    }

    // Mark all successfully pushed reports as synced in local SQLite
    await DatabaseHelper.instance.markAllReportsAsSynced();
  }

  /// Standard JSON Post for reports without pending binary file transfers
  Future<bool> uploadJsonReport(Map<String, dynamic> report) async {
    try {
      final response = await http.post(
        Uri.parse(_syncEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'bypass-tunnel-reminder': 'true',
        },
        body: jsonEncode([report]),
      );

      return (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      print("JSON sync failed: $e");
      return false;
    }
  }

  /// Multipart Request to attach raw binary media files alongside the JSON report
  Future<bool> uploadReportWithFiles(Map<String, dynamic> report, List<String> filePaths) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_uploadEndpoint));

      // DevTunnel Header Bypass
      request.headers['bypass-tunnel-reminder'] = 'true';

      // Attach Report Payload as Form Field
      request.fields['report'] = jsonEncode(report);

      // Attach Files
      for (String path in filePaths) {
        File file = File(path);
        if (await file.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath('files', file.path),
          );
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("Multipart upload error [${response.statusCode}]: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Multipart request error: $e");
      return false;
    }
  }

  /// Cancels subscription on service dispose
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}


// import 'dart:async';
// import 'dart:convert';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:http/http.dart' as http;
// import '../database/database_helper.dart';

// class SyncService {
//   static final SyncService instance = SyncService._init();
//   StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

//   // Ensure this URL matches your Spring Boot Controller RequestMapping
//   static const String _backendUrl = 'https://13jr54g7-8080.inc1.devtunnels.ms/api/v1/sos/sync';

//   SyncService._init();

//   /// Initializes real-time connectivity listener to auto-sync when online
//   void initialize() {
//     _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) async {
//       bool isOnline = results.contains(ConnectivityResult.wifi) ||
//                       results.contains(ConnectivityResult.mobile);

//       if (isOnline) {
//         print("Network restored. Triggering auto-sync to backend...");
//         await syncPendingReports();
//       }
//     });
//   }

//   /// Syncs all unsynced SQLite reports to the Spring Boot cloud backend
//   Future<void> syncPendingReports() async {
//     final pendingReports = await DatabaseHelper.instance.getUnsyncedReports();
//     if (pendingReports.isEmpty) {
//       print("No pending reports to sync.");
//       return;
//     }

//     print("Syncing ${pendingReports.length} pending reports to backend: $_backendUrl");

//     try {
//       final response = await http.post(
//         Uri.parse(_backendUrl),
//         headers: {
//           'Content-Type': 'application/json',
//           'bypass-tunnel-reminder': 'true', // BYPASS DEV TUNNEL INTERSTITIAL
//         },
//         body: jsonEncode(pendingReports),
//       );

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         await DatabaseHelper.instance.markAllReportsAsSynced();
//         print("Mesh queue successfully synced to cloud backend.");
//       } else {
//         print("Backend sync returned status code: ${response.statusCode}");
//         print("Backend response body: ${response.body}");
//       }
//     } catch (e) {
//       print("Sync failed (offline or host unreachable): $e");
//     }
//   }

//   /// Cancels subscription on service dispose
//   void dispose() {
//     _connectivitySubscription?.cancel();
//   }
// }