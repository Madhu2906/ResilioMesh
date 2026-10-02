import 'dart:async';
import 'package:flutter/material.dart';

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
        setState(() {
          _remainingSeconds--;
        });
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
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
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
            'Rescue team has been dispatched to your location.',
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