// Defines the "shape" of a Complaint - every field a complaint document has.
// We'll use this later when reading/writing complaints from Firestore,
// but defining it now helps us think clearly about what our form needs to collect.
class Complaint {
  final String category;
  final String priority; // 'low', 'medium', 'high'
  final String block;
  final String floor;
  final String room;
  final String description;
  final List<String> photoUrls;

  Complaint({
    required this.category,
    required this.priority,
    required this.block,
    required this.floor,
    required this.room,
    required this.description,
    required this.photoUrls,
  });
}