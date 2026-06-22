import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:planther/core/constants.dart';
import 'ai_service.dart';

class PerenualService {
  static const String _base = 'https://perenual.com/api';

  // ── Bad URL patterns Perenual uses for locked/upgrade-required images ──────
  static bool _isBadImageUrl(String? url) {
    if (url == null || url.isEmpty) return true;
    // Perenual returns these for free-tier locked content
    if (url.contains('upgrade_access')) return true;
    if (url.contains('perenual.com/storage/image/upgrade')) return true;
    if (url.contains('no_image')) return true;
    return false;
  }

  // ── Search Perenual by plant name ──────────────────────────────────────────
  Future<Map<String, dynamic>?> searchPlant(String plantName) async {
    try {
      final uri = Uri.parse(
        '$_base/species-list?key=$perenualApiKey&q=${Uri.encodeComponent(plantName)}&page=1',
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final results = data['data'] as List?;
      if (results == null || results.isEmpty) return null;

      final first = results[0];
      final rawUrl =
          first['default_image']?['regular_url'] as String?;

      // Treat bad URLs as null — we'll fall back to Wikipedia
      final imageUrl = _isBadImageUrl(rawUrl) ? null : rawUrl;
      final id = first['id'] as int?;

      return {'imageUrl': imageUrl, 'id': id};
    } catch (_) {
      return null;
    }
  }

  // ── Get full plant details by Perenual ID ──────────────────────────────────
  Future<Map<String, dynamic>?> getPlantDetails(int plantId) async {
    try {
      final uri = Uri.parse(
        '$_base/species/details/$plantId?key=$perenualApiKey',
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body);
    } catch (_) {
      return null;
    }
  }

  // ── Wikipedia image fetch ──────────────────────────────────────────────────
  Future<String?> getWikipediaImage(String searchTerm) async {
    try {
      // Clean up the search term — remove Filipino name in parentheses
      final clean = searchTerm.split('(')[0].trim();
      final encoded = Uri.encodeComponent(clean);

      final uri = Uri.parse(
        'https://en.wikipedia.org/api/rest_v1/page/summary/$encoded',
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final url = data['thumbnail']?['source'] as String?;

      // Wikipedia thumbnail is usually small — try to get original size
      if (url != null) {
        // Replace /thumb/ path with full image if possible
        final biggerUrl =
            url.replaceAll(RegExp(r'/\d+px-'), '/800px-');
        return biggerUrl;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Wikimedia Commons search (better quality than Wikipedia summary) ────────
  Future<String?> getWikimediaImage(String plantName) async {
    try {
      final clean = plantName.split('(')[0].trim();
      final encoded = Uri.encodeComponent(clean);

      final uri = Uri.parse(
        'https://en.wikipedia.org/w/api.php?action=query&titles=$encoded&prop=pageimages&format=json&pithumbsize=800',
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final pages = data['query']?['pages'] as Map?;
      if (pages == null) return null;

      for (final page in pages.values) {
        final url = page['thumbnail']?['source'] as String?;
        if (url != null) return url;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Enrich recommendations with images ─────────────────────────────────────
  // Strategy: Perenual first → Wikipedia summary → Wikimedia API → null
  Future<List<PlantRecommendation>> enrichWithImages(
    List<PlantRecommendation> recommendations,
  ) async {
    final enriched = <PlantRecommendation>[];

    for (final plant in recommendations) {
      try {
        // Strip Filipino name from common name for better search results
        final cleanName = plant.plantName.split('(')[0].trim();

        // 1. Try Perenual by common name
        final perenualResult = await searchPlant(cleanName);
        String? imageUrl = perenualResult?['imageUrl'];
        int? perenualId = perenualResult?['id'];

        // 2. If Perenual has no image, try by scientific name
        if (imageUrl == null && plant.scientificName.isNotEmpty) {
          final sciResult = await searchPlant(plant.scientificName);
          imageUrl = sciResult?['imageUrl'];
          perenualId ??= sciResult?['id'];
        }

        // 3. Try Wikipedia summary thumbnail
        if (imageUrl == null) {
          imageUrl = await getWikipediaImage(plant.scientificName);
        }

        // 4. Try Wikipedia with common name
        if (imageUrl == null) {
          imageUrl = await getWikipediaImage(cleanName);
        }

        // 5. Try Wikimedia Commons API
        if (imageUrl == null) {
          imageUrl = await getWikimediaImage(plant.scientificName);
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
      } catch (_) {
        // Keep the plant without an image rather than dropping it
        enriched.add(plant);
      }
    }

    return enriched;
  }
}