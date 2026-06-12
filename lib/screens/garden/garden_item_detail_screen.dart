import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plant.plantName);
    _sciNameController =
        TextEditingController(text: widget.plant.scientificName ?? '');
    _notesController = TextEditingController(text: widget.plant.notes ?? '');
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _saveAll() async {
    try {
      await _gardenService.updatePlant(
        id: widget.plant.id,
        plantName: _nameController.text.trim(),
        scientificName: _sciNameController.text.trim().isEmpty
            ? null
            : _sciNameController.text.trim(),
        notes: _notesController.text.trim(),
      );
      _changed = true;
      _showMessage('Saved!');
      setState(() => _isEditingName = false);
    } catch (_) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Remove plant',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
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
        Navigator.of(context).pop(true);
      } catch (_) {
        _showMessage('Could not remove plant.', isError: true);
      }
    }
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
              // ── top bar ──────────────────────────────────────────
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
                      // Edit toggle
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
                            _isEditingName ? Icons.check : Icons.edit_outlined,
                            size: 18,
                            color: _isEditingName
                                ? Colors.white
                                : const Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Delete
                      GestureDetector(
                        onTap: _confirmDelete,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.redAccent.withOpacity(0.3)),
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

              // ── image ────────────────────────────────────────────
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D6A4F).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                clipBehavior: Clip.hardEdge,
                child: widget.plant.imageUrl != null
                    ? Image.network(
                        widget.plant.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(widget.plant.emoji,
                              style: const TextStyle(fontSize: 64)),
                        ),
                      )
                    : Center(
                        child: Text(widget.plant.emoji,
                            style: const TextStyle(fontSize: 64)),
                      ),
              ),

              const SizedBox(height: 24),

              // ── name / scientific name ─────────────────────────────
              if (_isEditingName) ...[
                TextField(
                  controller: _nameController,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                  decoration: const InputDecoration(labelText: 'Plant name'),
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
                    labelText: 'Scientific name (optional)',
                  ),
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

              // ── date acquired ───────────────────────────────────
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

              // ── notes ─────────────────────────────────────────────
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
                    borderSide: const BorderSide(color: Color(0xFFDDD8D0)),
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