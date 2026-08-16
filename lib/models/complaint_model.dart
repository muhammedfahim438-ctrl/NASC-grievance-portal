// lib/models/complaint_model.dart
//
// Defines the "shape" of a Complaint document in Firestore.
// Field names here MUST match exactly what my_complaints_screen.dart
// reads, and what new_complaint_screen.dart writes.
import 'package:cloud_firestore/cloud_firestore.dart';

class Complaint {
  final String id; // Firestore's auto-generated document ID (used as ticket #)
  final String category;
  final String priority; // 'low', 'medium', 'high'
  final String status; // 'pending', 'in_progress', 'resolved'
  final String block;
  final String floor;
  final String room;
  final String description;
  final List<String> photoUrls;
  final String reporterUid;
  final DateTime? createdAt;

  Complaint({
    required this.id,
    required this.category,
    required this.priority,
    required this.status,
    required this.block,
    required this.floor,
    required this.room,
    required this.description,
    required this.photoUrls,
    required this.reporterUid,
    this.createdAt,
  });

  // Converts a raw Firestore document into a Complaint object.
  // We'll use this later if we refactor my_complaints_screen.dart
  // to use this model instead of reading the map directly.
  factory Complaint.fromFirestore(String id, Map<String, dynamic> data) {
    return Complaint(
      id: id,
      category: data['category'] ?? 'other',
      priority: data['priority'] ?? 'medium',
      status: data['status'] ?? 'pending',
      block: data['block'] ?? '',
      floor: data['floor'] ?? '',
      room: data['room'] ?? '',
      description: data['description'] ?? '',
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      reporterUid: data['reporterUid'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // Converts this object into a Map, ready to save to Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'category': category,
      'priority': priority,
      'status': status,
      'block': block,
      'floor': floor,
      'room': room,
      'description': description,
      'photoUrls': photoUrls,
      'reporterUid': reporterUid,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}