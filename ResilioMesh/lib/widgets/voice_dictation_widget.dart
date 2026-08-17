import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceDictationWidget extends StatefulWidget {
  final ValueChanged<String> onTextChanged;
  final bool isDisabled;

  const VoiceDictationWidget({
    super.key,
    required this.onTextChanged,
    this.isDisabled = false,
  });

  @override
  State<VoiceDictationWidget> createState() => _VoiceDictationWidgetState();
}

class _VoiceDictationWidgetState extends State<VoiceDictationWidget> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _dictatedText = "";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<void> _toggleListening() async {
    if (widget.isDisabled) return;

    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (error) {
          if (mounted) setState(() => _isListening = false);
        },
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            if (mounted) {
              setState(() {
                _dictatedText = result.recognizedWords;
              });
              widget.onTextChanged(_dictatedText);
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _clearText() {
    setState(() {
      _dictatedText = "";
    });
    widget.onTextChanged("");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isListening ? Colors.red.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isListening ? const Color(0xFFFF5252) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: _isListening ? const Color(0xFFFF5252) : Colors.grey.shade700,
              size: 26,
            ),
            onPressed: widget.isDisabled ? null : _toggleListening,
          ),
          Expanded(
            child: Text(
              _isListening
                  ? "Listening... Speak emergency details."
                  : (_dictatedText.isNotEmpty
                      ? "\"$_dictatedText\""
                      : "Tap mic to dictate voice details"),
              style: TextStyle(
                fontSize: 13,
                color: _isListening ? const Color(0xFFFF5252) : Colors.grey.shade700,
                fontWeight: _isListening ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (_dictatedText.isNotEmpty && !_isListening)
            IconButton(
              icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
              onPressed: widget.isDisabled ? null : _clearText,
            ),
        ],
      ),
    );
  }
}