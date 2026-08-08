import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:torch_light/torch_light.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  Timer? _countdownTimer;
  int _secondsRemaining = 3;
  bool _isSending = false;
  bool _sosTriggered = false;
  String _selectedCategory = 'GENERAL';

  // Text Controller for Custom Emergency Details
  final TextEditingController _customCategoryController = TextEditingController();

  // Hardware Audio & Strobe Controllers
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isHardwareActive = false;

  // Real-Time Admin Dispatch & ETA Tracking Variables
  int? _activeAlertId;
  bool _isAccepted = false;
  int _etaMinutes = 0;
  Timer? _pollTimer;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'General', 'icon': Icons.warning_amber_rounded, 'code': 'GENERAL'},
    {'label': 'Medical', 'icon': Icons.local_hospital_rounded, 'code': 'MEDICAL'},
    {'label': 'Fire', 'icon': Icons.local_fire_department_rounded, 'code': 'FIRE'},
    {'label': 'Trapped', 'icon': Icons.minor_crash_rounded, 'code': 'TRAPPED'},
    {'label': 'Other', 'icon': Icons.edit_note_rounded, 'code': 'OTHER'},
  ];

  @override
  void initState() {
    super.initState();

    // Listen for FCM Push Notification when Admin accepts SOS
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['type'] == 'ETA_UPDATE') {
        final eta = int.tryParse(message.data['etaMinutes'] ?? '15') ?? 15;
        _pollTimer?.cancel();
        if (mounted) {
          setState(() {
            _isAccepted = true;
            _etaMinutes = eta;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _cancelTimer();
    _pollTimer?.cancel();
    _stopHardwareAlert();
    _customCategoryController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Hardware activation methods (Siren + Flashlight)
  Future<void> _startHardwareAlert() async {
    _isHardwareActive = true;

    // 1. Play Emergency Siren Audio on Loop
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('siren.mp3'));
    } catch (e) {
      debugPrint("Audio Player Error: $e");
    }

    // 2. Turn on Device Flashlight
    try {
      final isTorchAvailable = await TorchLight.isTorchAvailable();
      if (isTorchAvailable && _isHardwareActive) {
        await TorchLight.enableTorch();
      }
    } catch (e) {
      debugPrint("Torch Light Error: $e");
    }
  }

  Future<void> _stopHardwareAlert() async {
    _isHardwareActive = false;

    // Stop Siren
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint("Audio Stop Error: $e");
    }

    // Disable Flashlight
    try {
      await TorchLight.disableTorch();
    } catch (e) {
      debugPrint("Torch Disable Error: $e");
    }
  }

  // Handle Location Permission and GPS state checks
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services (GPS) are disabled. Please enable GPS in device settings.'),
          ),
        );
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required to send live coordinates.'),
            ),
          );
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permissions are permanently denied. Please enable them in app settings.',
            ),
          ),
        );
      }
      return false;
    }

    return true;
  }

  // Start 3-Second Visible Countdown Dialog
  void _startSosCountdown() {
    if (_isSending || _sosTriggered) return;

    _secondsRemaining = 3;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            _countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
              if (_secondsRemaining > 1) {
                setDialogState(() {
                  _secondsRemaining--;
                });
              } else {
                _cancelTimer();
                Navigator.of(dialogContext).pop();
                _triggerSosAlert();
              }
            });

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252), size: 28),
                  SizedBox(width: 8),
                  Text('Sending SOS Alert', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Distress signal will be transmitted in:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.red.shade100,
                    child: Text(
                      '$_secondsRemaining',
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF5252),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tap Cancel if this was triggered accidentally.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      _cancelTimer();
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('SOS Alert Cancelled.'),
                          backgroundColor: Colors.grey,
                        ),
                      );
                    },
                    child: const Text('CANCEL SOS', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => _cancelTimer());
  }

  void _cancelTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  Future<void> _triggerSosAlert() async {
    setState(() {
      _isSending = true;
    });

    try {
      // 1. Check permissions first
      final bool hasPermission = await _handleLocationPermission();
      if (!hasPermission) {
        if (mounted) setState(() => _isSending = false);
        return;
      }

      // 2. Fetch high-accuracy GPS coordinates
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Construct category payload (Includes user typed description if 'OTHER' selected)
      String categoryPayload = _selectedCategory;
      if (_selectedCategory == 'OTHER' && _customCategoryController.text.trim().isNotEmpty) {
        categoryPayload = "OTHER: ${_customCategoryController.text.trim()}";
      }

      // 3. Backend Endpoint
      final url = Uri.parse('http://10.0.2.2:8080/api/admin/sos/trigger');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'X-Tunnel-Skip-Anti-Phishing-Page': 'true',
            },
            body: jsonEncode({
              'latitude': position.latitude,
              'longitude': position.longitude,
              'category': categoryPayload,
              'fcmToken': 'sample_token',
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final alertId = responseData['id'];

        setState(() {
          _sosTriggered = true;
          _isSending = false;
          _activeAlertId = alertId != null
              ? (alertId is int ? alertId : int.tryParse(alertId.toString()))
              : null;
        });

        // Trigger Flashlight and Siren Alarm
        _startHardwareAlert();

        // Start polling for Admin acceptance
        if (_activeAlertId != null) {
          _startPollingForAcceptance(_activeAlertId!);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('🚨 SOS Alert transmitted! Waiting for Admin dispatch...'),
          ),
        );
      } else {
        throw Exception("Server status ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("SOS API Error: $e");
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _showFallbackDialog();
      }
    }
  }

  // Polls backend every 3 seconds to check if Admin clicked 'Dispatch Rescue Unit'
  void _startPollingForAcceptance(int alertId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final url = Uri.parse('http://10.0.2.2:8080/api/admin/sos/status/$alertId');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'ACCEPTED') {
            timer.cancel();
            if (mounted) {
              setState(() {
                _isAccepted = true;
                _etaMinutes = data['etaMinutes'] ?? 15;
              });
            }
          }
        }
      } catch (e) {
        debugPrint("Status Check Error: $e");
      }
    });
  }

  // Fallback SMS launcher in case API or internet fails
  Future<void> _sendEmergencySms() async {
    try {
      final bool hasPermission = await _handleLocationPermission();
      if (!hasPermission) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String categoryText = _selectedCategory;
      if (_selectedCategory == 'OTHER' && _customCategoryController.text.trim().isNotEmpty) {
        categoryText = "OTHER (${_customCategoryController.text.trim()})";
      }

      final String mapsLink =
          "https://maps.google.com/?q=${position.latitude},${position.longitude}";
      final String message =
          "EMERGENCY ALERT ($categoryText)! I need immediate help. Live Location: $mapsLink";

      final Uri smsUri = Uri(
        scheme: 'sms',
        path: '8369732553',
        queryParameters: <String, String>{'body': message},
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch SMS application.')),
          );
        }
      }
    } catch (e) {
      debugPrint("SMS Error: $e");
    }
  }

  void _showFallbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Server Unreachable'),
        content: const Text(
          'Could not connect to emergency network. Would you like to send an emergency SMS with your live location instead?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
            ),
            onPressed: () {
              Navigator.pop(context);
              _sendEmergencySms();
            },
            child: const Text('SEND SMS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _resetAlertState() {
    _pollTimer?.cancel();
    _stopHardwareAlert(); // Stops siren and flashlight
    _customCategoryController.clear();
    setState(() {
      _sosTriggered = false;
      _isSending = false;
      _isAccepted = false;
      _activeAlertId = null;
      _etaMinutes = 0;
      _selectedCategory = 'GENERAL';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          children: [
            const Text(
              'EMERGENCY DISTRESS SIGNAL',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap button once to initiate emergency broadcast. You will have 3 seconds to cancel.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Emergency Category Selection
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select Emergency Type:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(height: 12),

            // Horizontally Scrollable Category Bar to Fit 5 Categories Seamlessly
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final bool isSelected = _selectedCategory == cat['code'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        if (!_sosTriggered && !_isSending) {
                          setState(() {
                            _selectedCategory = cat['code'];
                          });
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFF5252)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFF5252)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              cat['icon'],
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cat['label'],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Custom TextField Input - Appears dynamically when 'OTHER' is selected
            if (_selectedCategory == 'OTHER') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _customCategoryController,
                enabled: !_sosTriggered && !_isSending,
                decoration: InputDecoration(
                  hintText: 'Type emergency detail (e.g. Gas Leak, Flood)...',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                  prefixIcon: const Icon(Icons.edit_note_rounded, color: Color(0xFFFF5252)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF5252), width: 2),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),

            // IF ACCEPTED BY ADMIN: Show Countdown Tracker
            if (_isAccepted) ...[
              EtaTrackingWidget(initialEtaMinutes: _etaMinutes),
              const SizedBox(height: 20),
            ]
            // IF SOS SENT BUT WAITING FOR ADMIN: Show Waiting Status Banner
            else if (_sosTriggered) ...[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: const [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.orange),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'SOS Signal Transmitted!\nWaiting for Admin Dispatch & ETA...',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // SOS Single-Tap Button UI
            GestureDetector(
              onTap: _isSending || _sosTriggered ? null : _startSosCountdown,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _sosTriggered
                      ? Colors.green
                      : const Color(0xFFFF5252),
                  boxShadow: [
                    BoxShadow(
                      color: (_sosTriggered
                              ? Colors.green
                              : const Color(0xFFFF5252))
                          .withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isSending)
                      const CircularProgressIndicator(color: Colors.white)
                    else if (_sosTriggered) ...[
                      const Icon(Icons.check_circle,
                          size: 50, color: Colors.white),
                      const SizedBox(height: 8),
                      const Text(
                        'ALERT SENT!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    ] else ...[
                      const Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'TAP TO TRIGGER',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // If SOS is already triggered, show button to reset and stop hardware sound/flashlight
            if (_sosTriggered)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.volume_off_rounded, color: Colors.white),
                label: const Text('STOP SIREN & RESET',
                    style: TextStyle(color: Colors.white)),
                onPressed: _resetAlertState,
              )
            else
              // Direct SMS Fallback Trigger Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF5252),
                  side: const BorderSide(color: Color(0xFFFF5252)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.sms_rounded),
                label: const Text('SEND SMS EMERGENCY ALERT'),
                onPressed: _sendEmergencySms,
              ),
          ],
        ),
      ),
    );
  }
}

// Inline Countdown Widget Component
class EtaTrackingWidget extends StatefulWidget {
  final int initialEtaMinutes;

  const EtaTrackingWidget({super.key, required this.initialEtaMinutes});

  @override
  State<EtaTrackingWidget> createState() => _EtaTrackingWidgetState();
}

class _EtaTrackingWidgetState extends State<EtaTrackingWidget> {
  Timer? _timer;
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialEtaMinutes * 60;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.shield_rounded, color: Colors.green, size: 56),
          const SizedBox(height: 12),
          const Text(
            'HELP IS ON THE WAY!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Rescue team dispatched by Disaster Management Admin.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Text(
            _formatTime(_remainingSeconds),
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
          const Text(
            'ESTIMATED TIME OF ARRIVAL',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}