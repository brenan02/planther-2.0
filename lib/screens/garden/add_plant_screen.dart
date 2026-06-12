import 'package:flutter/material.dart';
import 'package:planther/services/garden_service.dart';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _nameController = TextEditingController();
  final _sciNameController = TextEditingController();
  final _notesController = TextEditingController();
  final _gardenService = GardenService();
  bool _isSaving = false;

  void _showMessage(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? Colors.redAccent : const Color(0xFF2D6A4F),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      _showMessage('Please enter a plant name');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _gardenService.addPlant(
        plantName: _nameController.text.trim(),
        scientificName: _sciNameController.text.trim().isEmpty
            ? null
            : _sciNameController.text.trim(),
        notes: _notesController.text.trim(),
        emoji: '🌱',
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      _showMessage('Could not add plant. Try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sciNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(false),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDDD8D0)),
                  ),
                  child: const Icon(Icons.close,
                      size: 18, color: Color(0xFF1A1A1A)),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Add a plant',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Add a plant you already own to your garden',
                style: TextStyle(fontSize: 14, color: Color(0xFF8A8578)),
              ),

              const SizedBox(height: 28),

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Plant name',
                  prefixIcon: Icon(Icons.eco_outlined,
                      color: Color(0xFF8A8578), size: 20),
                ),
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _sciNameController,
                decoration: const InputDecoration(
                  labelText: 'Scientific name (optional)',
                  prefixIcon: Icon(Icons.science_outlined,
                      color: Color(0xFF8A8578), size: 20),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Add to Garden'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}