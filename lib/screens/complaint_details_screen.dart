import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';

class ComplaintDetailsScreen extends StatelessWidget {
  final String complaintId;

  const ComplaintDetailsScreen({super.key, required this.complaintId});

  Map<String, dynamic> _statusInfo(String status) {
    switch (status) {
      case 'in_progress':
        return {'label': 'In Progress', 'color': AppColors.primary};
      case 'resolved':
        return {'label': 'Resolved', 'color': AppColors.secondary};
      default:
        return {'label': 'Pending', 'color': Colors.orange};
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
        title: const Text('Complaint Details', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: StreamBuilder<DocumentSnapshot>(
              // StreamBuilder (not just a one-time fetch) means if an admin
              // updates this complaint's status while the teacher has this
              // screen open, it updates live - no refresh needed.
              stream: FirebaseFirestore.instance.collection('complaints').doc(complaintId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.data!.exists) {
                  return Center(
                    child: Text('This complaint no longer exists.', style: TextStyle(color: AppColors.onSurfaceVariant)),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final status = data['status'] ?? 'pending';
                final statusInfo = _statusInfo(status);
                final photoUrls = List<String>.from(data['photoUrls'] ?? []);
                final timestamp = data['createdAt'] as Timestamp?;
                final formattedDate = timestamp != null
                    ? DateFormat('MMM d, yyyy - hh:mm a').format(timestamp.toDate())
                    : 'Unknown date';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header card: ticket ID + status
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Ticket #${complaintId.substring(0, 6).toUpperCase()}',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusInfo['color'],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    statusInfo['label'],
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(formattedDate, style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Details card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _detailRow('Category', (data['category'] ?? '').toString().toUpperCase()),
                            const SizedBox(height: 10),
                            _detailRow('Priority', (data['priority'] ?? '').toString().toUpperCase()),
                            const SizedBox(height: 10),
                            _detailRow('Location', '${data['block']} Block, ${data['floor']}, ${data['room']}'),
                            const SizedBox(height: 14),
                            Text('Issue Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                data['description'] ?? '',
                                style: TextStyle(fontSize: 14, color: AppColors.onSurface, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Photos section - only shown if photos exist
                      if (photoUrls.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Uploaded Photos (${photoUrls.length})', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 120,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: photoUrls.length,
                                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                                  itemBuilder: (context, index) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        photoUrls[index],
                                        width: 160,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        // Shows a spinner while the image loads from the internet
                                        loadingBuilder: (context, child, progress) {
                                          if (progress == null) return child;
                                          return Container(
                                            width: 160,
                                            height: 120,
                                            color: AppColors.background,
                                            child: const Center(child: CircularProgressIndicator()),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Text(value, style: TextStyle(fontSize: 13, color: AppColors.onSurface)),
        ),
      ],
    );
  }
}