import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:planther/core/constants.dart';

class CareGuide {
  final String title;
  final String summary;
  final List<String> tips;
  final String icon;

  CareGuide({
    required this.title,
    required this.summary,
    required this.tips,
    required this.icon,
  });

  factory CareGuide.fromJson(Map<String, dynamic> json) {
    return CareGuide(
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
      tips: List<String>.from(json['tips'] ?? []),
      icon: json['icon'] ?? '🌿',
    );
  }
}

class CareGuideService {
  final _client = Supabase.instance.client;

  // Load latest survey answers for the current user
  Future<Map<String, String>?> _getLatestSurveyAnswers() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _client
        .from('surveys')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) return null;

    return {
      'experience': data['experience'] ?? '',
      'environment': data['environment'] ?? '',
      'lighting': data['lighting'] ?? '',
      'maintenance': data['maintenance'] ?? '',
    };
  }

  // Generate personalized care guides using Groq
  Future<List<CareGuide>> getPersonalizedGuides() async {
    final answers = await _getLatestSurveyAnswers();

    // If no survey yet, return generic beginner guides
    final experience = answers?['experience'] ?? 'Beginner';
    final environment = answers?['environment'] ?? 'Indoor';
    final lighting = answers?['lighting'] ?? 'Low';
    final maintenance = answers?['maintenance'] ?? 'Low';

    final prompt = '''
You are a plant care expert. Generate exactly 4 personalized plant care guides for a user with this profile:
- Experience level: $experience
- Living environment: $environment
- Lighting condition: $lighting
- Maintenance preference: $maintenance

Each guide must be specifically relevant to this user's profile. 
Tailor the title, content, and tips to match their exact experience level, environment, lighting, and maintenance preference.

Return ONLY a valid JSON array with exactly 4 objects. Each object must have:
- title: short guide title (max 6 words)
- summary: 2-sentence explanation of what this guide covers and why it matters for this specific user
- tips: array of exactly 4 practical, specific tips for this user's situation
- icon: single relevant emoji

Example format:
[{"title":"Beginner Plant Care Basics","summary":"Starting your plant journey can feel overwhelming. This guide covers the essential habits every new plant owner needs.","tips":["Water only when the top inch of soil is dry","Place plants near north or east-facing windows for gentle light","Use well-draining potting mix to prevent root rot","Start with one or two plants before expanding your collection"],"icon":"🌱"}]
''';

    final response = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
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
                'You are a plant care expert. Always respond with valid JSON only. No markdown, no explanation.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
        'max_tokens': 1500,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to generate care guides');
    }

    final data = jsonDecode(response.body);
    final text = data['choices'][0]['message']['content'] as String;

    final cleaned = text
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    final start = cleaned.indexOf('[');
    final end = cleaned.lastIndexOf(']');
    if (start == -1 || end == -1) throw Exception('Invalid response');

    final List<dynamic> list =
        jsonDecode(cleaned.substring(start, end + 1));
    return list.map((e) => CareGuide.fromJson(e)).toList();
  }

  Future<bool> hasSurveyAnswers() async {
    final answers = await _getLatestSurveyAnswers();
    return answers != null && answers['experience']!.isNotEmpty;
  }
}