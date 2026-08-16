// lib/screens/campus_map_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/campus_location_model.dart';

class CampusMapScreen extends StatefulWidget {
  const CampusMapScreen({super.key});

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  // Track which pin is currently selected so we know what to show
  // in the bottom detail card.
  CampusLocation? _selectedLocation;
  final TransformationController _zoomController = TransformationController();

  @override
  void initState() {
    super.initState();
    // Select the first building by default, like the mockup does.
    _selectedLocation = campusLocations.first;
  }

  void _zoomIn() {
    _zoomController.value = _zoomController.value.scaled(1.2);
  }

  void _zoomOut() {
    _zoomController.value = _zoomController.value.scaled(0.8);
  }

  void _resetZoom() {
    _zoomController.value = Matrix4.identity();
  }

  Future<void> _openDirections(CampusLocation location) async {
    final query = Uri.encodeComponent(location.address);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _shareLocation(CampusLocation location) {
    Share.share('${location.name} — ${location.address}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ---- Full-screen zoomable map image ----
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _zoomController,
              minScale: 1.0,
              maxScale: 4.0,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      Image.asset(
                        'assets/images/campus_map.png',
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        fit: BoxFit.cover,
                      ),
                      // ---- Pins, placed using fractional coordinates ----
                      ...campusLocations.map((location) {
                        final isSelected = _selectedLocation?.id == location.id;
                        return Positioned(
                          top: constraints.maxHeight * location.top,
                          left: constraints.maxWidth * location.left,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedLocation = location);
                            },
                            child: Icon(
                              Icons.location_on,
                              size: isSelected ? 40 : 32,
                              color: isSelected
                                  ? const Color(0xFF16767C)
                                  : Colors.redAccent,
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ),

          // ---- Floating search bar ----
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: const [
                  Icon(Icons.search, color: Colors.grey),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Search campus locations...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---- Zoom + locate controls ----
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height / 2 - 60,
            child: Column(
              children: [
                _mapControlButton(Icons.add, _zoomIn),
                const SizedBox(height: 8),
                _mapControlButton(Icons.remove, _zoomOut),
                const SizedBox(height: 16),
                _mapControlButton(
                  Icons.my_location,
                  _resetZoom,
                  iconColor: const Color(0xFF16767C),
                ),
              ],
            ),
          ),

          // ---- Bottom location detail card ----
          if (_selectedLocation != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildDetailCard(_selectedLocation!),
            ),

          // ---- Back button ----
          Positioned(
            top: 70,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapControlButton(IconData icon, VoidCallback onTap, {Color? iconColor}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: iconColor ?? Colors.black87),
        ),
      ),
    );
  }

  Widget _buildDetailCard(CampusLocation location) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            location.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF16767C),
            ),
          ),
          const SizedBox(height: 4),
          Text(location.address, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            location.distance,
            style: const TextStyle(
              color: Color(0xFF306C78),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openDirections(location),
                  icon: const Icon(Icons.directions),
                  label: const Text('Get Directions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16767C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareLocation(location),
                  icon: const Icon(Icons.share),
                  label: const Text('Share Location'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}