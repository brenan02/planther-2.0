import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:planther/core/constants.dart';

class PlantRecommendation {
  final String plantName;
  final String scientificName;
  final String reason;
  final String careLevel;
  final String emoji;
  final String? imageUrl;      
  final int? perenualId;

  PlantRecommendation({
    required this.plantName,
    required this.scientificName,
    required this.reason,
    required this.careLevel,
    required this.emoji,
    this.imageUrl,
    this.perenualId,
  });

  factory PlantRecommendation.fromJson(Map<String, dynamic> json) {
    return PlantRecommendation(
      plantName: json['plant_name'] ?? '',
      scientificName: json['scientific_name'] ?? '',
      reason: json['reason'] ?? '',
      careLevel: json['care_level'] ?? '',
      emoji: json['emoji'] ?? '🌿',
      imageUrl: json['image_url'],
      perenualId: json['perenual_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plant_name': plantName,
      'scientific_name': scientificName,
      'reason': reason,
      'care_level': careLevel,
      'emoji': emoji,
      'image_url': imageUrl,
      'perenual_id': perenualId,
    };
  }
}

class AIService {
  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  Future<List<PlantRecommendation>> getRecommendations({
    required Map<String, String> surveyAnswers,
  }) async {
    final prompt = _buildPrompt(surveyAnswers);

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $groqApiKey',
      },
      body: jsonEncode({
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a plant expert. Always respond with valid JSON only. No markdown, no explanation, just raw JSON.',
          },
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'temperature': 0.7,
        'max_tokens': 1024,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'AI request failed: ${response.statusCode}\n${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    final text =
        data['choices'][0]['message']['content'] as String;

    final jsonString = _extractJson(text);
    final List<dynamic> plantList = jsonDecode(jsonString);

    return plantList
        .map((p) => PlantRecommendation.fromJson(p))
        .toList();
  }

  String _buildPrompt(Map<String, String> answers) {
    return '''
You are a plant expert specializing in plants found in the Philippines.
Based on the user survey answers below, recommend exactly 5 plants.

IMPORTANT RULES:
- Prioritize native Filipino plants and plants commonly found in the Philippines
- If a native Filipino plant fits the user's needs, always prefer it over exotic alternatives
- Include the local Filipino name in parentheses after the common name if one exists (e.g. "Snake Plant (Espada)")
- Only recommend non-Filipino plants if no suitable Filipino plant matches the user's needs

User profile:
- Experience level: ${answers['experience']}
- Living environment: ${answers['environment']}
- Lighting condition: ${answers['lighting']}
- Maintenance preference: ${answers['maintenance']}
- Available space: ${answers['space']}
- Plant purpose: ${answers['purpose']}
- Needs pet-safe plant: ${answers['petSafe']}

Return ONLY a JSON array with exactly 5 objects. Each object must have:
- plant_name: common name (with local Filipino name in parentheses if applicable)
- scientific_name: scientific name
- reason: one sentence why this suits the user based on their answers
- care_level: exactly "Easy", "Moderate", or "Advanced"
- emoji: one plant emoji

Example:
[{"plant_name":"Calamansi (Kalamansi)","scientific_name":"Citrus microcarpa","reason":"A popular Filipino citrus plant perfect for small outdoor spaces","care_level":"Easy","emoji":"🍋"}]
''';
  }

  String _extractJson(String text) {
    final cleaned = text
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    final start = cleaned.indexOf('[');
    final end = cleaned.lastIndexOf(']');

    if (start == -1 || end == -1) {
      throw Exception('No valid JSON found in AI response');
    }

    return cleaned.substring(start, end + 1);
  }
}