import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/cloudinary_service.dart';

class NewComplaintScreen extends StatefulWidget {
  const NewComplaintScreen({super.key});

  @override
  State<NewComplaintScreen> createState() => _NewComplaintScreenState();
}

class _NewComplaintScreenState extends State<NewComplaintScreen> {
  // Location fields
  String? _selectedBlock;
  String? _selectedFloor;
  final _roomController = TextEditingController();

  // Category selection - matches NASC5's 8 category icons
  String? _selectedCategory;
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

  // Priority selection
  String _selectedPriority = 'medium'; // matches the design's default

  final _descriptionController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final List<Uint8List> _selectedImages = []; // holds the actual photo data in memory

  bool _isLoading = false;

  @override
  void dispose() {
    _roomController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Opens the device's photo gallery and lets the user pick one image.
  // imageQuality: 70 compresses it automatically (70% quality - a good
  // balance between file size and looking sharp).
  Future<void> _pickImage() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can add up to 5 photos.')),
      );
      return;
    }
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1200,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImages.add(bytes);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitComplaint() async {
    // Validate required fields before doing any network work
    if (_selectedBlock == null) {
      _showError('Please select a block.');
      return;
    }
    if (_selectedFloor == null) {
      _showError('Please select a floor.');
      return;
    }
    if (_roomController.text.trim().isEmpty) {
      _showError('Please enter a room or facility.');
      return;
    }
    if (_selectedCategory == null) {
      _showError('Please select a complaint category.');
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showError('Please describe the issue.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Step A: upload any selected photos to Cloudinary first
      List<String> photoUrls = [];
      if (_selectedImages.isNotEmpty) {
        photoUrls = await _cloudinaryService.uploadImages(_selectedImages);
      }

      // Step B: write the complaint document into Firestore
      final currentUser = FirebaseAuth.instance.currentUser!;
      final docRef = await FirebaseFirestore.instance.collection('complaints').add({
        'reporterUid': currentUser.uid,
        'block': _selectedBlock,
        'floor': _selectedFloor,
        'room': _roomController.text.trim(),
        'category': _selectedCategory,
        'priority': _selectedPriority,
        'description': _descriptionController.text.trim(),
        'photoUrls': photoUrls,
        'status': 'pending', // every new complaint starts as pending
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Step C: show success and go back to the dashboard
      _showSuccessDialog(docRef.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showError('Something went wrong. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showSuccessDialog(String ticketId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.check_circle, color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Complaint Submitted Successfully', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Ticket ID: #${ticketId.substring(0, 6).toUpperCase()}', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context); // closes the dialog
                Navigator.pop(context); // goes back to the dashboard
              },
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 1,
        foregroundColor: AppColors.onSurface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Complaint', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
            Text('Report a campus maintenance issue', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
          ],
        ),
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
                  // Location Details card
                  _sectionCard(
                    title: 'Location Details',
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedBlock,
                          decoration: _inputDecoration('Select a block...'),
                          items: const [
                            DropdownMenuItem(value: 'A', child: Text('A Block')),
                            DropdownMenuItem(value: 'B', child: Text('B Block')),
                            DropdownMenuItem(value: 'C', child: Text('C Block')),
                            DropdownMenuItem(value: 'D', child: Text('D Block')),
                          ],
                          onChanged: (value) => setState(() => _selectedBlock = value),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedFloor,
                                decoration: _inputDecoration('Floor'),
                                items: const [
                                  DropdownMenuItem(value: 'Ground', child: Text('Ground Floor')),
                                  DropdownMenuItem(value: '1st', child: Text('First Floor')),
                                  DropdownMenuItem(value: '2nd', child: Text('Second Floor')),
                                  DropdownMenuItem(value: '3rd', child: Text('Third Floor')),
                                ],
                                onChanged: (value) => setState(() => _selectedFloor = value),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _roomController,
                                decoration: _inputDecoration('e.g. Lab 102'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category grid
                  Text('Complaint Category', style: _labelStyle()),
                  const SizedBox(height: 8),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.9,
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat['value'];
                      return InkWell(
                        onTap: () => setState(() => _selectedCategory = cat['value']),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withOpacity(0.08) : AppColors.surface,
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.outlineVariant,
                              width: isSelected ? 1.5 : 1,
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
                                style: const TextStyle(fontSize: 9),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Priority selector
                  _sectionCard(
                    title: 'Priority Level',
                    child: Row(
                      children: [
                        _priorityOption('low', 'Low'),
                        const SizedBox(width: 8),
                        _priorityOption('medium', 'Medium'),
                        const SizedBox(width: 8),
                        _priorityOption('high', 'High'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text('Issue Description', style: _labelStyle()),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: _inputDecoration(
                      'Describe the issue clearly so the maintenance team can resolve it quickly.',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Upload Images section
                  Text('Upload Images (Optional)', style: _labelStyle()),
                  const SizedBox(height: 8),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      // One thumbnail per already-picked photo
                      for (int i = 0; i < _selectedImages.length; i++)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _selectedImages[i],
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(i),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      // The "Add Photo" tile, always shown last
                      InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.outlineVariant, width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, color: AppColors.outlineVariant),
                              const SizedBox(height: 4),
                              Text('Add Photo', style: TextStyle(fontSize: 10, color: AppColors.outlineVariant)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitComplaint,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text('Submit Complaint', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper: wraps a titled section in a white card, matching your design's cards
  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  // Helper: one of the 3 priority pill buttons (Low/Medium/High)
  Widget _priorityOption(String value, String label) {
    final isSelected = _selectedPriority == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedPriority = value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.outlineVariant),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _labelStyle() => TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface);

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.outlineVariant)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.outlineVariant)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.primary, width: 2)),
    );
  }
}