import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:planther/services/garden_service.dart';

class GardenItemDetailScreen extends StatefulWidget {
  final GardenPlant plant;
  const GardenItemDetailScreen({super.key, required this.plant});

  @override
  State<GardenItemDetailScreen> createState() =>
      _GardenItemDetailScreenState();
}

class _GardenItemDetailScreenState extends State<GardenItemDetailScreen> {
  final _gardenService = GardenService();

  late TextEditingController _nameController;
  late TextEditingController _sciNameController;
  late TextEditingController _notesController;

  bool _isEditingName = false;
  bool _isSavingNotes = false;
  bool _changed = false;

  // ── image state ────────────────────────────────────────────────────────────
  File? _newImage;           // newly picked image (not yet saved)
  String? _currentImageUrl;  // current saved image URL
  bool _removeImage = false; // user wants to remove the image
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plant.plantName);
    _sciNameController =
        TextEditingController(text: widget.plant.scientificName ?? '');
    _notesController = TextEditingController(text: widget.plant.notes ?? '');
    _currentImageUrl = widget.plant.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sciNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? Colors.redAccent : const Color(0xFF2D6A4F),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── pick image from gallery ────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _newImage = File(picked.path);
        _removeImage = false;
      });
    }
  }

  // ── save everything including image ───────────────────────────────────────
  Future<void> _saveAll() async {
    try {
      String? imageUrl = _currentImageUrl;

      // Upload new image if picked
      if (_newImage != null) {
        setState(() => _isUploadingImage = true);
        imageUrl = await _gardenService.uploadImage(_newImage!);
        setState(() {
          _isUploadingImage = false;
          _currentImageUrl = imageUrl;
          _newImage = null;
        });
      } else if (_removeImage) {
        imageUrl = null;
        setState(() {
          _currentImageUrl = null;
          _removeImage = false;
        });
      }

      await _gardenService.updatePlant(
        id: widget.plant.id,
        plantName: _nameController.text.trim(),
        scientificName: _sciNameController.text.trim().isEmpty
            ? null
            : _sciNameController.text.trim(),
        notes: _notesController.text.trim(),
        imageUrl: imageUrl,
      );

      _changed = true;
      _showMessage('Saved!');
      setState(() => _isEditingName = false);
    } catch (e) {
      setState(() => _isUploadingImage = false);
      _showMessage('Could not save changes.', isError: true);
    }
  }

  Future<void> _saveNotesOnly() async {
    setState(() => _isSavingNotes = true);
    try {
      await _gardenService.updatePlant(
        id: widget.plant.id,
        plantName: _nameController.text.trim(),
        scientificName: _sciNameController.text.trim().isEmpty
            ? null
            : _sciNameController.text.trim(),
        notes: _notesController.text.trim(),
        imageUrl: _currentImageUrl,
      );
      _changed = true;
      _showMessage('Notes saved!');
    } catch (_) {
      _showMessage('Could not save notes.', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingNotes = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove plant',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        content: Text(
          'Remove "${widget.plant.plantName}" from your garden?',
          style: const TextStyle(color: Color(0xFF8A8578), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF8A8578))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _gardenService.deletePlant(widget.plant.id);
        if (!mounted) return;
        Navigator.of(context).pop('deleted');
      } catch (_) {
        _showMessage('Could not remove plant.', isError: true);
      }
    }
  }

  // ── build the image area ───────────────────────────────────────────────────
  Widget _buildImageArea() {
    Widget imageContent;

    if (_newImage != null) {
      // Show newly picked image (not yet saved)
      imageContent = Image.file(_newImage!, fit: BoxFit.cover);
    } else if (!_removeImage && _currentImageUrl != null) {
      // Show current saved image
      imageContent = Image.network(
        _currentImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildEmojiPlaceholder(),
      );
    } else {
      // No image — show emoji placeholder
      imageContent = _buildEmojiPlaceholder();
    }

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            color: const Color(0xFF2D6A4F).withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.hardEdge,
          child: imageContent,
        ),

        // Edit mode overlay buttons
        if (_isEditingName)
          Positioned(
            bottom: 12,
            right: 12,
            child: Row(
              children: [
                // Change / add photo button
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.photo_camera_outlined,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _currentImageUrl != null || _newImage != null
                              ? 'Change photo'
                              : 'Add photo',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),

                // Remove photo button — only if there's an image
                if ((_currentImageUrl != null && !_removeImage) ||
                    _newImage != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() {
                      _removeImage = true;
                      _newImage = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ],
            ),
          ),

        // Uploading indicator
        if (_isUploadingImage)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmojiPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.plant.emoji,
              style: const TextStyle(fontSize: 56)),
          if (_isEditingName) ...[
            const SizedBox(height: 8),
            Text('Tap "Add photo" to add an image',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500)),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('MMMM d, yyyy').format(widget.plant.dateAcquired);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── top bar ────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(_changed),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDDD8D0)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          size: 16, color: Color(0xFF1A1A1A)),
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_isEditingName) {
                            _saveAll();
                          } else {
                            setState(() => _isEditingName = true);
                          }
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _isEditingName
                                ? const Color(0xFF2D6A4F)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFDDD8D0)),
                          ),
                          child: Icon(
                            _isEditingName
                                ? Icons.check
                                : Icons.edit_outlined,
                            size: 18,
                            color: _isEditingName
                                ? Colors.white
                                : const Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _confirmDelete,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    Colors.redAccent.withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.delete_outline,
                              size: 18, color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── image area (now with edit controls) ────────────────
              _buildImageArea(),

              const SizedBox(height: 24),

              // ── name / scientific name ──────────────────────────────
              if (_isEditingName) ...[
                TextField(
                  controller: _nameController,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                  decoration:
                      const InputDecoration(labelText: 'Plant name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _sciNameController,
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF8A8578),
                  ),
                  decoration: const InputDecoration(
                      labelText: 'Scientific name (optional)'),
                ),
              ] else ...[
                Text(
                  _nameController.text,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                if (_sciNameController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _sciNameController.text,
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF8A8578),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 16),

              // ── date acquired ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEEEAE2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: Color(0xFF8A8578)),
                    const SizedBox(width: 10),
                    Text(
                      'Date acquired: $dateStr',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8A8578),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── notes ───────────────────────────────────────────────
              const Text(
                'Notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notesController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Write any notes about this plant...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Color(0xFFDDD8D0)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isSavingNotes ? null : _saveNotesOnly,
                child: _isSavingNotes
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Notes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}