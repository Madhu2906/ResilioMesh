import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'services/p2p_mesh_service.dart';
import 'services/sync_service.dart';

class MeshTaskHandler extends TaskHandler {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) async {
      final bool hasNetwork = results.any((result) => result != ConnectivityResult.none);

      if (!hasNetwork) {
        // Off-grid detected: Activate P2P Mesh engine in background isolate
        await P2pMeshService().startMeshNode();
        FlutterForegroundTask.updateService(
          notificationTitle: 'ResilioMesh Emergency Relay Active',
          notificationText: 'Off-grid SOS Mesh Node running in background...',
        );
      } else {
        // Internet restored: Stop mesh to preserve battery
        await P2pMeshService().stopMeshNode();
        FlutterForegroundTask.updateService(
          notificationTitle: 'ResilioMesh Online',
          notificationText: 'Connected to central server.',
        );
      }
    });
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    try {
      debugPrint("Executing background mesh sync cycle at $timestamp...");
      // Calls the matching method in SyncService
      await SyncService.instance.syncPendingReports(); 
    } catch (e) {
      debugPrint("Error during background mesh repeat sync: $e");
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _connectivitySubscription?.cancel();
    await P2pMeshService().stopMeshNode();
  }
}