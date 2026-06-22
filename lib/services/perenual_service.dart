import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:planther/core/constants.dart';
import 'ai_service.dart';

class PerenualService {
  static const String _base = 'https://perenual.com/api';

  // Detect Perenual's "upgrade required" placeholder URLs
  static bool _isBadUrl(String? url) {
    if (url == null || url.isEmpty) return true;
    if (url.contains('upgrade_access')) return true;
    if (url.contains('upgrade-plan')) return true;
    if (url.contains('no_image')) return true;
    return false;
  }

  Future<Map<String, dynamic>?> searchPlant(String name) async {
    try {
      final uri = Uri.parse(
          '$_base/species-list?key=$perenualApiKey&q=${Uri.encodeComponent(name)}&page=1');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final results = (jsonDecode(res.body)['data'] as List?) ?? [];
      if (results.isEmpty) return null;
      final first = results[0];
      final url = first['default_image']?['regular_url'] as String?;
      return {
        'imageUrl': _isBadUrl(url) ? null : url,
        'id': first['id'],
      };
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getPlantDetails(int plantId) async {
    try {
      final uri = Uri.parse('$_base/species/details/$plantId?key=$perenualApiKey');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body);
    } catch (_) {
      return null;
    }
  }

  // Wikipedia REST summary thumbnail
  Future<String?> _wikiSummaryImage(String term) async {
    try {
      final clean = term.split('(')[0].trim();
      final res = await http
          .get(Uri.parse(
              'https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(clean)}'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final url = jsonDecode(res.body)['thumbnail']?['source'] as String?;
      if (url == null) return null;
      // Upscale the thumbnail
      return url.replaceAll(RegExp(r'/\d+px-'), '/800px-');
    } catch (_) {
      return null;
    }
  }

  // Wikimedia API — often higher quality than REST summary
  Future<String?> _wikimediaImage(String term) async {
    try {
      final clean = term.split('(')[0].trim();
      final res = await http
          .get(Uri.parse(
              'https://en.wikipedia.org/w/api.php?action=query&titles=${Uri.encodeComponent(clean)}&prop=pageimages&format=json&pithumbsize=800'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final pages = jsonDecode(res.body)['query']?['pages'] as Map?;
      if (pages == null) return null;
      for (final p in pages.values) {
        final url = p['thumbnail']?['source'] as String?;
        if (url != null) return url;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // iNaturalist — great for Philippine plants and biodiversity photos
  Future<String?> _iNaturalistImage(String scientificName) async {
    try {
      final clean = scientificName.split('(')[0].trim();
      final res = await http
          .get(Uri.parse(
              'https://api.inaturalist.org/v1/taxa?q=${Uri.encodeComponent(clean)}&rank=species&per_page=1'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final results = jsonDecode(res.body)['results'] as List?;
      if (results == null || results.isEmpty) return null;
      return results[0]['default_photo']?['medium_url'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── Main enrichment fallback chain ────────────────────────────────
  Future<List<PlantRecommendation>> enrichWithImages(
  List<PlantRecommendation> recommendations,
) async {
  final enriched = <PlantRecommendation>[];

  for (final plant in recommendations) {
    final cleanName = plant.plantName.split('(')[0].trim();
    String? imageUrl;
    int? perenualId;

    // 1. Perenual by SCIENTIFIC name first (most accurate)
    if (plant.scientificName.isNotEmpty) {
      final p1 = await searchPlant(plant.scientificName);
      imageUrl = p1?['imageUrl'] as String?;
      perenualId = p1?['id'] as int?;
    }

    // 2. Perenual by common name
    if (imageUrl == null) {
      final p2 = await searchPlant(cleanName);
      imageUrl = p2?['imageUrl'] as String?;
      perenualId ??= p2?['id'] as int?;
    }

    // 3. iNaturalist by SCIENTIFIC name
    if (imageUrl == null) {
      imageUrl = await _iNaturalistImage(plant.scientificName);
    }

    // 4. Wikipedia REST by SCIENTIFIC name
    if (imageUrl == null) {
      imageUrl = await _wikiSummaryImage(plant.scientificName);
    }

    // 5. Wikimedia API by SCIENTIFIC name
    if (imageUrl == null) {
      imageUrl = await _wikimediaImage(plant.scientificName);
    }

    // 6. iNaturalist by common name (last resort)
    if (imageUrl == null) {
      imageUrl = await _iNaturalistImage(cleanName);
    }

    // 7. Wikipedia by common name (absolute last resort)
    if (imageUrl == null) {
      imageUrl = await _wikiSummaryImage(cleanName);
    }

    enriched.add(PlantRecommendation(
      plantName: plant.plantName,
      scientificName: plant.scientificName,
      reason: plant.reason,
      careLevel: plant.careLevel,
      emoji: plant.emoji,
      imageUrl: imageUrl,
      perenualId: perenualId,
    ));
  }

  return enriched;
}
}