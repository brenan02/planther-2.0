import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_service.dart';
import 'perenual_service.dart'; 

class SurveyService {
  final _client = Supabase.instance.client;
  final _aiService = AIService();

  // Save survey + get AI recommendations + save recommendations
  Future<List<PlantRecommendation>> submitSurvey(
    Map<String, String> answers,
    
  ) async {
    final userId = _client.auth.currentUser!.id;

    // 1. Save survey answers to Supabase
    final surveyResponse = await _client
        .from('surveys')
        .insert({
          'user_id': userId,
          'experience': answers['experience'],
          'environment': answers['environment'],
          'lighting': answers['lighting'],
          'maintenance': answers['maintenance'],
          'space': answers['space'],
          'purpose': answers['purpose'],
          'pet_safe': answers['petSafe'],
        })
        .select()
        .single();

    final surveyId = surveyResponse['id'];

    // 2. Get AI recommendations
    final recommendations =
        await _aiService.getRecommendations(surveyAnswers: answers);

    final enriched =
        await PerenualService().enrichWithImages(recommendations);

    // 3. Delete old recommendations for this user
    await _client
        .from('recommendations')
        .delete()
        .eq('user_id', userId);

    // 4. Save new recommendations to Supabase
    final recommendationRows = enriched.map((r) => {
      'user_id': userId,
      'survey_id': surveyId,
      ...r.toMap(),
    }).toList();

    await _client.from('recommendations').insert(recommendationRows);

    return enriched;
  }

  // Load saved recommendations from Supabase (no AI call)
  Future<List<PlantRecommendation>> loadRecommendations() async {
    final userId = _client.auth.currentUser!.id;

    final data = await _client
        .from('recommendations')
        .select()
        .eq('user_id', userId)
        .order('created_at');

    return data
        .map((row) => PlantRecommendation.fromJson(row))
        .toList();
  }

  // Check if user has existing recommendations
  Future<bool> hasRecommendations() async {
    final userId = _client.auth.currentUser!.id;

    final data = await _client
        .from('recommendations')
        .select('id')
        .eq('user_id', userId)
        .limit(1);

    return data.isNotEmpty;
  }
}