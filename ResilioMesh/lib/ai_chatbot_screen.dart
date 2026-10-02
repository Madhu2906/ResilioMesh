import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIChatbotScreen extends StatefulWidget {
  const AIChatbotScreen({super.key});

  @override
  State<AIChatbotScreen> createState() => _AIChatbotScreenState();
}

class _AIChatbotScreenState extends State<AIChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // API key is left blank to protect sensitive data on GitHub
  final String _apiKey = '';

  final List<Map<String, String>> _messages = [
    {
      "role": "model",
      "text":
          "Hello! I am your ResilioMesh AI Assistant. How can I help you with emergency preparedness or app features today?",
    },
  ];

  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final String userText = _controller.text.trim();

    if (userText.isEmpty || _isLoading) return;

    _controller.clear();

    setState(() {
      _messages.add({"role": "user", "text": userText});
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      if (_apiKey.trim().isEmpty) {
        setState(() {
          _messages.add({
            "role": "model",
            "text":
                "Gemini API key is missing. Please add your valid Gemini API key in ai_chatbot_screen.dart.",
          });
          _isLoading = false;
        });
        _scrollToBottom();
        return;
      }

      // Initialize Gemini model with the latest stable flash path
      final model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: _apiKey);

      final String prompt =
          '''
You are the AI Assistant for ResilioMesh.
ResilioMesh is a hyper-local disaster resilience and emergency response application.
Your role is to help users with emergency preparedness, safety guidelines, and app features.

User's question:
$userText
''';

      final List<Content> content = [Content.text(prompt)];
      final GenerateContentResponse response = await model.generateContent(
        content,
      );

      final String responseText =
          response.text?.trim() ??
          "I couldn't generate a response. Please try again.";

      if (!mounted) return;

      setState(() {
        _messages.add({"role": "model", "text": responseText});
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _messages.add({
          "role": "model",
          "text":
              "Error connecting to AI.\n\n${e.toString()}\n\nPlease check your internet connection and API key.",
        });
        _isLoading = false;
      });

      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ResilioMesh AI Assistant'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final bool isUser = message['role'] == 'user';

                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.redAccent : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        message['text'] ?? '',
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.black87,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: LinearProgressIndicator(color: Colors.redAccent),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              color: Colors.white,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_isLoading,
                      maxLines: 4,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Ask how can I help you...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _isLoading
                        ? Colors.grey
                        : Colors.redAccent,
                    child: IconButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}