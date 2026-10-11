import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../database/database_helper.dart';

class CloudSyncService {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  // Replace with your actual Spring Boot or Firebase API Endpoint
  final String cloudApiUrl = "https://your-resiliomesh-backend.com/api/v1/reports/sync";

  /// Starts listening for internet connectivity changes
  void startConnectivityListener(Function onSyncComplete) {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      bool hasInternet = results.any((result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi);

      if (hasInternet && !_isSyncing) {
        await syncPendingReportsToCloud(onSyncComplete);
      }
    });
  }

  /// Iterates through SQLite unsynced queue and POSTs each payload to central backend
  Future<void> syncPendingReportsToCloud(Function onSyncComplete) async {
    _isSyncing = true;
    try {
      List<Map<String, dynamic>> pendingReports =
          await DatabaseHelper.instance.getPendingSyncReports();

      if (pendingReports.isEmpty) {
        _isSyncing = false;
        return;
      }

      for (var report in pendingReports) {
        final payload = {
          'reportId': report['reportId'],
          'senderName': report['senderName'] ?? 'Anonymous Node',
          'title': report['title'],
          'description': report['description'],
          'latitude': report['latitude'],
          'longitude': report['longitude'],
          'timestamp': report['timestamp'],
          'priorityScore': report['priority'] ?? 1.0,
        };

        // HTTP POST to Central Server
        final response = await http.post(
          Uri.parse(cloudApiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Update status in local SQLite to reflect successful cloud upload
          await DatabaseHelper.instance.updateReportStatus(report['reportId'], 'SYNCED');
        }
      }
      onSyncComplete();
    } catch (e) {
      print("Cloud Sync Error: $e");
    } finally {
      _isSyncing = false;
    }
  }

  void stopListener() {
    _connectivitySubscription?.cancel();
  }
}