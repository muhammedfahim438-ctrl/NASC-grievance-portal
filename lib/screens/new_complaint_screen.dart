// lib/screens/new_complaint_screen.dart
//
// This is the "Report Complaint" form a teacher fills out.
// On submit: images go to Cloudinary first, then we save a Firestore
// document in the 'complaints' collection with fields that EXACTLY
// match what my_complaints_screen.dart expects to read.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../utils/app_colors.dart';
import '../services/cloudinary_service.dart';

class NewComplaintScreen extends StatefulWidget {
  const NewComplaintScreen({super.key});

  @override
  State<NewComplaintScreen> createState() => _NewComplaintScreenState();
}

class _NewComplaintScreenState extends State<NewComplaintScreen> {
  // ---- Form state ----
  String? _selectedBlock;
  String? _selectedFloor;
  final _roomController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategory; // e.g. 'electrical', 'plumbing'
  String _selectedPriority = 'medium'; // default, matches index5.html

  // Picked images live in memory as bytes until we upload them.
  final List<_PickedImage> _pickedImages = [];
  static const int _maxImages = 3;

  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Category options — value is what gets saved to Firestore,
  // label + icon are just for display (matches index5.html grid).
  final List<Map<String, dynamic>> _categories = [
    {'value': 'electrical', 'label': 'Electrical', 'icon': Icons.electrical_services},
    {'value': 'plumbing', 'label': 'Plumbing', 'icon': Icons.plumbing},
    {'value': 'it', 'label': 'IT / Proj.', 'icon': Icons.router},
    {'value': 'carpentry', 'label': 'Carpentry', 'icon': Icons.handyman},
    {'value': 'cleaning', 'label': 'Cleaning', 'icon': Icons.cleaning_services},
    {'value': 'furniture', 'label': 'Furniture', 'icon': Icons.chair},
    {'value': 'wifi', 'label': 'Wi-Fi', 'icon': Icons.wifi},
    {'value': 'other', 'label': 'Other', 'icon': Icons.more_horiz},
  ];

  final List<String> _blocks = ['A Block', 'B Block', 'C Block', 'D Block'];
  final List<String> _floors = [
    'Ground Floor',
    'First Floor',
    'Second Floor',
    'Third Floor',
    'Fourth Floor',
  ];

  @override
  void dispose() {
    _roomController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ---- Image picking ----
  Future<void> _pickImage() async {
    if (_pickedImages.length >= _maxImages) {
      _showSnack('You can attach up to $_maxImages photos.');
      return;
    }

    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85, // light compression at pick-time
    );
    if (file == null) return;

    final rawBytes = await file.readAsBytes();

    // Further compress client-side before upload — keeps Cloudinary
    // usage and upload time down, matches the app's compression rule.
    final compressedBytes = await FlutterImageCompress.compressWithList(
      rawBytes,
      minWidth: 1024,
      minHeight: 1024,
      quality: 70,
    );

    setState(() {
      _pickedImages.add(_PickedImage(bytes: compressedBytes, fileName: file.name));
    });
  }

  void _removeImage(int index) {
    setState(() => _pickedImages.removeAt(index));
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ---- Submit ----
  Future<void> _submitComplaint() async {
    // Basic validation — matches the required fields in the form
    if (_selectedBlock == null) return _showSnack('Please select a block.');
    if (_selectedFloor == null) return _showSnack('Please select a floor.');
    if (_roomController.text.trim().isEmpty) {
      return _showSnack('Please enter a room / facility.');
    }
    if (_selectedCategory == null) return _showSnack('Please select a category.');
    if (_descriptionController.text.trim().isEmpty) {
      return _showSnack('Please describe the issue.');
    }

    setState(() => _isSubmitting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // 1. Upload photos to Cloudinary first (if any were picked)
      List<String> photoUrls = [];
      if (_pickedImages.isNotEmpty) {
        photoUrls = await _cloudinaryService.uploadImages(
          _pickedImages.map((img) => img.bytes).toList(),
        );
      }

      // 2. Save the complaint document to Firestore.
      // Field names below MUST match my_complaints_screen.dart exactly.
      final docRef = await FirebaseFirestore.instance.collection('complaints').add({
        'reporterUid': uid,
        'category': _selectedCategory,
        'priority': _selectedPriority,
        'status': 'pending', // every new complaint starts as pending
        'block': _selectedBlock,
        'floor': _selectedFloor,
        'room': _roomController.text.trim(),
        'description': _descriptionController.text.trim(),
        'photoUrls': photoUrls,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // 3. Show success + ticket ID, then close the form
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Complaint Submitted ✅'),
          content: Text(
            'Ticket ID: #${docRef.id.substring(0, 6).toUpperCase()}\n\n'
            'The maintenance team has been notified.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // close form, back to dashboard
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showSnack('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 1,
        foregroundColor: AppColors.onSurface,
        title: const Text('New Complaint', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Location Details ----
                  Text('Location Details',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedBlock,
                    decoration: _dropdownDecoration('Select Block'),
                    items: _blocks
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedBlock = val),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedFloor,
                          decoration: _dropdownDecoration('Select Floor'),
                          items: _floors
                              .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedFloor = val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _roomController,
                          decoration: _dropdownDecoration('e.g. Lab 102'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ---- Category ----
                  Text('Complaint Category',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.9,
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat['value'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat['value']),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.1)
                                : AppColors.surface,
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(cat['icon'], color: AppColors.primary, size: 22),
                              const SizedBox(height: 4),
                              Text(
                                cat['label'],
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // ---- Priority ----
                  Text('Priority Level',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  Row(
                    children: ['low', 'medium', 'high'].map((p) {
                      final isSelected = _selectedPriority == p;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPriority = p),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.1)
                                  : AppColors.surface,
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.outlineVariant,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              p[0].toUpperCase() + p.substring(1),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // ---- Description ----
                  Text('Issue Description',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: _dropdownDecoration(
                      'Describe the issue clearly so the maintenance team can resolve it quickly.',
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ---- Photo Upload ----
                  Text('Upload Images (Optional)',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._pickedImages.asMap().entries.map((entry) {
                        final index = entry.key;
                        final img = entry.value;
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                img.bytes,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      if (_pickedImages.length < _maxImages)
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.outlineVariant,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, color: AppColors.onSurfaceVariant),
                                const SizedBox(height: 4),
                                Text('Add Photo',
                                    style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ---- Submit ----
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitComplaint,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Submit Complaint',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.outlineVariant),
      ),
    );
  }
}

// Small helper class to keep an image's bytes + original filename together
// while it sits in the form, before it's uploaded.
class _PickedImage {
  final Uint8List bytes;
  final String fileName;
  _PickedImage({required this.bytes, required this.fileName});
}