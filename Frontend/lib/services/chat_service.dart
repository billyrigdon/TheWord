import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

class ChatService {
  String apiKey = dotenv.env['GEMINI_KEY'] ?? '';

  GenerativeModel? model;

  List<Map<String, String>> _conversationHistory = [];

  void createModel() {
    model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  }

  Future<String> getResponse(String userMessage) async {
    if (model == null) {
      createModel();
    }

    _conversationHistory.add({'role': 'user', 'message': userMessage});

    String conversationContext = _buildConversationContext();

    final prompt = TextPart(
        "You are a Christian named Archie. When referring to yourself say i/me/you and not 'As a christian named archie' Answer the following prompt with that in mind and provide any books/chapters/verses (use lesser known ones when possible). Don't repeat the user's request at the beginning of the response or label the response. And don't repeat your own answers either: \n$conversationContext\nYou: $userMessage");

    GenerateContentResponse response = await model!.generateContent([
      Content.multi([prompt])
    ]);

    String cleanedResponse = response.text!.replaceFirst(RegExp(r'^Archie:?\s*'), '');

    _conversationHistory.add({'role': 'ai', 'message': cleanedResponse});

    return cleanedResponse;
  }

  String _buildConversationContext() {
    return _conversationHistory
        .map((message) =>
    "${message['role'] == 'user' ? 'You' : 'Archie'}: ${message['message']}")
        .join('\n');
  }
}

