import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:planther/core/constants.dart';
import 'ai_service.dart';

class PerenualService {
  static const String _base = 'https://perenual.com/api';

  // Search for a plant by name and return image URL + ID
  Future<Map<String, dynamic>?> searchPlant(String plantName) async {
    final uri = Uri.parse(
      '$_base/species-list?key=$perenualApiKey&q=${Uri.encodeComponent(plantName)}&page=1',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    final results = data['data'] as List?;
    if (results == null || results.isEmpty) return null;

    final first = results[0];
    final imageUrl = first['default_image']?['regular_url'] as String?;
    final id = first['id'] as int?;

    return {'imageUrl': imageUrl, 'id': id};
  }

  // Get full plant details by Perenual ID
  Future<Map<String, dynamic>?> getPlantDetails(int plantId) async {
    final uri = Uri.parse(
      '$_base/species/details/$plantId?key=$perenualApiKey',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return null;

    return jsonDecode(response.body);
  }

  // Add this method to PerenualService
Future<String?> getWikipediaImage(String plantName) async {
  try {
    final encoded = Uri.encodeComponent(plantName);
    final uri = Uri.parse(
      'https://en.wikipedia.org/api/rest_v1/page/summary/$encoded',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    return data['thumbnail']?['source'] as String?;
  } catch (_) {
    return null;
  }
}

// Update enrichWithImages() to use Wikipedia as fallback:
Future<List<PlantRecommendation>> enrichWithImages(
  List<PlantRecommendation> recommendations,
) async {
  final enriched = <PlantRecommendation>[];

  for (final plant in recommendations) {
    try {
      final cleanName = plant.plantName.split('(')[0].trim();
      final result = await searchPlant(cleanName);
      String? imageUrl = result?['imageUrl'];

      // If Perenual has no image, try Wikipedia
      if (imageUrl == null) {
        imageUrl = await getWikipediaImage(plant.scientificName)
            ?? await getWikipediaImage(plant.plantName);
      }

      enriched.add(PlantRecommendation(
        plantName: plant.plantName,
        scientificName: plant.scientificName,
        reason: plant.reason,
        careLevel: plant.careLevel,
        emoji: plant.emoji,
        imageUrl: imageUrl,
        perenualId: result?['id'],
      ));
    } catch (_) {
      enriched.add(plant);
    }
  }

  return enriched;
  }
}