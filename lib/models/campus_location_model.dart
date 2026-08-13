// lib/models/campus_location_model.dart

class CampusLocation {
  final String id;
  final String name;
  final String address;
  final String distance; // e.g. "450m away • 6 min walk"
  final double top;      // 0.0 = top of image, 1.0 = bottom
  final double left;     // 0.0 = left of image, 1.0 = right

  CampusLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    required this.top,
    required this.left,
  });
}

// Hardcoded list for now — you can move this to Firestore later
// if you want admins to add/edit buildings without a code change.
final List<CampusLocation> campusLocations = [
  CampusLocation(
    id: 'arts_a',
    name: 'Arts Block A',
    address: 'Nehru Group of Institutions, Main Campus Road',
    distance: '450m away • 6 min walk',
    top: 0.25,
    left: 0.30,
  ),
  CampusLocation(
    id: 'science_block',
    name: 'Science Block',
    address: 'Nehru Group of Institutions, East Wing',
    distance: '300m away • 4 min walk',
    top: 0.45,
    left: 0.60,
  ),
  CampusLocation(
    id: 'library',
    name: 'Central Library',
    address: 'Nehru Group of Institutions, North Wing',
    distance: '600m away • 8 min walk',
    top: 0.65,
    left: 0.40,
  ),
  CampusLocation(
    id: 'admin_block',
    name: 'Admin Block',
    address: 'Nehru Group of Institutions, Main Entrance',
    distance: '150m away • 2 min walk',
    top: 0.15,
    left: 0.55,
  ),
];