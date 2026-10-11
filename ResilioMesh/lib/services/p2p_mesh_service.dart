import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import '../database/database_helper.dart';
import '../engine/ecva_engine.dart';

class P2pMeshService {
  // Singleton pattern setup
  static final P2pMeshService _instance = P2pMeshService._internal();
  factory P2pMeshService() => _instance;
  P2pMeshService._internal();

  // P2P_CLUSTER enables M-to-N multi-device peer topology
  final Strategy strategy = Strategy.P2P_CLUSTER;
  final String userName = "Node_${DateTime.now().millisecondsSinceEpoch}";
  final String serviceId = "com.resiliomesh.app";

  // Track currently connected and pending endpoint IDs
  final Set<String> _connectedEndpoints = {};
  final Set<String> _pendingConnections = {};

  // Track incoming file payloads mapped by Payload ID -> Report ID / File Name
  final Map<int, String> _pendingFileReports = {};
  final Map<int, String> _pendingFileNames = {};
  final Map<String, Map<String, dynamic>> _pendingReportMetadata = {};

  // Stream controller to notify UI when peer count changes in real time
  final StreamController<int> _peerCountController = StreamController<int>.broadcast();
  Stream<int> get peerCountStream => _peerCountController.stream;

  // Stream controller for incoming real-time P2P reports
  final StreamController<Map<String, dynamic>> _incomingReportController =
      StreamController<Map<String, dynamic>>.broadcast();
  
  /// Real-time stream of reports received over the P2P Mesh
  Stream<Map<String, dynamic>> get incomingReportStream => _incomingReportController.stream;

  /// Getter for the current connected peer count
  int get connectedEndpointsCount => _connectedEndpoints.length;

  void _updatePeerCount() {
    _peerCountController.add(_connectedEndpoints.length);
  }

  /// Starts both Advertising and Discovery safely by clearing existing states first
 /// Starts both Advertising and Discovery safely by clearing existing states first
  Future<void> startMeshNode() async {
    try {
      // Clean up existing states
      await stopMeshNode();

      // 1. Start Advertising
      await Nearby().startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: (id, status) {
          _pendingConnections.remove(id);
          if (status == Status.CONNECTED) {
            _connectedEndpoints.add(id);
            _updatePeerCount();
            _syncLocalReportsWithPeer(id);
            debugPrint("P2P Connected as Advertiser: $id");
          } else {
            _connectedEndpoints.remove(id);
            _updatePeerCount();
          }
        },
        onDisconnected: (id) {
          _connectedEndpoints.remove(id);
          _pendingConnections.remove(id);
          _updatePeerCount();
        },
        serviceId: serviceId,
      );

      // 2. Start Discovery
      await _startDiscovery();
    } catch (e) {
      debugPrint("P2P Mesh Startup Error: $e");
    }
  }

  /// Internal helper to run continuous discovery scan
  Future<void> _startDiscovery() async {
    try {
      await Nearby().startDiscovery(
        userName,
        strategy,
        onEndpointFound: (id, name, serviceId) async {
          if (_connectedEndpoints.contains(id) || _pendingConnections.contains(id)) {
            return;
          }

          _pendingConnections.add(id);
          debugPrint("Endpoint discovered: $id ($name). Requesting connection...");

          try {
            await Nearby().requestConnection(
              userName,
              id,
              onConnectionInitiated: _onConnectionInitiated,
              onConnectionResult: (id, status) {
                _pendingConnections.remove(id);
                if (status == Status.CONNECTED) {
                  _connectedEndpoints.add(id);
                  _updatePeerCount();
                  _syncLocalReportsWithPeer(id);
                  debugPrint("P2P Connected as Discoverer: $id");
                } else {
                  _connectedEndpoints.remove(id);
                  _updatePeerCount();
                }
              },
              onDisconnected: (id) {
                _connectedEndpoints.remove(id);
                _pendingConnections.remove(id);
                _updatePeerCount();
              },
            );
          } catch (e) {
            _pendingConnections.remove(id);
            debugPrint("P2P Connection Request Error for $id: $e");
          }
        },
        onEndpointLost: (id) {
          _connectedEndpoints.remove(id);
          _pendingConnections.remove(id);
          _updatePeerCount();
        },
        serviceId: serviceId,
      );
    } catch (e) {
      debugPrint("Error starting discovery: $e");
    }
  }

  /// Auto-accept incoming connection requests on both nodes
  void _onConnectionInitiated(String endpointId, ConnectionInfo info) async {
    try {
      debugPrint("Connection initiated with $endpointId (${info.endpointName}). Auto-accepting...");
      await Nearby().acceptConnection(
        endpointId,
        onPayLoadRecieved: (id, payload) async {
          if (payload.type == PayloadType.BYTES && payload.bytes != null) {
            await _processReceivedBytesPayload(payload.bytes!, id, payload.id);
          } else if (payload.type == PayloadType.FILE) {
            String? tempFilePath = payload.filePath;
            String reportId = _pendingFileReports[payload.id] ?? '';

            if (tempFilePath != null && reportId.isNotEmpty) {
              Map<String, dynamic>? metadata = _pendingReportMetadata.remove(reportId);
              if (metadata != null) {
                metadata['tempFilePath'] = tempFilePath;
                await _saveAndRelayFileReport(metadata, tempFilePath, id);
              }
            }
          }
        },
        onPayloadTransferUpdate: (id, update) async {
          if (update.status == PayloadStatus.SUCCESS) {
            debugPrint("Payload ${update.id} transfer completed with peer $endpointId");
            _pendingFileReports.remove(update.id);
            _pendingFileNames.remove(update.id);
          }
        },
      );
    } catch (e) {
      debugPrint("Handshake error for $endpointId: $e");
    }
  }

  /// Primary broadcast method called across UI sheets to send reports over the mesh
  Future<void> broadcastReport(Map<String, dynamic> reportData) async {
    await broadcastNewReport(reportData);
  }

  /// Broadcasts a newly created local report (with optional media file) to all connected mesh nodes
  Future<void> broadcastNewReport(Map<String, dynamic> report) async {
    if (_connectedEndpoints.isEmpty) {
      debugPrint("No connected P2P mesh peers available for broadcast.");
      return;
    }

    String mediaPath = report['mediaPaths']?.toString() ?? '';

    for (String endpointId in _connectedEndpoints) {
      if (mediaPath.isNotEmpty && File(mediaPath).existsSync()) {
        await sendReportWithMedia(endpointId, report);
      } else {
        try {
          Map<String, dynamic> payloadMap = {
            'type': 'REPORT_DATA',
            'report': report,
          };
          String jsonStr = jsonEncode(payloadMap);
          Uint8List bytes = Uint8List.fromList(utf8.encode(jsonStr));
          await Nearby().sendBytesPayload(endpointId, bytes);
          debugPrint("Broadcasted text report ${report['reportId']} to $endpointId.");
        } catch (e) {
          debugPrint("Error broadcasting report: $e");
        }
      }
    }
  }

  /// Transmits report data and attached media files using PayloadType.BYTES and PayloadType.FILE
  Future<void> sendReportWithMedia(String endpointId, Map<String, dynamic> report) async {
    // Step 1: Send the report metadata as JSON BYTES
    Map<String, dynamic> payloadMap = {
      'type': 'REPORT_DATA',
      'report': report,
    };

    String jsonString = jsonEncode(payloadMap);
    await Nearby().sendBytesPayload(
      endpointId,
      Uint8List.fromList(utf8.encode(jsonString)),
    );

    // Step 2: If media files exist, transfer them using PayloadType.FILE
    String mediaPaths = report['mediaPaths']?.toString() ?? '';
    if (mediaPaths.isNotEmpty) {
      List<String> paths = mediaPaths.split(',');
      for (String path in paths) {
        File file = File(path);
        if (await file.exists()) {
          // Send metadata header first so receiver knows which report this file belongs to
          Map<String, dynamic> fileMeta = {
            'type': 'FILE_HEADER',
            'reportId': report['reportId'],
            'fileName': path.split('/').last,
          };
          await Nearby().sendBytesPayload(
            endpointId,
            Uint8List.fromList(utf8.encode(jsonEncode(fileMeta))),
          );

          // Send actual file payload
          int payloadId = await Nearby().sendFilePayload(endpointId, file.path);
          debugPrint("Sent file payload $payloadId ($path) to peer $endpointId");
        }
      }
    }
  }

  /// Alias method for sendReportWithMedia for backward compatibility
  Future<void> sendFileReport({
    required Map<String, dynamic> report,
    required String localFilePath,
  }) async {
    for (String endpointId in _connectedEndpoints) {
      await sendReportWithMedia(endpointId, report);
    }
  }

  /// Processes received BYTES, pairs metadata with FILE payloads or inserts text reports
  Future<void> _processReceivedBytesPayload(Uint8List bytes, String senderEndpointId, int payloadId) async {
    try {
      String jsonStr = utf8.decode(bytes);
      Map<String, dynamic> data = jsonDecode(jsonStr);

      if (data['type'] == 'REPORT_DATA') {
        Map<String, dynamic> report = Map<String, dynamic>.from(data['report']);
        report['status'] = 'PENDING_SYNC';
        String reportId = report['reportId'] ?? 'sos_${DateTime.now().millisecondsSinceEpoch}';
        
        _pendingReportMetadata[reportId] = report;

        bool isNew = await DatabaseHelper.instance.insertReportIfNew(report);

        if (isNew) {
          debugPrint("New P2P text report received & stored: $reportId");
          _incomingReportController.add(report);
          _relayReportToOtherPeers(bytes, senderEndpointId);
        }
      } else if (data['type'] == 'FILE_HEADER') {
        // Prepare tracking maps for incoming file payload stream
        String reportId = data['reportId'];
        String fileName = data['fileName'];

        _pendingFileReports[payloadId + 1] = reportId; // Map next incoming file payload
        _pendingFileNames[payloadId + 1] = fileName;
      }
    } catch (e) {
      debugPrint("Error decoding P2P byte payload: $e");
    }
  }

  /// Saves complete offline file transfer to SQLite and relays to remaining mesh peers
  Future<void> _saveAndRelayFileReport(
    Map<String, dynamic> report,
    String savedFilePath,
    String senderEndpointId,
  ) async {
    report['status'] = 'PENDING_SYNC';
    if (savedFilePath.isNotEmpty) {
      report['mediaPaths'] = savedFilePath;
    }

    bool isNew = await DatabaseHelper.instance.insertReportIfNew(report);

    if (isNew) {
      debugPrint("New P2P media report saved to SQLite: ${report['reportId']}");
      _incomingReportController.add(report);

      // Relay media file to other connected peers
      for (String peerId in _connectedEndpoints) {
        if (peerId != senderEndpointId) {
          try {
            await sendReportWithMedia(peerId, report);
          } catch (e) {
            debugPrint("Error relaying media file to $peerId: $e");
          }
        }
      }
    }
  }

  /// Forwards payload bytes to all connected nodes except the sender
  void _relayReportToOtherPeers(Uint8List bytes, String senderEndpointId) async {
    for (String endpointId in _connectedEndpoints) {
      if (endpointId != senderEndpointId) {
        await Nearby().sendBytesPayload(endpointId, bytes);
      }
    }
  }

  /// Reads unsynced off-grid reports from SQLite and transmits them to a newly connected peer
  void _syncLocalReportsWithPeer(String endpointId) async {
    List<Map<String, dynamic>> pendingReports =
        await DatabaseHelper.instance.getUnsyncedReports();

    for (var report in pendingReports) {
      await sendReportWithMedia(endpointId, report);
    }
  }

  /// Calculates ECVA priority scores for a list of raw SQLite reports
  List<Map<String, dynamic>> applyEcvaPrioritization({
    required List<Map<String, dynamic>> rawReports,
    required double userLat,
    required double userLng,
  }) {
    List<Map<String, dynamic>> prioritizedReports = rawReports.map((report) {
      Map<String, dynamic> mutableReport = Map<String, dynamic>.from(report);

      double priorityScore = EcvaEngine.calculatePriority(
        userLat: userLat,
        userLng: userLng,
        reportLat: (mutableReport['latitude'] as num).toDouble(),
        reportLng: (mutableReport['longitude'] as num).toDouble(),
        timestamp: mutableReport['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      );

      mutableReport['priority'] = priorityScore;
      return mutableReport;
    }).toList();

    // Sort by highest priority score descending
    prioritizedReports.sort((a, b) => (b['priority'] as double).compareTo(a['priority'] as double));
    return prioritizedReports;
  }

  /// Stops all active mesh advertising, scanning, and endpoint links
  Future<void> stopMeshNode() async {
    try {
      await Nearby().stopAdvertising();
      await Nearby().stopDiscovery();
      await Nearby().stopAllEndpoints();
    } catch (e) {
      debugPrint("Error shutting down mesh node: $e");
    } finally {
      _connectedEndpoints.clear();
      _pendingConnections.clear();
      _pendingFileReports.clear();
      _pendingFileNames.clear();
      _pendingReportMetadata.clear();
      _updatePeerCount();
    }
  }
}