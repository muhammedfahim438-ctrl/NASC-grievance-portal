# NASC Grievance Portal

A Flutter-based grievance management mobile app for the Nehru Arts and Science College (NASC) campus. Teachers can report campus maintenance issues with photos, track complaint status in real time, and request venue/resource bookings. Admins can triage, assign, resolve, and detect duplicate complaints.

## Features

- **Role-based access** — Teacher and Admin dashboards
- **Complaint reporting** — location (block/floor/room), category, priority, description, up to 3 photos
- **Live status tracking** — Pending / In Progress / Resolved, updates in real time via Firestore
- **Admin triage & assignment** — set priority, assign technicians, add internal notes
- **Resolution & closure** — proof photo + closure notes, before/after verification, rework requests
- **Duplicate detection** — finds similar active tickets in the same block/floor/category and merges them
- **Campus map** — interactive zoomable map with pins, directions, and share
- **Venue & resource booking** — request auditorium/seminar hall with equipment quantities and date/time
- **Photo upload** — compressed client-side and uploaded to Cloudinary

## Tech Stack

| Layer | Technology |
| --- | --- |
| Frontend | Flutter (Dart, Material 3) |
| Backend | Firebase (Authentication, Cloud Firestore) |
| Image hosting | Cloudinary |
| Platforms | Android, iOS, Web, Windows, macOS |

## Project Structure

```
lib/
├── main.dart                  # App entry point + Firebase init
├── firebase_options.dart      # Firebase config per platform (generated)
├── models/
│   ├── complaint_model.dart   # Complaint data model
│   └── campus_location_model.dart  # Campus map building pins
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── teacher_home_screen.dart
│   ├── new_complaint_screen.dart
│   ├── my_complaints_screen.dart
│   ├── complaint_details_screen.dart
│   ├── campus_map_screen.dart
│   ├── booking_dashboard_screen.dart
│   ├── new_booking_screen.dart
│   ├── booking_ticket_screen.dart
│   ├── admin_home_screen.dart
│   ├── admin_triage_screen.dart
│   ├── admin_resolution_screen.dart
│   └── admin_duplicate_screen.dart
├── services/
│   ├── auth_service.dart      # Sign in / sign up / role lookup
│   └── cloudinary_service.dart # Image upload
└── utils/
    └── app_colors.dart        # Design system colors
```

## Getting Started

### Prerequisites

- Flutter SDK `^3.12.2` (Dart `^3.12.2`)
- A Firebase project (auth + Firestore enabled)
- A Cloudinary account (upload preset)

### Setup

1. Clone the repository.
2. Install dependencies:

```bash
flutter pub get
```

3. Configure Firebase:

```bash
# Requires flutterfire_cli
flutterfire configure --project=nasc-grievance-portal
```

4. Set your Cloudinary credentials in `lib/services/cloudinary_service.dart`:

```dart
static const String _cloudName = 'YOUR_CLOUD_NAME';
static const String _uploadPreset = 'YOUR_UPLOAD_PRESET';
```

5. Run the app:

```bash
flutter run
```

### Firestore Indexes

The following composite indexes are required (defined in `firestore.indexes.json`):

- `complaints`: `reporterUid` (ASC) + `createdAt` (DESC)
- `complaints`: `block` (ASC) + `category` (ASC)

Deploy with:

```bash
firebase deploy --only firestore:indexes
```

## Firestore Data Model

### `users`
| Field | Type |
| --- | --- |
| fullName | string |
| staffId | string |
| department | string |
| designation | string |
| email | string |
| mobile | string |
| role | `teacher` \| `admin` |
| createdAt | timestamp |

### `complaints`
| Field | Type |
| --- | --- |
| reporterUid | string |
| category | `electrical` \| `plumbing` \| `it` \| `carpentry` \| `cleaning` \| `furniture` \| `wifi` \| `other` |
| priority | `low` \| `medium` \| `high` |
| status | `pending` \| `in_progress` \| `resolved` \| `merged` |
| block / floor / room | string |
| description | string |
| photoUrls | string[] |
| assignedTechnician | string (optional) |
| internalNotes | string (optional) |
| closureNotes | string (optional) |
| proofPhotoUrl | string (optional) |
| mergedInto | string (optional) |
| createdAt | timestamp |

### `bookings`
| Field | Type |
| --- | --- |
| bookedByUid | string |
| status | `pending` \| `approved` \| `completed` |
| purpose / title | string |
| createdAt | timestamp |

## Usage

**Teacher**
1. Sign in or register (Teacher tab).
2. Home → Report Complaint → fill location, category, priority, description, add photos → Submit.
3. Track tickets under My Tickets (search + status filters). Details update live.
4. Request bookings from the Booking tab.

**Admin**
1. Register/Login via Admin tab (requires the admin secret key `NASC2024ADMIN`).
2. Dashboard shows live metrics + recent tickets.
3. Open a ticket → Triage: set priority, assign technician, update status.
4. In Progress → Resolve Ticket: add proof photo + closure notes, Confirm & Close, or Request Rework.
5. Check Duplicates → merge similar tickets.

## Running Tests

```bash
flutter test
```

## License

Private project — not intended for public distribution.
