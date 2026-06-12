import 'package:flutter/material.dart';
import 'package:planther/services/ai_service.dart';
import 'plant_detail_screen.dart';
import 'package:planther/services/garden_service.dart';
import 'package:planther/widgets/garden_toast.dart';

class PlantCardView extends StatefulWidget {
  final List<PlantRecommendation> plants;

  const PlantCardView({super.key, required this.plants});

  @override
  State<PlantCardView> createState() => _PlantCardViewState();
}

class _PlantCardViewState extends State<PlantCardView> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Full screen page view of plant cards
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemCount: widget.plants.length,
            itemBuilder: (context, index) {
              final plant = widget.plants[index];
              return _buildPlantCard(plant);
            },
          ),
        ),

        const SizedBox(height: 16),

        // Page indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.plants.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentIndex == i ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentIndex == i
                    ? const Color(0x4b986c)
                    : const Color(0xFFDDD8D0),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPlantCard(PlantRecommendation plant) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF1A2E1F),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Plant image — full card
          if (plant.imageUrl != null)
            Image.network(
              plant.imageUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: const Color(0xFF1A2E1F),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0x4b986c),
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => _buildImageFallback(plant),
            )
          else
            _buildImageFallback(plant),

          // Dark gradient overlay at bottom
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.85),
                  ],
                  stops: const [0.0, 0.45, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // Plant info at bottom left
          Positioned(
            left: 24,
            right: 24,
            bottom: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  plant.plantName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Georgia',
                    height: 1.1,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  plant.scientificName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            PlantDetailScreen(plant: plant),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'See more',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Care level badge top right
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                '${plant.emoji}  ${plant.careLevel}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          
          Positioned(
            right: 20,
            bottom: 28,
            child: GestureDetector(
             onTap: () async {
                try {
                  await GardenService().addPlant(
                    plantName: plant.plantName,
                    scientificName: plant.scientificName,
                    imageUrl: plant.imageUrl,
                    emoji: plant.emoji,
                    );
                  if (context.mounted) showAddedToGardenToast(context);
                  } catch (_) {
                  // fail silently or show error
                }
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D6A4F),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageFallback(PlantRecommendation plant) {
    return Container(
      color: const Color(0xFF1A2E1F),
      child: Center(
        child: Text(
          plant.emoji,
          style: const TextStyle(fontSize: 80),
        ),
      ),
    );
  }
}