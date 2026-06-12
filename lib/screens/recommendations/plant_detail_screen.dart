import 'package:flutter/material.dart';
import 'package:planther/services/ai_service.dart';
import 'package:planther/services/perenual_service.dart';
import 'package:planther/services/garden_service.dart';
import 'package:planther/widgets/garden_toast.dart';

class PlantDetailScreen extends StatefulWidget {
  final PlantRecommendation plant;

  const PlantDetailScreen({super.key, required this.plant});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  Map<String, dynamic>? _details;
  bool _isLoading = true;
  String _dataSource = 'perenual';

  @override
    void initState() {
    super.initState();
    _loadDetails();
  }

  void _loadDetails() async {
  try {
    Map<String, dynamic>? perenualData;

    // Try Perenual first if we have an ID
    if (widget.plant.perenualId != null) {
      perenualData = await PerenualService()
          .getPlantDetails(widget.plant.perenualId!);
    }

    // Check if Perenual returned useful data
    final hasUsefulData = perenualData != null &&
        (perenualData['watering'] != null ||
            perenualData['sunlight'] != null);

    if (hasUsefulData) {
      if (mounted) setState(() {
        _details = perenualData;
        _dataSource = 'perenual';
        _isLoading = false;
      });
    } else {
      // Fallback to Groq
      final groqData = await AIService().getPlantDetails(
        plantName: widget.plant.plantName,
        scientificName: widget.plant.scientificName,
      );
      if (mounted) setState(() {
        _details = groqData;
        _dataSource = 'groq';
        _isLoading = false;
      });
    }
  } catch (e) {
    // Try Groq if Perenual threw an error
    try {
      final groqData = await AIService().getPlantDetails(
        plantName: widget.plant.plantName,
        scientificName: widget.plant.scientificName,
      );
      if (mounted) setState(() {
        _details = groqData;
        _dataSource = 'groq';
        _isLoading = false;
        
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final plant = widget.plant;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: CustomScrollView(
        slivers: [
          // ── hero image ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.45,
            pinned: true,
            backgroundColor: const Color(0xFF1A1A1A),
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: plant.imageUrl != null
                  ? Image.network(
                      plant.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _fallback(plant.emoji),
                    )
                  : _fallback(plant.emoji),
            ),
          ),

          // ── content ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1C2B20),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(60),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0x4b986c),
                        ),
                      ),
                    )
                  : _buildContent(plant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(PlantRecommendation plant) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + scientific name
          Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Expanded(
      child: Text(
        plant.plantName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          fontFamily: 'Georgia',
          height: 1.1,
        ),
      ),
    ),
    const SizedBox(width: 12),
    GestureDetector(
      onTap: () async {
        try {
          await GardenService().addPlant(
            plantName: plant.plantName,
            scientificName: plant.scientificName,
            imageUrl: plant.imageUrl,
            emoji: plant.emoji,
          );
          if (context.mounted) showAddedToGardenToast(context);
        } catch (_) {}
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF2D6A4F),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 22),
      ),
    ),
  ],
),
          const SizedBox(height: 6),
          Text(
            plant.scientificName,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 15,
              fontStyle: FontStyle.italic,
              fontFamily: 'Georgia',
            ),
          ),

          const SizedBox(height: 16),

          // Why recommended
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0x4b986c).withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0x4b986c).withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                const Text('🌿', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    plant.reason,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          if (_details != null) ...[
            _buildDetailsFromSource(),
          ] else ...[
            _buildSection('Care Level', [
              _buildRow('Difficulty', plant.careLevel),
            ]),
            const SizedBox(height: 16),
            Text(
              'Detailed plant information not available.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 13,
            fontStyle: FontStyle.italic,),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Georgia',
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetSafetyBadge() {
    final poisonous = _details?['poisonous_to_pets'];
    final isSafe = poisonous == false || poisonous == 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSafe
            ? const Color(0x4b986c).withOpacity(0.2)
            : Colors.redAccent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSafe
              ? const Color(0x4b986c).withOpacity(0.4)
              : Colors.redAccent.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Text(
            isSafe ? '🐾' : '⚠️',
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Text(
            isSafe
                ? 'Pet safe — safe around cats and dogs'
                : 'Not pet safe — keep away from pets',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDetailsFromSource() {
  if (_dataSource == 'groq') {
    return _buildGroqDetails();
  }
  return _buildPerenualDetails();
}

Widget _buildPerenualDetails() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSection('Care Level', [
        _buildRow('Difficulty', widget.plant.careLevel),
      ]),

      const SizedBox(height: 24),

      _buildSection('Watering', [
        _buildRow('Frequency', _details!['watering'] ?? 'N/A'),
        if (_details!['watering_notes'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _details!['watering_notes'],
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
      ]),

      const SizedBox(height: 24),

      _buildSection('Sunlight', [
        _buildRow('Light level', _details!['sunlight'] ?? 'N/A'),
        if (_details!['sunlight_notes'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _details!['sunlight_notes'],
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
      ]),

      const SizedBox(height: 24),

      // Pet safety
      _buildPetSafetyBadge(),
    ],
  );
}

Widget _buildGroqDetails() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSection('Basic Information', [
        _buildRow('Plant type', _details!['plant_type'] ?? 'N/A'),
        _buildRow('Height', _details!['height'] ?? 'N/A'),
        _buildRow('Spread', _details!['spread'] ?? 'N/A'),
        _buildRow('Flower', _details!['flower'] ?? 'N/A'),
      ]),

      const SizedBox(height: 24),

      _buildSection('Growing Conditions', [
        _buildRow('Soil type', _details!['soil_type'] ?? 'N/A'),
        _buildRow('Light level', _details!['light_level'] ?? 'N/A'),
      ]),

      const SizedBox(height: 24),

      _buildSection('Watering Frequency', [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            _details!['watering'] ?? 'N/A',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),
      ]),

      const SizedBox(height: 24),

      _buildSection('Care Tips', [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            _details!['care_tips'] ?? 'No tips available',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
      ]),

        const SizedBox(height: 24),

        // Filipino origin badge
        if (_details!['is_native_to_philippines'] == true)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x4b986c).withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0x4b986c).withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                const Text('🇵🇭', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _details!['local_name'] != null
                        ? 'Native Filipino plant — locally known as "${_details!['local_name']}"'
                        : 'Native Filipino plant',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Pet safety
        _buildGroqPetSafetyBadge(),
      ],
    );
  }

  Widget _buildGroqPetSafetyBadge() {
    final isSafe = _details?['is_pet_safe'] == true;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSafe
            ? const Color(0x4b986c).withOpacity(0.2)
            : Colors.redAccent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSafe
              ? const Color(0x4b986c).withOpacity(0.4)
              : Colors.redAccent.withOpacity(0.3),
       ),
     ),
      child: Row(
        children: [
          Text(
            isSafe ? '🐾' : '⚠️',
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Text(
            isSafe
                ? 'Pet safe — safe around cats and dogs'
                : 'Not pet safe — keep away from pets',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String? _extractList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .join(', ');
    }
    return value.toString();
  }

  String _extractDimension(dynamic dimensions, String type) {
    if (dimensions == null) return 'N/A';
    if (dimensions is List) {
      for (final d in dimensions) {
        if (d['type']?.toString().toLowerCase() == type) {
          final min = d['min_value'];
          final max = d['max_value'];
          final unit = d['unit'] ?? '';
          if (min != null && max != null) {
            return '$min - $max $unit';
          }
        }
      }
    }
    return 'N/A';
  }

  Widget _fallback(String emoji) {
    return Container(
      color: const Color(0xFF1A2E1F),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 80)),
      ),
    );
  }
}