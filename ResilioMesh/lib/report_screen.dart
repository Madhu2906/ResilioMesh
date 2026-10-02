import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  File? _imageFile;
  Position? _currentPosition;
  bool _isLoading = false;

  // 1. Pick image from camera
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // 2. Get current GPS location
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permissions are permanently denied.'),
        ),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = position;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Location set: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
        ),
      ),
    );
  }

  // 3. Upload photo to Firebase Storage & save report to Firestore
  Future<void> _submitReport() async {
    if (_imageFile == null ||
        _currentPosition == null ||
        _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a photo, location, and description!'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Unique file name based on timestamp
      String fileName = 'disaster_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Fixed storage reference using standard ref()
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('disaster_photos')
          .child(fileName);

      // Upload file
      UploadTask uploadTask = storageRef.putFile(_imageFile!);

      // Wait for upload to complete fully
      TaskSnapshot snapshot = await uploadTask;

      // Get download URL after snapshot completes successfully
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Save report data to Firestore
      await FirebaseFirestore.instance.collection('disaster_reports').add({
        'photoUrl': downloadUrl,
        'description': _descriptionController.text.trim(),
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading report: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Disaster'),
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Picker Box
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.redAccent, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: Colors.redAccent,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap to Take Photo',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Location Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.location_on, color: Colors.white),
                label: Text(
                  _currentPosition == null
                      ? 'Get Current Location'
                      : 'Location Set (${_currentPosition!.latitude.toStringAsFixed(2)}, ${_currentPosition!.longitude.toStringAsFixed(2)})',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),

              // Description Text Field
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Report incident description...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Send / Submit Button
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.redAccent),
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _submitReport,
                      child: const Text(
                        'Send',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
