// lib/screens/teacher_home_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'new_complaint_screen.dart';
import 'my_complaints_screen.dart';
import 'campus_map_screen.dart';
import 'login_screen.dart';
import 'booking_dashboard_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  // BUG FIX / CHANGE: this used to track 4 tabs (Home, Report, My Tickets,
  // Profile) driving a stock BottomNavigationBar. That's been replaced with
  // just 2 tabs - Report and Booking - styled like booking_dashboard_screen's
  // pill nav. Index 0 = Report (this screen, unchanged), index 1 = Booking
  // (pushes BookingDashboardScreen).
  int _currentTabIndex = 0;

  // We'll cache the logged-in user's name/department here after
  // we fetch it once from Firestore, so we don't re-fetch every rebuild.
  String _userName = 'Loading...';
  String _userDepartment = '';
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Pulls the current user's name + department from the "users" collection.
  // Why a separate fetch instead of StreamBuilder? Profile info rarely
  // changes mid-session, so one read is enough — no need to keep listening.
  Future<void> _loadUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _userName = doc.data()?['fullName'] ?? 'Teacher';
          _userDepartment = doc.data()?['department'] ?? '';
          _loadingProfile = false;
        });
      } else {
        setState(() {
          _userName = 'Teacher';
          _loadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = 'Teacher';
          _loadingProfile = false;
        });
      }
    }
  }

  // A live stream of THIS teacher's own complaints, used to power
  // the 4 stat cards (Active / Resolved / High Priority / Total).
  Stream<QuerySnapshot> _myComplaintsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('complaints')
        .where('reporterUid', isEqualTo: uid)
        .snapshots();
  }

  Future<void> _callNumber(String phoneNumber) async {
    final url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  // Handles taps on the new 2-tab bottom nav.
  void _onNavTap(int index) {
    if (index == 0) {
      // Report tab - this IS the current screen, so just make sure it's
      // shown as active. Nothing to navigate to.
      setState(() => _currentTabIndex = 0);
    } else if (index == 1) {
      // Booking tab - open the Booking Dashboard, then reset back to
      // the Report tab once they return here.
      setState(() => _currentTabIndex = 1);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BookingDashboardScreen()),
      ).then((_) {
        if (mounted) setState(() => _currentTabIndex = 0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildCampusStatusCard(),
              const SizedBox(height: 24),
              _buildQuickActionsGrid(),
              const SizedBox(height: 24),
              _buildComplaintSummary(),
              const SizedBox(height: 80), // leaves room above bottom nav
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ---------------- HEADER ----------------

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFE2E8F0),
              child: _loadingProfile
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'T',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $_userName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  _userDepartment.isNotEmpty
                      ? _userDepartment
                      : 'Faculty Member',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        Stack(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_outlined),
              color: const Color(0xFF64748B),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF0F766E),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------- CAMPUS STATUS CARD ----------------

  Widget _buildCampusStatusCard() {
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
                "Today's Campus Status",
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              SizedBox(height: 4),
              Text(
                'No Critical Issues',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF006B5F),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEAEDFF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF006B5F),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- QUICK ACTIONS (2x2 BENTO GRID) ----------------

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: [
        _buildActionCard(
          icon: Icons.report_problem_outlined,
          label: 'Report Complaint',
          isPrimary: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NewComplaintScreen()),
            );
          },
        ),
        _buildActionCard(
          icon: Icons.assignment_outlined,
          label: 'My Complaints',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyComplaintsScreen()),
            );
          },
        ),
        _buildContactMaintenanceCard(),
        _buildActionCard(
          icon: Icons.map_outlined,
          label: 'Campus Map',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CampusMapScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Material(
      color: isPrimary ? const Color(0xFF0F766E) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : const Color(0xFF0F766E),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
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

  // Contact Maintenance card — expandable list with tap-to-call rows,
  // matching the NASC3 mockup's dropdown-style quick action.
  Widget _buildContactMaintenanceCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Icon(Icons.support_agent_outlined, color: Color(0xFF735B19), size: 20),
              Icon(Icons.arrow_drop_down, color: Colors.grey, size: 18),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Contact Maintenance',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const Divider(height: 10),
          _contactRow('Main Desk', '+911234567890'),
          _contactRow('Electrical Shop', '+911234567891'),
          _contactRow('Plumbing Unit', '+911234567892'),
        ],
      ),
    );
  }

  Widget _contactRow(String label, String number) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: () => _callNumber(number),
            child: const Icon(Icons.call, size: 12, color: Color(0xFF0F766E)),
          ),
        ],
      ),
    );
  }

  // ---------------- COMPLAINT SUMMARY (LIVE STATS) ----------------

  Widget _buildComplaintSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Complaint Summary',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: _myComplaintsStream(),
          builder: (context, snapshot) {
            int active = 0, resolved = 0, highPriority = 0, total = 0;

            if (snapshot.hasData) {
              final docs = snapshot.data!.docs;
              total = docs.length;
              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                final status = (data['status'] ?? '').toString().toLowerCase();
                final priority = (data['priority'] ?? '').toString().toLowerCase();

                if (status == 'resolved') {
                  resolved++;
                } else {
                  active++;
                }
                if (priority == 'high' || priority == 'emergency') {
                  highPriority++;
                }
              }
            }

            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: [
                _statCard('$active', 'Active Reports', const Color(0xFF0F766E)),
                _statCard('$resolved', 'Resolved', const Color(0xFF14B8A6)),
                _statCard('$highPriority', 'High Priority', const Color(0xFFBA1A1A)),
                _statCard('$total', 'Total Submitted', const Color(0xFF0F172A)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  // ---------------- BOTTOM NAV (Report / Booking only) ----------------
  // Replaces the old 4-item BottomNavigationBar with a custom 2-tab pill
  // nav matching booking_dashboard_screen.dart's style exactly.

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
    final isActive = _currentTabIndex == index;
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