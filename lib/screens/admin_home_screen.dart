import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'admin_triage_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700), // a bit wider than teacher screens - admin needs more room
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary,
                        child: const Icon(Icons.admin_panel_settings, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin Dashboard',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                            ),
                            Text(
                              'Monitor and manage campus complaints',
                              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        color: AppColors.onSurfaceVariant,
                        onPressed: () async {
                          await AuthService().signOut();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Live metrics - watching ALL complaints, not filtered to one user
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('complaints').snapshots(),
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? [];

                      final total = docs.length;
                      final pending = docs.where((d) => (d.data() as Map)['status'] == 'pending').length;
                      final inProgress = docs.where((d) => (d.data() as Map)['status'] == 'in_progress').length;
                      final resolved = docs.where((d) => (d.data() as Map)['status'] == 'resolved').length;
                      final highPriority = docs.where((d) {
                        final data = d.data() as Map;
                        return data['priority'] == 'high' && data['status'] != 'resolved';
                      }).length;

                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 5 : 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        // Lowered from 1.3 -> 0.85 so each card has enough
                        // vertical room for the icon + number + two-line label.
                        // (1.3 made cards too short, which caused the overflow.)
                        childAspectRatio: 0.85,
                        children: [
                          _MetricCard(count: total, label: 'Total Complaints', icon: Icons.assignment, color: AppColors.onSurface),
                          _MetricCard(count: pending, label: 'Pending Review', icon: Icons.hourglass_empty, color: Colors.orange),
                          _MetricCard(count: inProgress, label: 'In Progress', icon: Icons.engineering, color: AppColors.primary),
                          _MetricCard(count: resolved, label: 'Resolved', icon: Icons.check_circle, color: AppColors.secondary),
                          _MetricCard(count: highPriority, label: 'High Priority', icon: Icons.warning, color: AppColors.error),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Recent Tickets',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 10),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('complaints')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text('No complaints submitted yet.', style: TextStyle(color: AppColors.onSurfaceVariant)),
                          ),
                        );
                      }

                      final docs = snapshot.data!.docs;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return _AdminTicketCard(
                            ticketId: doc.id,
                            reporterUid: data['reporterUid'] ?? '',
                            category: data['category'] ?? 'other',
                            priority: data['priority'] ?? 'medium',
                            status: data['status'] ?? 'pending',
                            block: data['block'] ?? '',
                            floor: data['floor'] ?? '',
                            room: data['room'] ?? '',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AdminTriageScreen(complaintId: doc.id),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// A single metric card for the admin dashboard
class _MetricCard extends StatelessWidget {
  final int count;
  final String label;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.count,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Slightly smaller padding gives a bit more breathing room inside the card
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        // Tells the Column to only take as much vertical space as its
        // children actually need, instead of trying to expand and overflow.
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// One row/card in the admin's ticket list.
// Looks up the reporter's name from Firestore using their uid.
class _AdminTicketCard extends StatelessWidget {
  final String ticketId;
  final String reporterUid;
  final String category;
  final String priority;
  final String status;
  final String block;
  final String floor;
  final String room;
  final VoidCallback onTap;

  const _AdminTicketCard({
    required this.ticketId,
    required this.reporterUid,
    required this.category,
    required this.priority,
    required this.status,
    required this.block,
    required this.floor,
    required this.room,
    required this.onTap,
  });

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

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return AppColors.error;
      case 'low':
        return AppColors.onSurfaceVariant;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusInfo = _statusInfo(status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${ticketId.substring(0, 6).toUpperCase()}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.onSurface),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusInfo['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusInfo['label'],
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusInfo['color']),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Reporter name - looked up live from the users collection
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(reporterUid).get(),
              builder: (context, snapshot) {
                String reporterName = 'Loading...';
                if (snapshot.hasData && snapshot.data!.exists) {
                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                  reporterName = userData['fullName'] ?? 'Unknown';
                } else if (snapshot.connectionState == ConnectionState.done) {
                  reporterName = 'Unknown';
                }
                return Row(
                  children: [
                    Icon(Icons.person_outline, size: 14, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(reporterName, style: TextStyle(fontSize: 12, color: AppColors.onSurface, fontWeight: FontWeight.w500)),
                  ],
                );
              },
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: AppColors.secondary),
                const SizedBox(width: 4),
                Text('$block Block, $floor, $room', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    category.isNotEmpty ? category[0].toUpperCase() + category.substring(1) : '',
                    style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _priorityColor(priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _priorityColor(priority)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}