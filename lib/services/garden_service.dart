import 'dart:io';
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

  Map<String, dynamic> toMap() {
    return {
      'plant_name': plantName,
      'scientific_name': scientificName,
      'notes': notes ?? '',
      'image_url': imageUrl,
      'emoji': emoji,
      'date_acquired': dateAcquired.toIso8601String(),
    };
  }
}

class GardenService {
  final _client = Supabase.instance.client;

  // ── CHECK DUPLICATE ────────────────────────────────────────────────────────
  Future<bool> plantExists(String plantName) async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('garden_plants')
        .select('id')
        .eq('user_id', userId)
        .ilike('plant_name', plantName.trim())
        .maybeSingle();
    return data != null;
  }

  // ── ADD PLANT — returns false if already exists ────────────────────────────
  Future<bool> addPlant({
    required String plantName,
    String? scientificName,
    String? notes,
    String? imageUrl,
    String emoji = '🌿',
    DateTime? dateAcquired,
  }) async {
    final userId = _client.auth.currentUser!.id;

    final exists = await plantExists(plantName);
    if (exists) return false;

    await _client.from('garden_plants').insert({
      'user_id': userId,
      'plant_name': plantName,
      'scientific_name': scientificName,
      'notes': notes ?? '',
      'image_url': imageUrl,
      'emoji': emoji,
      if (dateAcquired != null)
        'date_acquired': dateAcquired.toIso8601String(),
    });
    return true;
  }

  // ── GET GARDEN ─────────────────────────────────────────────────────────────
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

  // ── UPDATE PLANT ───────────────────────────────────────────────────────────
  Future<void> updatePlant({
    required String id,
    required String plantName,
    String? scientificName,
    String? notes,
    String? imageUrl,
  }) async {
    await _client.from('garden_plants').update({
      'plant_name': plantName,
      'scientific_name': scientificName,
      'notes': notes ?? '',
      'image_url': imageUrl,
    }).eq('id', id);
  }

  // ── DELETE PLANT ───────────────────────────────────────────────────────────
  Future<void> deletePlant(String id) async {
    await _client.from('garden_plants').delete().eq('id', id);
  }

  // ── UPLOAD IMAGE ───────────────────────────────────────────────────────────
  Future<String> uploadImage(File file) async {
    final userId = _client.auth.currentUser!.id;
    final fileName =
        '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _client.storage
        .from('garden-images')
        .upload(fileName, file,
            fileOptions: const FileOptions(upsert: true));

    return _client.storage
        .from('garden-images')
        .getPublicUrl(fileName);
  }
}