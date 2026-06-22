import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_service.dart';
import 'perenual_service.dart';

class SurveyService {
  final _client = Supabase.instance.client;
  final _aiService = AIService();

  // ── SUBMIT SURVEY ─────────────────────────────────────────────────────────
  Future<List<PlantRecommendation>> submitSurvey(
    Map<String, String> answers,
  ) async {
    final userId = _client.auth.currentUser!.id;

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

    final recommendations =
        await _aiService.getRecommendations(surveyAnswers: answers);
    final enriched =
        await PerenualService().enrichWithImages(recommendations);

    await _client
        .from('recommendations')
        .delete()
        .eq('user_id', userId);

    final rows = enriched
        .map((r) => {
              'user_id': userId,
              'survey_id': surveyId,
              ...r.toMap(),
            })
        .toList();

    await _client.from('recommendations').insert(rows);
    return enriched;
  }

  // ── REFRESH RECOMMENDATIONS (no new survey needed) ────────────────────────
  // Uses the latest saved survey answers to get a fresh set of AI suggestions
  Future<List<PlantRecommendation>> refreshRecommendations() async {
    final userId = _client.auth.currentUser!.id;

    // Load latest survey answers
    final latestSurvey = await _client
        .from('surveys')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (latestSurvey == null) {
      throw Exception('No survey found. Please take the survey first.');
    }

    final answers = {
      'experience': latestSurvey['experience'] as String,
      'environment': latestSurvey['environment'] as String,
      'lighting': latestSurvey['lighting'] as String,
      'maintenance': latestSurvey['maintenance'] as String,
      'space': latestSurvey['space'] as String,
      'purpose': latestSurvey['purpose'] as String,
      'petSafe': latestSurvey['pet_safe'] as String,
    };

    final surveyId = latestSurvey['id'] as String;

    // Get fresh AI recommendations
    final recommendations =
        await _aiService.getRecommendations(surveyAnswers: answers);
    final enriched =
        await PerenualService().enrichWithImages(recommendations);

    // Replace old recommendations
    await _client
        .from('recommendations')
        .delete()
        .eq('user_id', userId);

    final rows = enriched
        .map((r) => {
              'user_id': userId,
              'survey_id': surveyId,
              ...r.toMap(),
            })
        .toList();

    await _client.from('recommendations').insert(rows);
    return enriched;
  }

  // ── LOAD SAVED RECOMMENDATIONS ────────────────────────────────────────────
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

  // ── HAS RECOMMENDATIONS ───────────────────────────────────────────────────
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