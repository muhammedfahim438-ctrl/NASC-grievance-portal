import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';

class AdminDuplicateScreen extends StatefulWidget {
  final String complaintId;

  const AdminDuplicateScreen({super.key, required this.complaintId});

  @override
  State<AdminDuplicateScreen> createState() => _AdminDuplicateScreenState();
}

class _AdminDuplicateScreenState extends State<AdminDuplicateScreen> {
  final Set<String> _selectedDuplicateIds = {};
  bool _isMerging = false;

  Future<void> _mergeSelected(String masterId) async {
    if (_selectedDuplicateIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one duplicate to merge.')),
      );
      return;
    }

    setState(() => _isMerging = true);

    try {
      // Update each selected duplicate: mark it as merged and link it to the master ticket
      for (final duplicateId in _selectedDuplicateIds) {
        await FirebaseFirestore.instance.collection('complaints').doc(duplicateId).update({
          'status': 'merged',
          'mergedInto': masterId,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_selectedDuplicateIds.length} ticket(s) merged successfully.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Failed to merge tickets.'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isMerging = false);
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
        title: const Text('Duplicate Detection', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: StreamBuilder<DocumentSnapshot>(
              // First, load the "master" ticket - the one we're checking for duplicates of
              stream: FirebaseFirestore.instance.collection('complaints').doc(widget.complaintId).snapshots(),
              builder: (context, masterSnapshot) {
                if (!masterSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!masterSnapshot.data!.exists) {
                  return Center(child: Text('This complaint no longer exists.', style: TextStyle(color: AppColors.onSurfaceVariant)));
                }

                final masterData = masterSnapshot.data!.data() as Map<String, dynamic>;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Master ticket card
                      Text('Master Ticket', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('#${widget.complaintId.substring(0, 6).toUpperCase()}', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                            const SizedBox(height: 4),
                            Text((masterData['category'] ?? '').toString().toUpperCase(), style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('${masterData['block']} Block, ${masterData['floor']}, ${masterData['room']}', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                            const SizedBox(height: 6),
                            Text(masterData['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text('Similar Reports', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                      const SizedBox(height: 4),
                      Text(
                        'Other active tickets in the same block, floor, and category',
                        style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),

                      // Now search for potential duplicates: same block, floor, category, not resolved, not this ticket
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('complaints')
                            .where('block', isEqualTo: masterData['block'])
                            .where('category', isEqualTo: masterData['category'])
                            .snapshots(),
                        builder: (context, dupSnapshot) {
                          if (!dupSnapshot.hasData) {
                            return const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          // Filter out: this ticket itself, already-resolved tickets, and already-merged tickets
                          final candidates = dupSnapshot.data!.docs.where((doc) {
                            if (doc.id == widget.complaintId) return false;
                            final data = doc.data() as Map<String, dynamic>;
                            final status = data['status'] ?? 'pending';
                            final sameFloor = data['floor'] == masterData['floor'];
                            return sameFloor && status != 'resolved' && status != 'merged';
                          }).toList();

                          if (candidates.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text('No potential duplicates found.', style: TextStyle(color: AppColors.onSurfaceVariant)),
                              ),
                            );
                          }

                          return Column(
                            children: candidates.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final isSelected = _selectedDuplicateIds.contains(doc.id);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.outlineVariant, width: isSelected ? 1.5 : 1),
                                ),
                                child: CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (checked) {
                                    setState(() {
                                      if (checked == true) {
                                        _selectedDuplicateIds.add(doc.id);
                                      } else {
                                        _selectedDuplicateIds.remove(doc.id);
                                      }
                                    });
                                  },
                                  activeColor: AppColors.primary,
                                  title: Text('#${doc.id.substring(0, 6).toUpperCase()}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.onSurface)),
                                  subtitle: Text(
                                    data['description'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                              child: const Text('Discard as Non-Duplicate'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isMerging ? null : () => _mergeSelected(widget.complaintId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: _isMerging
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Merge Selected'),
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