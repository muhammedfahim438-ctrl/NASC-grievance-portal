import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../utils/app_colors.dart';
import '../services/cloudinary_service.dart';

class AdminResolutionScreen extends StatefulWidget {
  final String complaintId;

  const AdminResolutionScreen({super.key, required this.complaintId});

  @override
  State<AdminResolutionScreen> createState() => _AdminResolutionScreenState();
}

class _AdminResolutionScreenState extends State<AdminResolutionScreen> {
  final _closureNotesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  Uint8List? _proofImage;
  bool _isProcessing = false;

  @override
  void dispose() {
    _closureNotesController.dispose();
    super.dispose();
  }

  Future<void> _pickProofPhoto() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1200,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _proofImage = bytes);
    }
  }

  Future<void> _confirmAndClose() async {
    setState(() => _isProcessing = true);

    try {
      String? proofPhotoUrl;
      if (_proofImage != null) {
        proofPhotoUrl = await _cloudinaryService.uploadImage(
          _proofImage!,
          'proof_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      await FirebaseFirestore.instance.collection('complaints').doc(widget.complaintId).update({
        'status': 'resolved',
        'closureNotes': _closureNotesController.text.trim(),
        if (proofPhotoUrl != null) 'proofPhotoUrl': proofPhotoUrl,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket closed successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Failed to close ticket.'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _requestRework() async {
    setState(() => _isProcessing = true);
    try {
      await FirebaseFirestore.instance.collection('complaints').doc(widget.complaintId).update({
        'status': 'in_progress',
        'closureNotes': _closureNotesController.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rework requested. Ticket sent back to In Progress.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Failed to update ticket.'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
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
        title: const Text('Resolution & Closure', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('complaints').doc(widget.complaintId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.data!.exists) {
                  return Center(child: Text('This complaint no longer exists.', style: TextStyle(color: AppColors.onSurfaceVariant)));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final photoUrls = List<String>.from(data['photoUrls'] ?? []);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ticket #${widget.complaintId.substring(0, 6).toUpperCase()}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                      const SizedBox(height: 4),
                      Text((data['category'] ?? '').toString().toUpperCase(), style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),

                      // Before/After comparison
                      Text('Grievance Verification', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Original issue photo
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Original Issue', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                                const SizedBox(height: 6),
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: photoUrls.isNotEmpty
                                        ? Image.network(photoUrls.first, fit: BoxFit.cover)
                                        : Container(
                                            color: AppColors.surface,
                                            child: Icon(Icons.image_not_supported_outlined, color: AppColors.outlineVariant),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Technician proof photo (uploaded here)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Technician Proof', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                                const SizedBox(height: 6),
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: InkWell(
                                    onTap: _pickProofPhoto,
                                    borderRadius: BorderRadius.circular(12),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: _proofImage != null
                                          ? Image.memory(_proofImage!, fit: BoxFit.cover)
                                          : Container(
                                              decoration: BoxDecoration(border: Border.all(color: AppColors.outlineVariant, width: 1.5)),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.add_a_photo_outlined, color: AppColors.outlineVariant),
                                                  const SizedBox(height: 4),
                                                  Text('Add Proof', style: TextStyle(fontSize: 10, color: AppColors.outlineVariant)),
                                                ],
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Closure notes
                      Text('Closure Notes (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _closureNotesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Add any final remarks before closing this ticket...',
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.outlineVariant)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isProcessing ? null : _requestRework,
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                              child: const Text('Request Rework'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isProcessing ? null : _confirmAndClose,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              icon: _isProcessing
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.check_circle, size: 18),
                              label: const Text('Confirm & Close'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}