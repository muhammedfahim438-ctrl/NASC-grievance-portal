import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import 'admin_duplicate_screen.dart';
import 'admin_resolution_screen.dart';

class AdminTriageScreen extends StatefulWidget {
  final String complaintId;

  const AdminTriageScreen({super.key, required this.complaintId});

  @override
  State<AdminTriageScreen> createState() => _AdminTriageScreenState();
}

class _AdminTriageScreenState extends State<AdminTriageScreen> {
  String _selectedPriority = 'medium';
  String? _selectedTechnician;
  final _notesController = TextEditingController();
  bool _isSaving = false;
  bool _isUpdatingStatus = false;

  // BUG FIX: this used to be read+mutated directly inside build() every
  // time a new Firestore snapshot arrived (e.g. whenever you clicked
  // "Assign Ticket" or "Update Status" the stream would fire again and
  // silently overwrite _selectedPriority mid-build). That's fragile -
  // Flutter's framework never gets told the state changed.
  //
  // Instead, we only want to seed _selectedPriority from Firestore ONCE,
  // the first time the ticket's data arrives - after that, the admin's
  // own taps on the priority pills should be the only thing that changes
  // it. This flag makes sure the "seed from Firestore" logic only ever
  // runs a single time.
  bool _priorityInitialized = false;

  final List<String> _technicians = [
    'Ramesh - Electrician',
    'Suresh - Plumber',
    'Anil - General Maintenance',
    'Priya - IT Support',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _assignTicket() async {
    if (_selectedTechnician == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a technician.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('complaints').doc(widget.complaintId).update({
        'priority': _selectedPriority,
        'assignedTechnician': _selectedTechnician,
        'internalNotes': _notesController.text.trim(),
        'status': 'in_progress',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket assigned successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Failed to assign ticket.'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdatingStatus = true);
    try {
      await FirebaseFirestore.instance.collection('complaints').doc(widget.complaintId).update({
        'status': newStatus,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to ${_statusLabel(newStatus)}.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Failed to update status.'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'merged':
        return 'Merged';
      default:
        return 'Pending';
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
        title: const Text('Triage & Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Quick access to duplicate detection from anywhere in Triage
          IconButton(
            icon: const Icon(Icons.content_copy),
            tooltip: 'Check Duplicates',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminDuplicateScreen(complaintId: widget.complaintId)),
              );
            },
          ),
        ],
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
                final currentStatus = data['status'] ?? 'pending';
                final timestamp = data['createdAt'] as Timestamp?;
                final formattedDate = timestamp != null
                    ? DateFormat('MMM d, yyyy - hh:mm a').format(timestamp.toDate())
                    : 'Unknown date';

                // BUG FIX: seed the priority selector from Firestore exactly
                // once, the proper way. We schedule the setState() to run
                // right after this frame finishes (addPostFrameCallback)
                // instead of mutating _selectedPriority mid-build. The
                // _priorityInitialized flag guarantees this block only
                // does its job on the very first snapshot - after that,
                // only the admin tapping a priority pill can change it.
                if (!_priorityInitialized) {
                  _priorityInitialized = true;
                  final initialPriority = data['priority'];
                  if (initialPriority != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() => _selectedPriority = initialPriority);
                      }
                    });
                  }
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ticket info card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
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
                                Text('Ticket #${widget.complaintId.substring(0, 6).toUpperCase()}',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _statusLabel(currentStatus),
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                            Text(formattedDate, style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                            const SizedBox(height: 12),
                            _detailRow('Category', (data['category'] ?? '').toString().toUpperCase()),
                            const SizedBox(height: 8),
                            _detailRow('Location', '${data['block']} Block, ${data['floor']}, ${data['room']}'),
                            const SizedBox(height: 12),
                            Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                            const SizedBox(height: 6),
                            Text(data['description'] ?? '', style: TextStyle(fontSize: 14, color: AppColors.onSurface, height: 1.4)),
                            if (photoUrls.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 100,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: photoUrls.length,
                                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                                  itemBuilder: (context, index) => ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(photoUrls[index], width: 130, height: 100, fit: BoxFit.cover),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Status Management card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status Management', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                            const SizedBox(height: 4),
                            Text('Current status: ${_statusLabel(currentStatus)}', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (currentStatus != 'in_progress' && currentStatus != 'resolved')
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _isUpdatingStatus ? null : () => _updateStatus('in_progress'),
                                      icon: const Icon(Icons.sync, size: 18),
                                      label: const Text('In Progress'),
                                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: BorderSide(color: AppColors.primary)),
                                    ),
                                  ),
                                if (currentStatus != 'in_progress' && currentStatus != 'resolved') const SizedBox(width: 8),

                                // Once In Progress, this button now opens the full Resolution & Closure screen
                                // instead of just flipping the status directly
                                if (currentStatus == 'in_progress')
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => AdminResolutionScreen(complaintId: widget.complaintId)),
                                        );
                                      },
                                      icon: const Icon(Icons.task_alt, size: 18),
                                      label: const Text('Resolve Ticket'),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
                                    ),
                                  ),
                                if (currentStatus == 'resolved')
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _isUpdatingStatus ? null : () => _updateStatus('pending'),
                                      icon: const Icon(Icons.replay, size: 18),
                                      label: const Text('Reopen Ticket'),
                                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: BorderSide(color: AppColors.error)),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Assignment card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Action & Assignment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                            const SizedBox(height: 16),
                            Text('Priority Level', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _priorityPill('low', 'Low'),
                                const SizedBox(width: 8),
                                _priorityPill('medium', 'Medium'),
                                const SizedBox(width: 8),
                                _priorityPill('high', 'High'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text('Assign Technician', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedTechnician,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.background,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.outlineVariant)),
                              ),
                              hint: const Text('Select available staff...'),
                              items: _technicians.map((tech) => DropdownMenuItem(value: tech, child: Text(tech))).toList(),
                              onChanged: (value) => setState(() => _selectedTechnician = value),
                            ),
                            const SizedBox(height: 16),
                            Text('Internal Notes (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _notesController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Add instructions for technician...',
                                filled: true,
                                fillColor: AppColors.background,
                                contentPadding: const EdgeInsets.all(12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.outlineVariant)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _assignTicket,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isSaving
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                    : const Text('Assign Ticket', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
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

  Widget _priorityPill(String value, String label) {
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
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600))),
        Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: AppColors.onSurface))),
      ],
    );
  }
}