import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';
import '../services/p2p_mesh_service.dart';
import '../screens/create_sos_bottom_sheet.dart';

class P2pMeshScreen extends StatefulWidget {
  const P2pMeshScreen({Key? key}) : super(key: key);

  @override
  State<P2pMeshScreen> createState() => _P2pMeshScreenState();
}

class _P2pMeshScreenState extends State<P2pMeshScreen> {
  final P2pMeshService _meshService = P2pMeshService();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<int>? _peerCountSubscription;
  StreamSubscription<Map<String, dynamic>>? _incomingReportSubscription;

  bool _isMeshEnabled = false;
  bool _isSyncing = false;
  int _connectedPeersCount = 0;
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadLocalReports();
    _initAutoCloudSyncListener();
    _initPeerCountListener();
    _initP2pReportListener();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _peerCountSubscription?.cancel();
    _incomingReportSubscription?.cancel();
    super.dispose();
  }

  /// 1. Listens to real-time peer updates emitted from P2pMeshService
  void _initPeerCountListener() {
    _peerCountSubscription = _meshService.peerCountStream.listen((count) {
      if (mounted) {
        setState(() {
          _connectedPeersCount = count;
        });
      }
    });
  }

  /// 2. Listens for incoming P2P reports from nearby devices and updates local state dynamically
  void _initP2pReportListener() {
    _incomingReportSubscription = _meshService.incomingReportStream.listen((incomingReport) async {
      // Save received peer report into local SQLite database
      await DatabaseHelper.instance.insertReportIfNew(incomingReport);
      // Immediately refresh local list view
      await _loadLocalReports();
    });
  }

  /// 3. Listens for cellular/Wi-Fi connection to automatically sync off-grid queue to central server
  void _initAutoCloudSyncListener() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      bool hasInternet = results.any((result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi);

      if (hasInternet && !_isSyncing) {
        await _syncReportsToCloud();
      }
    });
  }

  /// 4. Fetch local SQLite queue and re-render screen
  Future<void> _loadLocalReports() async {
    final rawReports = await DatabaseHelper.instance.getAllReports();

    final prioritized = _meshService.applyEcvaPrioritization(
      rawReports: rawReports,
      userLat: 19.0760,
      userLng: 72.8777,
    );

    if (mounted) {
      setState(() {
        _reports = prioritized;
      });
    }
  }

  void _toggleMeshNode(bool value) async {
    setState(() {
      _isMeshEnabled = value;
    });

    if (_isMeshEnabled) {
      await _meshService.startMeshNode();
      if (mounted) {
        setState(() {
          _connectedPeersCount = _meshService.connectedEndpointsCount;
        });
      }
    } else {
      await _meshService.stopMeshNode();
      if (mounted) {
        setState(() {
          _connectedPeersCount = 0;
        });
      }
    }
  }

  /// Syncs accumulated off-grid SQLite queue to cloud central server
  Future<void> _syncReportsToCloud() async {
    final pendingReports = await DatabaseHelper.instance.getPendingSyncReports();
    if (pendingReports.isEmpty) return;

    setState(() {
      _isSyncing = true;
    });

    // Simulate central server upload delay over network
    await Future.delayed(const Duration(milliseconds: 1500));

    // Update local SQLite queue status from PENDING_SYNC to SYNCED
    await DatabaseHelper.instance.markAllReportsAsSynced();

    await _loadLocalReports();

    if (mounted) {
      setState(() {
        _isSyncing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Internet connected: Off-grid reports uploaded to Central Server!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Displays bottom sheet for creating an emergency report and broadcasts over Mesh + reloads local list
  void _showCreateSosSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return CreateSosBottomSheet(
          onSosCreated: () async {
            // 🔄 1. Immediately re-query local SQLite DB to display new report on screen
            await _loadLocalReports();

            // 📡 2. Broadcast the newly created report over the P2P Mesh to nearby peer phones
            if (_reports.isNotEmpty && _isMeshEnabled) {
              final latestReport = _reports.first; // Grab newly created top report
              await _meshService.broadcastReport(latestReport);
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("P2P Edge Mesh Network", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF00897B),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Live Peer Counter Badge in AppBar
          if (_isMeshEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.teal.shade900,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_tethering, size: 14, color: Colors.greenAccent),
                    const SizedBox(width: 4),
                    Text(
                      "$_connectedPeersCount Peer(s)",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          _isSyncing
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.cloud_upload_outlined),
                  tooltip: "Sync Queue to Cloud",
                  onPressed: _syncReportsToCloud,
                ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: SwitchListTile(
                title: Text(
                  _isMeshEnabled ? "Mesh Node Enabled" : "Mesh Node Disabled",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _isMeshEnabled
                      ? "📡 Active Mesh: $_connectedPeersCount Peer(s) Nearby"
                      : "Turn on to sync off-grid reports with nearby peers",
                  style: TextStyle(
                    color: _isMeshEnabled ? Colors.green.shade800 : Colors.black54,
                    fontWeight: _isMeshEnabled ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                value: _isMeshEnabled,
                onChanged: _toggleMeshNode,
                secondary: Icon(
                  Icons.hub,
                  size: 36,
                  color: _isMeshEnabled ? const Color(0xFF00897B) : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Off-Grid Queue (Local SQLite)",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadLocalReports,
                  tooltip: "Refresh Local Queue",
                )
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _reports.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.cloud_done_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 10),
                          Text("No pending off-grid reports.", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _reports.length,
                      itemBuilder: (context, index) {
                        final item = _reports[index];
                        final String status = item['status']?.toString() ?? 'PENDING_SYNC';
                        final bool isSynced = status == 'SYNCED';
                        final String mediaPaths = item['mediaPaths']?.toString() ?? '';
                        final bool hasAttachments = mediaPaths.isNotEmpty;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(
                              "${item['title'] ?? 'Untitled'} - ${item['senderName'] ?? 'Anonymous'}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${item['description'] ?? ''}"),
                                if (item['mobileNumber'] != null)
                                  Text("Mobile: ${item['mobileNumber']}", style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                                Text(
                                  "Location: (${item['latitude']}, ${item['longitude']}) | Priority: ${(item['priority'] ?? 0.0).toStringAsFixed(2)}",
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                if (hasAttachments)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: const [
                                        Icon(Icons.attach_file, size: 14, color: Colors.blue),
                                        SizedBox(width: 4),
                                        Text("Media Attached", style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Chip(
                              label: Text(
                                status,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: isSynced ? Colors.green : Colors.orange,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSosSheet,
        icon: const Icon(Icons.add_alert, color: Colors.white),
        label: const Text("Create SOS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFD32F2F),
      ),
    );
  }
}