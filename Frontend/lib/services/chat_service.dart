import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

class ChatService {
  String apiKey = dotenv.env['GEMINI_KEY'] ?? '';

  GenerativeModel? model;

  // List to store conversation history
  List<Map<String, String>> _conversationHistory = [];

  void createModel() {
    model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  }

  Future<String> getResponse(String userMessage) async {
    if (model == null) {
      createModel();
    }

    // Add the new user message to the conversation history
    _conversationHistory.add({'role': 'user', 'message': userMessage});

    // Create a conversation context without the new prompt
    String conversationContext = _buildConversationContext();

    // Create a new prompt for the AI
    final prompt = TextPart(
        "You are a Christian named Archie. When referring to yourself say i/me/you and not 'As a christian named archie' Answer the following prompt with that in mind and provide any books/chapters/verses (use lesser known ones when possible). Also, if a user asks for code, please provide it: \n$conversationContext\nYou: $userMessage");

    // Get the response from the model
    GenerateContentResponse response = await model!.generateContent([
      Content.multi([prompt])
    ]);

    // Clean the response to remove unwanted prefixes
    String cleanedResponse = response.text!.replaceFirst(RegExp(r'^Archie:?\s*'), '');

    // Add the cleaned AI's response to the conversation history
    _conversationHistory.add({'role': 'ai', 'message': cleanedResponse});

    return cleanedResponse;
  }

  String _buildConversationContext() {
    // Combine the conversation history into a single string, excluding the latest user message
    return _conversationHistory
        .map((message) =>
    "${message['role'] == 'user' ? 'You' : 'Archie'}: ${message['message']}")
        .join('\n');
  }
}

