import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/database_helper.dart';
import '../services/p2p_mesh_service.dart';
import 'package:path/path.dart' as p;

class CreateSosBottomSheet extends StatefulWidget {
  final Function() onSosCreated;

  const CreateSosBottomSheet({Key? key, required this.onSosCreated}) : super(key: key);

  @override
  State<CreateSosBottomSheet> createState() => _CreateSosBottomSheetState();
}

class _CreateSosBottomSheetState extends State<CreateSosBottomSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String _senderName = "Loading...";
  String _mobileNumber = "Loading...";
  List<File> _selectedMediaFiles = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Auto-loads User Profile from SharedPreferences with live Firebase/Firestore fallback
  /// Auto-loads User Profile from SharedPreferences with live Firebase/Firestore fallback
Future<void> _loadUserProfile() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    String name = prefs.getString('user_name') ?? '';
    String mobile = prefs.getString('user_mobile') ?? '';

    // If local cache is missing or unknown, fetch live from Firebase / Firestore
    if (name.isEmpty || name == 'Unknown User' || name == 'Loading...' || mobile.isEmpty || mobile == 'N/A') {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        name = user.displayName ?? user.email ?? 'Unknown User';
        
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get()
              .timeout(const Duration(seconds: 3));

          if (doc.exists) {
            final data = doc.data();
            if (data != null) {
              name = data['name'] ?? data['fullName'] ?? name;
              // Check all possible field name variations for phone number
              mobile = data['phone'] ?? data['mobile'] ?? data['phoneNumber'] ?? mobile;
            }
          }
        } catch (_) {
          // Offline fallback
        }

        // Cache locally for offline future use
        await prefs.setString('user_name', name);
        await prefs.setString('user_mobile', mobile.isNotEmpty ? mobile : 'N/A');
      }
    }

    if (mounted) {
      setState(() {
        _senderName = name.isNotEmpty ? name : 'Unknown User';
        _mobileNumber = (mobile.isNotEmpty && mobile != 'null') ? mobile : 'N/A';
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _senderName = 'Unknown User';
        _mobileNumber = 'N/A';
      });
    }
  }
}
  /// Safe GPS Retrieval with Fallback & Timeout
  Future<Position?> _getSafePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return await Geolocator.getLastKnownPosition();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return await Geolocator.getLastKnownPosition();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return await Geolocator.getLastKnownPosition();
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(
        const Duration(seconds: 4),
        onTimeout: () async {
          return await Geolocator.getLastKnownPosition() ??
              Position(
                longitude: 0.0,
                latitude: 0.0,
                timestamp: DateTime.now(),
                accuracy: 0.0,
                altitude: 0.0,
                heading: 0.0,
                speed: 0.0,
                speedAccuracy: 0.0,
                altitudeAccuracy: 0.0,
                headingAccuracy: 0.0,
              );
        },
      );
    } catch (e) {
      return await Geolocator.getLastKnownPosition();
    }
  }

  /// Pick Image from Camera or Gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (image != null && mounted) {
        setState(() {
          _selectedMediaFiles.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  /// Pick Short Video clip from Camera
  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 15),
      );
      if (video != null && mounted) {
        setState(() {
          _selectedMediaFiles.add(File(video.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record video: $e')),
        );
      }
    }
  }

  /// Submit SOS Report with P2P Broadcast, Local SQLite Storage & HTTP Multipart Sync
  Future<void> _submitReport() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an emergency title.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      Position? position = await _getSafePosition();

      double lat = position?.latitude ?? 0.0;
      double lng = position?.longitude ?? 0.0;

      List<String> rawLocalPaths = _selectedMediaFiles.map((f) => f.path).toList();

      Map<String, dynamic> reportData = {
        'reportId': 'sos_${DateTime.now().millisecondsSinceEpoch}',
        'senderName': _senderName,
        'mobileNumber': _mobileNumber,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'latitude': lat,
        'longitude': lng,
        'mediaPaths': rawLocalPaths.join(','),
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'PENDING_SYNC',
      };

      // 1. Save locally to SQLite database
      await DatabaseHelper.instance.insertReportIfNew(reportData);

      // 2. Broadcast over P2P Mesh Network
      try {
        await P2pMeshService().broadcastReport(reportData);
        debugPrint("SOS broadcasted to nearby P2P mesh peers!");
      } catch (p2pError) {
        debugPrint("P2P Broadcast error: $p2pError");
      }

      // 3. HTTP Sync to Spring Boot Backend
      try {
        if (_selectedMediaFiles.isNotEmpty) {
          var request = http.MultipartRequest(
            'POST',
            Uri.parse('https://13jr54g7-8080.inc1.devtunnels.ms/api/v1/reports/upload'),
          );

          request.headers['bypass-tunnel-reminder'] = 'true';
          request.fields['report'] = jsonEncode(reportData);

          for (File mediaFile in _selectedMediaFiles) {
            bool exists = await mediaFile.exists();
            if (exists) {
              request.files.add(
                await http.MultipartFile.fromPath('files', mediaFile.path),
              );
            }
          }

          var streamedResponse = await request.send().timeout(const Duration(seconds: 15));
          var response = await http.Response.fromStream(streamedResponse);

          if (response.statusCode == 200 || response.statusCode == 201) {
            debugPrint("Report and files uploaded successfully to cloud backend!");
          }
        } else {
          final url = Uri.parse('https://13jr54g7-8080.inc1.devtunnels.ms/api/v1/sos/sync');
          await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'bypass-tunnel-reminder': 'true',
            },
            body: jsonEncode([reportData]),
          ).timeout(const Duration(seconds: 5));
        }
      } catch (networkError) {
        debugPrint("Network offline or request timed out: $networkError");
      }

    } catch (e) {
      debugPrint("Error creating SOS report: $e");
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.pop(context);
        widget.onSosCreated();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SOS Report Broadcasted & Saved!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 16,
        right: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Create Off-Grid Emergency SOS',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_pin, color: Colors.blueGrey),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reporter: $_senderName', style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('Mobile: $_mobileNumber', style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Emergency Title (e.g., Medical Alert)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (e.g., Injured leg near building A)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Attach Media (Optional):', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Photo'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.videocam),
                  label: const Text('Video Clip'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_selectedMediaFiles.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedMediaFiles.length,
                  itemBuilder: (context, index) {
                    final file = _selectedMediaFiles[index];
                    final isVideo = file.path.endsWith('.mp4');
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.black12,
                          ),
                          child: isVideo
                              ? const Icon(Icons.movie, size: 40, color: Colors.blueAccent)
                              : Image.file(file, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 2,
                          right: 10,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedMediaFiles.removeAt(index));
                            },
                            child: const CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.close, size: 12, color: Colors.white),
                            ),
                          ),
                        )
                      ],
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isSubmitting ? null : _submitReport,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('BROADCAST SOS', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}