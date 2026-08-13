import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_colors.dart';
import 'complaint_details_screen.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  String _selectedFilter = 'All'; // All, Pending, In Progress, Resolved
  String _searchQuery = '';

  final List<String> _filters = ['All', 'Pending', 'In Progress', 'Resolved'];

  // Maps our internal status values to what the filter chips say
  bool _matchesFilter(String status) {
    if (_selectedFilter == 'All') return true;
    if (_selectedFilter == 'Pending') return status == 'pending';
    if (_selectedFilter == 'In Progress') return status == 'in_progress';
    if (_selectedFilter == 'Resolved') return status == 'resolved';
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 1,
        foregroundColor: AppColors.onSurface,
        title: const Text('My Tickets', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search by category or room...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: AppColors.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: AppColors.outlineVariant),
                      ),
                    ),
                  ),
                ),

                // Filter chips row
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedFilter = filter),
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          backgroundColor: AppColors.surface,
                          side: BorderSide(color: isSelected ? AppColors.primary : AppColors.outlineVariant),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // The complaint list - live from Firestore
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('complaints')
                        .where('reporterUid', isEqualTo: uid)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            'No complaints submitted yet.',
                            style: TextStyle(color: AppColors.onSurfaceVariant),
                          ),
                        );
                      }

                      // Apply filter + search on top of the live data
                      final filteredDocs = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final status = data['status'] ?? 'pending';
                        final category = (data['category'] ?? '').toString().toLowerCase();
                        final room = (data['room'] ?? '').toString().toLowerCase();

                        final matchesFilter = _matchesFilter(status);
                        final matchesSearch = _searchQuery.isEmpty ||
                            category.contains(_searchQuery) ||
                            room.contains(_searchQuery);

                        return matchesFilter && matchesSearch;
                      }).toList();

                      if (filteredDocs.isEmpty) {
                        return Center(
                          child: Text(
                            'No matching complaints.',
                            style: TextStyle(color: AppColors.onSurfaceVariant),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return _ComplaintCard(
                            ticketId: doc.id,
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
                                  builder: (context) => ComplaintDetailsScreen(complaintId: doc.id),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// A single complaint card in the list
class _ComplaintCard extends StatelessWidget {
  final String ticketId;
  final String category;
  final String priority;
  final String status;
  final String block;
  final String floor;
  final String room;
  final VoidCallback onTap;

  const _ComplaintCard({
    required this.ticketId,
    required this.category,
    required this.priority,
    required this.status,
    required this.block,
    required this.floor,
    required this.room,
    required this.onTap,
  });

  // Turns 'in_progress' into a friendly label + color
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

  Map<String, dynamic> _priorityInfo(String priority) {
    switch (priority) {
      case 'high':
        return {'label': 'High Priority', 'color': AppColors.error};
      case 'low':
        return {'label': 'Low', 'color': AppColors.onSurfaceVariant};
      default:
        return {'label': 'Medium', 'color': Colors.orange};
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusInfo = _statusInfo(status);
    final priorityInfo = _priorityInfo(priority);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '#${ticketId.substring(0, 6).toUpperCase()}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.onSurface),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityInfo['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        priorityInfo['label'],
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: priorityInfo['color']),
                      ),
                    ),
                  ],
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
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: AppColors.secondary),
                const SizedBox(width: 4),
                Text(
                  '$block Block, $floor, $room',
                  style: TextStyle(fontSize: 13, color: AppColors.onSurface, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.category_outlined, size: 16, color: AppColors.secondary),
                const SizedBox(width: 4),
                Text(
                  category.isNotEmpty ? category[0].toUpperCase() + category.substring(1) : '',
                  style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}