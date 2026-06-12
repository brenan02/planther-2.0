import 'package:supabase_flutter/supabase_flutter.dart';

class GardenPlant {
  final String id;
  final String plantName;
  final String? scientificName;
  final String? notes;
  final String? imageUrl;
  final String emoji;
  final DateTime dateAcquired;

  GardenPlant({
    required this.id,
    required this.plantName,
    this.scientificName,
    this.notes,
    this.imageUrl,
    required this.emoji,
    required this.dateAcquired,
  });

  factory GardenPlant.fromJson(Map<String, dynamic> json) {
    return GardenPlant(
      id: json['id'] as String,
      plantName: json['plant_name'] ?? '',
      scientificName: json['scientific_name'],
      notes: json['notes'] ?? '',
      imageUrl: json['image_url'],
      emoji: json['emoji'] ?? '🌿',
      dateAcquired: DateTime.parse(json['date_acquired']),
    );
  }
}

class GardenService {
  final _client = Supabase.instance.client;

  Future<void> addPlant({
    required String plantName,
    String? scientificName,
    String? notes,
    String? imageUrl,
    String emoji = '🌿',
  }) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('garden_plants').insert({
      'user_id': userId,
      'plant_name': plantName,
      'scientific_name': scientificName,
      'notes': notes ?? '',
      'image_url': imageUrl,
      'emoji': emoji,
    });
  }

  Future<List<GardenPlant>> getGarden() async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('garden_plants')
        .select()
        .eq('user_id', userId)
        .order('date_acquired', ascending: false);

    return (data as List)
        .map((e) => GardenPlant.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updatePlant({
    required String id,
    required String plantName,
    String? scientificName,
    String? notes,
  }) async {
    await _client.from('garden_plants').update({
      'plant_name': plantName,
      'scientific_name': scientificName,
      'notes': notes ?? '',
    }).eq('id', id);
  }

  Future<void> deletePlant(String id) async {
    await _client.from('garden_plants').delete().eq('id', id);
  }
}