import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  File? _selectedImage;
  bool _isSaving = false;
  bool _isUploading = false;

  void _showMessage(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? Colors.redAccent : const Color(0xFF4b986c),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      _showMessage('Please enter a plant name');
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? imageUrl;

      if (_selectedImage != null) {
        setState(() => _isUploading = true);
        imageUrl = await _gardenService.uploadImage(_selectedImage!);
        setState(() => _isUploading = false);
      }

      final added = await _gardenService.addPlant(
        plantName: _nameController.text.trim(),
        scientificName: _sciNameController.text.trim().isEmpty
            ? null
            : _sciNameController.text.trim(),
        notes: _notesController.text.trim(),
        imageUrl: imageUrl,
        emoji: '🌱',
      );

      if (!mounted) return;

      if (!added) {
        _showMessage(
            'A plant with this name already exists in your garden.');
        return;
      }

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
                style:
                    TextStyle(fontSize: 14, color: Color(0xFF8A8578)),
              ),

              const SizedBox(height: 24),

              // ── Image picker ─────────────────────────────────────────
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: const Color(0xFFDDD8D0)),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: _selectedImage != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_selectedImage!,
                                fit: BoxFit.cover),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _selectedImage = null),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 32,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add a photo (optional)',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

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
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(_isUploading
                              ? 'Uploading photo...'
                              : 'Saving...'),
                        ],
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