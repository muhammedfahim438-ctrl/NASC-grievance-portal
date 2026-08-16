// lib/screens/booking_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'new_booking_screen.dart';
import 'booking_ticket_screen.dart';
import 'campus_map_screen.dart';

class BookingDashboardScreen extends StatefulWidget {
  const BookingDashboardScreen({super.key});

  @override
  State<BookingDashboardScreen> createState() => _BookingDashboardScreenState();
}

class _BookingDashboardScreenState extends State<BookingDashboardScreen> {
  // Replace these with real values from your logged-in user/profile
  // once this screen is wired up (same pattern as teacher_home_screen.dart).
  final String _userInitial = 'H';
  final String _userName = 'Welcome, HAI';
  final String _userDepartment = 'cs_ds';

  void _onNavTap(int index) {
    if (index == 0) {
      // Report tab - the real Report screen (TeacherHomeScreen) is
      // already open underneath this one, so just go back to it.
      Navigator.pop(context);
    }
    // index == 1 (Booking) - we're already here, nothing to do.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
        centerTitle: false,
        // Hamburger/drawer trigger removed from the top bar as requested.
        automaticallyImplyLeading: false,
        title: const Text(
          'Booking Dashboard',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F766E),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFE2E8F0),
              child: const Text(
                'img',
                style: TextStyle(fontSize: 10, color: Color(0xFF475569)),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBookingTab(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ---------------- BOOKING TAB ----------------

  Widget _buildBookingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeRow(),
          const SizedBox(height: 20),
          _buildStatusCard(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildBookingCard(
                  icon: Icons.event_note,
                  label: 'Booking',
                  isPrimary: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NewBookingScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBookingCard(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Booking Ticket',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BookingTicketScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBookingCard(
            icon: Icons.map_outlined,
            label: 'Campus Map',
            fullWidth: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CampusMapScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Booking Summary',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),
          _buildBookingSummary(),
        ],
      ),
    );
  }

  Widget _buildWelcomeRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFE2E8F0),
              child: Text(
                _userInitial,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  _userDepartment,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Icon(Icons.notifications_outlined, size: 18, color: Color(0xFF0F766E)),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today's Booking Status",
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              SizedBox(height: 4),
              Text(
                'No Active Bookings',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF006B5F),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F5F1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(Icons.check_circle, color: Color(0xFF006B5F)),
          ),
        ],
      ),
    );
  }

  // ---------------- BOOKING SUMMARY (4 live stat boxes) ----------------

  Widget _buildBookingSummary() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('reporterUid', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        int total = 0;
        int pending = 0;
        int approved = 0;
        int completed = 0;

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          total = docs.length;
          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status'] ?? '').toString().toLowerCase();
            if (status == 'pending') {
              pending++;
            } else if (status == 'approved') {
              approved++;
            } else if (status == 'completed') {
              completed++;
            }
          }
        }

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _summaryBox(
              label: 'Total Bookings',
              value: total,
              color: const Color(0xFF0F766E),
            ),
            _summaryBox(
              label: 'Pending',
              value: pending,
              color: const Color(0xFFD97706),
            ),
            _summaryBox(
              label: 'Approved',
              value: approved,
              color: const Color(0xFF14B8A6),
            ),
            _summaryBox(
              label: 'Completed',
              value: completed,
              color: const Color(0xFF1E293B),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryBox({required String label, required int value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool fullWidth = false,
  }) {
    return Material(
      color: isPrimary ? const Color(0xFF0F766E) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 130,
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPrimary ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isPrimary ? Colors.white : const Color(0xFF0F766E),
                  size: 20,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- BOTTOM NAV (Report / Booking only) ----------------

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(index: 0, icon: Icons.bar_chart, label: 'Report'),
            _navItem(index: 1, icon: Icons.confirmation_number_outlined, label: 'Booking'),
          ],
        ),
      ),
    );
  }

  Widget _navItem({required int index, required IconData icon, required String label}) {
    final isActive = index == 1; // Booking is the only tab this screen shows
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _onNavTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE6F5F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: isActive ? const Color(0xFF0F766E) : const Color(0xFF64748B)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? const Color(0xFF0F766E) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}