import 'package:flutter/material.dart';
import 'package:planther/services/garden_service.dart';
import 'garden_item_detail_screen.dart';
import 'add_plant_screen.dart';

class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  final _gardenService = GardenService();
  List<GardenPlant> _plants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGarden();
  }

  void _loadGarden() async {
    setState(() => _isLoading = true);
    try {
      final plants = await _gardenService.getGarden();
      if (mounted) setState(() => _plants = plants);
    } catch (_) {
      // silently fail
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Garden',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_plants.length} plant${_plants.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  // "+" button to add a plant manually
                  GestureDetector(
                    onTap: () async {
                      final added = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => const AddPlantScreen(),
                        ),
                      );
                      if (added == true) _loadGarden();
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D6A4F),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.add,
                          color: Colors.white, size: 26),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Body ───────────────────────────────────────────────
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2D6A4F),
                        ),
                      )
                    : _plants.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            color: const Color(0xFF2D6A4F),
                            onRefresh: () async => _loadGarden(),
                            child: GridView.builder(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 24),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.78,
                              ),
                              itemCount: _plants.length,
                              itemBuilder: (context, index) {
                                final plant = _plants[index];
                                return _buildPlantCard(plant);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFF2D6A4F).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🪴', style: TextStyle(fontSize: 44)),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No plants yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add plants from recommendations\nor tap + to add your own',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantCard(GardenPlant plant) {
    return GestureDetector(
      onTap: () async {
        final changed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => GardenItemDetailScreen(plant: plant),
          ),
        );
        if (changed == true) _loadGarden();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEAE2)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            // Image / emoji area
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFF2D6A4F).withOpacity(0.08),
                child: plant.imageUrl != null
                    ? Image.network(
                        plant.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(plant.emoji,
                              style: const TextStyle(fontSize: 32)),
                        ),
                      )
                    : Center(
                        child: Text(plant.emoji,
                            style: const TextStyle(fontSize: 32)),
                      ),
              ),
            ),
            // Name label
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              child: Text(
                plant.plantName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}