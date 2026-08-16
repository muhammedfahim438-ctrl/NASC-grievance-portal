# PROJECT MANUAL

## NASC Grievance Portal

**A Campus Complaint & Grievance Management Mobile Application**

Built with **Flutter · Firebase · GitHub · Cloudinary**

---

| | |
| --- | --- |
| **Application Name** | NASC Grievance Portal |
| **Platform** | Android, iOS, Web, Windows, macOS |
| **Developed By** | [Your Name / Team Name] |
| **Institution** | Nehru Arts and Science College (NASC) |
| **Project Guide** | [Guide Name] |
| **Submission Date** | [DD/MM/YYYY] |
| **Course / Semester** | [Course Name, Semester X] |
| **Version** | 1.0.0 |

---

# Abstract / Overview

The **NASC Grievance Portal** is a mobile application developed to digitize the complaint and grievance workflow of Nehru Arts and Science College. Faculty members (teachers) can report campus maintenance issues — such as electrical faults, plumbing leaks, Wi-Fi failures, furniture damage, and cleaning problems — with location details, priority, descriptions, and photographs. Every complaint is saved to a cloud database and given a unique ticket number that can be tracked in real time.

Administrators log in to a dedicated dashboard where they can view live statistics, review every ticket, assign technicians, add internal notes, verify fixes with before/after proof photos, and merge duplicate reports. The app also includes an interactive campus map, a tap-to-call maintenance directory, and a venue/resource booking request module.

The application removes paper-based reporting, gives complainants full visibility of ticket status, enables prioritization of urgent issues, and reduces duplicated maintenance work — all from a single cross-platform Flutter app backed by Firebase.

---

# 1. Introduction

## 1.1 Problem Statement

Campus maintenance in colleges is traditionally managed through paper registers, verbal requests, and phone calls. This approach suffers from several problems:

1. **No transparency** — A teacher who reports an issue has no way to know whether it has been seen, assigned, or fixed.
2. **No prioritization** — Critical issues (e.g., a power failure in a lab) compete equally with minor requests and can be ignored.
3. **Duplicate work** — Multiple people report the same problem, wasting the maintenance team's time.
4. **Loss of records** — Paper registers get lost; there is no history of what was fixed, by whom, or when.
5. **No accountability** — There is no audit trail linking a reported issue to the technician assigned and the proof of resolution.
6. **Inefficient booking** — Requests for venues and equipment have no organized, trackable workflow.

## 1.2 Objectives

The primary objectives of the project are to:

1. Provide a **mobile-friendly, cross-platform** app for reporting and tracking complaints.
2. Enable **role-based access** so teachers and admins each see only what they need.
3. Support **photo-based reporting** so issues can be communicated clearly.
4. Give admins tools to **triage, prioritize, assign, resolve, and merge** complaints.
5. Provide **real-time status updates** using cloud database streams.
6. Offer supporting utilities: an **interactive campus map**, **maintenance contacts**, and **venue booking**.
7. Follow an **easy-to-learn, well-commented** codebase suitable as a learning resource.

## 1.3 Scope

### In scope
- Teacher registration and login, complaint submission (with up to 3 photos), complaint tracking with search and filters, complaint summary statistics, campus map, contact maintenance, and venue booking request UI.
- Admin registration (key protected), live dashboard metrics, ticket triage and technician assignment, resolution with proof photo and closure notes, duplicate detection and merging.
- Data persistence in Cloud Firestore, image hosting on Cloudinary, authentication via Firebase Auth.

### Out of scope (future work)
- Push notifications for status changes.
- Student-facing portal.
- Admin-side booking approval workflow.
- Multi-language support and offline-first sync.

---

# 2. System Requirements

## 2.1 Hardware Requirements

### Mobile devices (minimal)
| Component | Minimum | Recommended |
| --- | --- | --- |
| OS (Android) | Android 7.0 (API 24) | Android 12+ |
| OS (iOS) | iOS 13 | iOS 16+ |
| RAM | 2 GB | 4 GB |
| Storage | 100 MB free | 500 MB free |
| Camera | 5 MP (for complaint photos) | 12 MP+ |
| Network | 3G / Wi-Fi | 4G / 5G / Wi-Fi |

### Development machine
| Component | Minimum | Recommended |
| --- | --- | --- |
| Processor | Dual-core x64 | Quad-core i5/Ryzen 5 |
| RAM | 8 GB | 16 GB |
| Storage | 10 GB free | SSD 20 GB+ |
| OS | Windows 10 / macOS 12 | Windows 11 / macOS 14 |

## 2.2 Software Requirements

| Purpose | Software | Version |
| --- | --- | --- |
| SDK | Flutter SDK | ^3.12.2 (Dart ^3.12.2) |
| IDE | Android Studio (with Flutter plugin) or VS Code | Latest stable |
| Backend | Firebase project (`nasc-grievance-portal`) | — |
| Firebase tooling | Firebase CLI + `flutterfire_cli` | Latest |
| Image hosting | Cloudinary account + unsigned upload preset | — |
| Version control | Git + GitHub account | Latest |
| Testing | `flutter_test` (bundled) | — |
| Java (Android builds) | JDK | 17+ |
| Android build | Android SDK / Gradle | Latest |

## 2.3 Third-Party APIs & Packages

| Package | Purpose |
| --- | --- |
| `firebase_core` | Firebase initialization |
| `firebase_auth` | Email/password authentication |
| `cloud_firestore` | NoSQL cloud database |
| `image_picker` | Capture/select photos |
| `flutter_image_compress` | Client-side image compression |
| `http` | Cloudinary multipart upload |
| `intl` | Date/time formatting |
| `url_launcher` | Phone calls + Google Maps directions |
| `share_plus` | Share building locations |

---

# 3. Architecture & Design

## 3.1 System Architecture

The application follows a three-tier logical architecture with no custom backend server. Firebase provides Backend-as-a-Service.

```
┌─────────────────────────────────────────────────────┐
│                  PRESENTATION LAYER                │
│           Flutter (Dart) — Material 3 UI           │
│   Login · Register · Teacher Home · Admin Home     │
│   Complaint Screens · Booking · Campus Map         │
└──────────────────────┬──────────────────────────────┘
                       │ HTTP / HTTPS
                       ▼
┌─────────────────────────────────────────────────────┐
│                  APPLICATION LAYER                 │
│   State: StatefulWidget + setState                 │
│   Services: auth_service.dart · cloudinary_service │
│   Models: complaint_model · campus_location_model  │
└───────────────┬─────────────────────┬───────────────┘
                │                     │
                ▼                     ▼
┌─────────────────────────────┐  ┌──────────────────────┐
│      FIREBASE (BaaS)        │  │      CLOUDINARY      │
│  ├─ Firebase Auth           │  │  └─ Image upload      │
│  │   Email/Password         │  │     (unsigned preset) │
│  ├─ Cloud Firestore         │  │                       │
│  │   users / complaints /   │  │                       │
│  │   bookings               │  │                       │
│  └─ (Indexes per firestore  │  │                       │
│      .indexes.json)         │  │                       │
└─────────────────────────────┘  └──────────────────────┘
```

### Data flow example — submitting a complaint
```
Teacher selects photos
   → compressed locally (min 1024px, quality 70)
   → CloudinaryService.uploadImages() → secure_url[]
   → Firestore complaints.add({...}) → ticket ID
   → UI shows success dialog with Ticket ID (#XXXXXX)
```

### Real-time updates
All lists use Firestore **streams** (`StreamBuilder` + `.snapshots()`), so when an admin changes a status, the teacher's open screen updates instantly without a refresh.

## 3.2 Database Schema

Firestore is a **NoSQL document database**; "tables" are **collections** and "rows" are **documents**. There are three collections. The ER diagram below shows the logical relationships.

### ER-style diagram
```
┌─────────────────────────────┐
│            users            │
│  (doc ID = Firebase UID)    │
│─────────────────────────────│
│ fullName      string        │
│ staffId       string        │
│ department    string        │
│ designation   string        │
│ email         string        │
│ mobile        string        │
│ role          teacher/admin │
│ createdAt     timestamp     │
└──────────┬──────────────────┘
           │ 1  reports   N
           ▼
┌─────────────────────────────┐
│         complaints          │
│  (doc ID = ticket number)   │
│─────────────────────────────│
│ reporterUid    string ──────┼─▶ users (reporter)
│ category       string       │
│ priority       low/med/high │
│ status         pending/     │
│                in_progress/ │
│                resolved/    │
│                merged       │
│ block/floor/room  string    │
│ description     string      │
│ photoUrls       string[]    │
│ assignedTechnician (opt)    │
│ internalNotes   (opt)       │
│ closureNotes    (opt)       │
│ proofPhotoUrl   (opt)       │
│ mergedInto      (opt) ──────┼─▶ complaints (master)
│ createdAt       timestamp   │
└──────────┬──────────────────┘
           │ 1  requests   N
           ▼
┌─────────────────────────────┐
│           bookings          │
│─────────────────────────────│
│ bookedByUid     string ─────┼─▶ users (requester)
│ status          pending/    │
│                 approved/   │
│                 completed   │
│ purpose / title string      │
│ createdAt       timestamp   │
└─────────────────────────────┘
```

### Indexes (`firestore.indexes.json`)
| Collection | Fields | Used by |
| --- | --- | --- |
| complaints | `reporterUid` (ASC) + `createdAt` (DESC) | My Tickets list |
| complaints | `block` (ASC) + `category` (ASC) | Duplicate detection |

## 3.3 UI/UX Design Flow

### Navigation structure
```
LoginScreen
  ├── RegisterScreen (Teacher / Admin tabs)
  ├── TeacherHomeScreen ──► NewComplaintScreen
  │       │                ├── MyComplaintsScreen ──► ComplaintDetailsScreen
  │       │                ├── CampusMapScreen
  │       │                └── BookingDashboardScreen ──► NewBookingScreen
  │       │                                            └── BookingTicketScreen
  └── AdminHomeScreen ──► AdminTriageScreen ──► AdminDuplicateScreen
                              └──────────────► AdminResolutionScreen
```

### Teacher home (wireframe sketch)
```
┌──────────────────────────────┐
│ (Avatar) Welcome, HAI   (🔔) │  ← header + profile
│                              │
│  Today's Campus Status       │
│  [No Critical Issues  ✓]     │
│                              │
│  [Report Complaint] [My Comp]│  ← 2x2 quick action grid
│  [Contact Maint.]   [Campus ]│
│                              │
│  Complaint Summary           │
│  [Active] [Resolved]         │  ← live stat cards
│  [High P] [Total]            │
│                              │
│  ─────────────(bottom nav)───│
│   (bar) Report  |  Booking   │
└──────────────────────────────┘
```

### Design system
- Material 3, seed color `0xFF0F766E` (teal), defined in `lib/utils/app_colors.dart` (`AppColors.primary`, `secondary`, `background`, `surface`, etc.).
- Teacher content constrained to `maxWidth: 480`; admin content to `maxWidth: 700`.
- Consistent card design (16px radius, subtle shadows) across all screens.

---

# 4. Firebase Integration

## 4.1 Setting Up the Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/) and create a project named **`nasc-grievance-portal`**.
2. Enable **Authentication** → **Sign-in method** → **Email/Password**.
3. Enable **Cloud Firestore** (production mode or test mode for development).
4. Register an app per platform:
   - Android package: `com.example.nasc_grievance_portal`
   - iOS bundle: `com.example.nascGrievancePortal`
   - Web: `nasc-grievance-portal`
5. Download `google-services.json` for Android and place it in `android/app/`.
6. Initialize with the FlutterFire CLI:
   ```bash
   flutterfire configure --project=nasc-grievance-portal
   ```
   This regenerates `lib/firebase_options.dart`.

### Firebase apps configured in this project
| Platform | App ID |
| --- | --- |
| Android | `1:418669433715:android:c33e1791a08c9eb302eb06` |
| iOS / macOS | `1:418669433715:ios:19a6695d94a30f5d02eb06` |
| Web | `1:418669433715:web:61a5e99d4f0e051b02eb06` |
| Windows | `1:418669433715:web:104e55b60b050cc202eb06` |

## 4.2 Authentication

The app currently uses **Firebase Auth with Email/Password** (wrapped in `lib/services/auth_service.dart`).

| Method | Behavior |
| --- | --- |
| `signIn(email, password)` | Returns `null` on success or a friendly error string |
| `signUp(fullName, staffId, department, designation, email, mobile, password, role)` | Creates the Auth user, then writes the profile to `users/{uid}` |
| `getUserRole(uid)` | Reads `role` from `users/{uid}` to choose Teacher vs Admin dashboard |
| `signOut()` | Logs out the current user |

### How roles are enforced
```dart
// login_screen.dart
final role = await _authService.getUserRole(uid);
if (role == 'admin') {
  Navigator.pushReplacement(... AdminHomeScreen());
} else if (role == 'teacher') {
  Navigator.pushReplacement(... TeacherHomeScreen());
}
```

### Admin registration protection
Admin sign-up requires a secret key (`NASC2024ADMIN`, hardcoded in `register_screen.dart`). **Note for production:** move this validation to a Cloud Function and never ship the key in the client.

### Future authentication options (recommended roadmap)
- **Google Sign-In** — add `google_sign_in` package and enable the provider.
- **OTP / Phone** — add `firebase_auth` phone provider (`verifyPhoneNumber`).
- **JWT / token validation** — issue custom tokens via a Cloud Function for staff identity verification.
- **Password reset** — call `sendPasswordResetEmail()` (the Forgot Password button on the login screen is currently a placeholder).

## 4.3 Cloud Firestore Usage

Used as the primary database. Key operations in the app:

| Operation | Code example |
| --- | --- |
| Write complaint | `FirebaseFirestore.instance.collection('complaints').add({...})` |
| Stream own tickets | `.collection('complaints').where('reporterUid', isEqualTo: uid).orderBy('createdAt', descending: true).snapshots()` |
| Update status | `.collection('complaints').doc(id).update({'status': 'in_progress'})` |
| Assign technician | `.update({'priority': ..., 'assignedTechnician': ..., 'status': 'in_progress'})` |
| Merge duplicates | Loop `.update({'status': 'merged', 'mergedInto': masterId})` |
| Stream all tickets (admin) | `.collection('complaints').snapshots()` |

## 4.4 Firebase Storage (Images/Files)

**Not used in this project.** Images are instead uploaded to **Cloudinary** (`lib/services/cloudinary_service.dart`):

```dart
static const String _cloudName = 'awmitzkw';
static const String _uploadPreset = 'nasc_complaints';
```

Flow: `image_picker` (quality 85) → `flutter_image_compress` (min 1024×1024, quality 70) → HTTP multipart upload → `secure_url` saved into `photoUrls[]`.

> If you prefer Firebase Storage, install `firebase_storage`, replace the Cloudinary call with `FirebaseStorage.instance.ref('complaints/<uid>/<file>').putData(bytes)`, and save `getDownloadURL()` into `photoUrls`.

## 4.5 Firebase Hosting (Web Deployment)

The Flutter web target is present (`web/index.html`, `web/manifest.json`). To host it on Firebase Hosting:

1. Enable Firebase Hosting for the project.
2. Create `firebase.json` hosting config:
   ```json
   {
     "hosting": {
       "public": "build/web",
       "ignore": ["firebase.json", "**/.*", "**/node_modules/**"]
     }
   }
   ```
3. Build and deploy:
   ```bash
   flutter build web
   firebase deploy --only hosting
   ```
4. (Recommended) Wire the deployment into GitHub Actions — see Section 5.3.

---

# 5. GitHub Process

## 5.1 Repository Setup

- **Hosting:** GitHub
- **Repository URL:** `https://github.com/muhammedfahim438-ctrl/NASC-grievance-portal.git`
- **Remote:** configured as `origin`
- **Default branch:** `main`

Initialize (if cloning fresh):
```bash
git clone https://github.com/muhammedfahim438-ctrl/NASC-grievance-portal.git
cd NASC-grievance-portal
```

Recommended repository metadata:
- **Description:** "Campus complaint/grievance management app built with Flutter + Firebase."
- **Topics:** `flutter`, `firebase`, `cloud-firestore`, `complaints`, `college-project`
- **Visibility:** Private (or public for portfolio with credentials redacted).

## 5.2 Branching Strategy

Recommended GitFlow-lite workflow:

```
main              ← production-ready code (protected)
  │
  ├── dev         ← integration branch (from main)
  │     │
  │     ├── feature/login-screen      ← feature branches
  │     ├── feature/admin-triage
  │     ├── feature/booking-module
  │     └── fix/booking-firestore-write
  │
  └── tags        ← v1.0.0, v1.1.0 (releases)
```

Rules:
- Never commit directly to `main`.
- `dev` is the working integration branch.
- Each feature gets a branch named `feature/<short-name>` or `fix/<short-name>`.
- Feature branches merge into `dev` via **pull request**; after review, `dev` merges into `main` for release.
- Tag releases: `git tag -a v1.0.0 -m "Release 1.0.0"`.

## 5.3 CI/CD with GitHub Actions

> **Note:** No workflow files exist in the repo yet — the two workflows below are the recommended templates to add under `.github/workflows/`.

### Workflow 1 — PR build & staging hosting (`firebase-hosting-pull-request.yml`)
```yaml
name: Deploy to Firebase Hosting on PR
'on':
  pull_request:
    branches: [main]
jobs:
  build_and_preview:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: flutter build web --release
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          projectId: nasc-grievance-portal
```

### Workflow 2 — deploy to production on merge (`firebase-hosting-merge.yml`)
```yaml
name: Deploy to Firebase Hosting on merge
'on':
  push:
    branches: [main]
jobs:
  build_and_deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: flutter build web --release
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
          projectId: nasc-grievance-portal
```

### Setup steps for the workflows
1. In Firebase Console → Project settings → Service accounts → **Generate new private key**.
2. In GitHub → repo **Settings → Secrets and variables → Actions**, add the service-account JSON as secret `FIREBASE_SERVICE_ACCOUNT`.

## 5.4 Collaboration Guidelines

- **Commits:** small, focused, imperative mood (e.g., `Add triage screen`, `Fix booking Firestore write`).
  ```bash
  git add lib/screens/new_booking_screen.dart
  git commit -m "Persist booking documents to Firestore"
  ```
- **Pull requests:** one PR per feature; describe what/why; attach screenshots; request review before merge.
- **Code quality gates:** run before pushing:
  ```bash
  flutter analyze
  dart format lib test
  flutter test
  ```
- **No secrets in the repo:** do not commit `google-services.json` details into public README; keep API keys out of commit messages.

---

# 6. Implementation

## 6.1 Development Environment Setup

```bash
# 1. Install Flutter SDK 3.12.x (stable)
# 2. Install Android Studio / VS Code with Flutter & Dart plugins
# 3. Install Firebase CLI + FlutterFire CLI
dart pub global activate flutterfire_cli
# 4. Clone the repo
git clone https://github.com/muhammedfahim438-ctrl/NASC-grievance-portal.git
# 5. Get dependencies
flutter pub get
# 6. Configure Firebase
flutterfire configure --project=nasc-grievance-portal
# 7. Run
flutter run
```

## 6.2 Modules & Features Implemented

| # | Module | Screen(s) | Notes |
| --- | --- | --- | --- |
| 1 | Authentication | `login_screen.dart`, `register_screen.dart` | Email/password; Teacher/Admin tabs; role redirect |
| 2 | Teacher dashboard | `teacher_home_screen.dart` | Profile header, campus status card, 2×2 quick actions, live complaint summary, Report/Booking bottom nav |
| 3 | Complaint reporting | `new_complaint_screen.dart` | Location, category grid (8), priority, description, ≤3 photos, Cloudinary upload, Firestore write, ticket-ID dialog |
| 4 | Complaint tracking | `my_complaints_screen.dart` | Search + filter chips + live stream |
| 5 | Complaint details | `complaint_details_screen.dart` | Live single-document stream, photos, formatted date |
| 6 | Campus map | `campus_map_screen.dart` | InteractiveViewer zoom, tappable pins, Google Maps directions, share |
| 7 | Booking (UI) | `booking_dashboard_screen.dart`, `new_booking_screen.dart`, `booking_ticket_screen.dart` | Booking summary (live), request form, booking ticket list |
| 8 | Admin dashboard | `admin_home_screen.dart` | Live metrics + recent tickets with reporter names |
| 9 | Triage & assignment | `admin_triage_screen.dart` | Priority pills, technician dropdown, internal notes, status actions |
| 10 | Resolution & closure | `admin_resolution_screen.dart` | Before/after photo verification, proof upload, closure notes, Confirm & Close / Rework |
| 11 | Duplicate detection | `admin_duplicate_screen.dart` | Same block+floor+category candidates, checkbox merge |

## 6.3 Representative Code Snippets

### Complaint submission (trimmed, `new_complaint_screen.dart`)
```dart
// 1. Upload photos to Cloudinary first
List<String> photoUrls = [];
if (_pickedImages.isNotEmpty) {
  photoUrls = await _cloudinaryService.uploadImages(
    _pickedImages.map((img) => img.bytes).toList(),
  );
}

// 2. Save the complaint document to Firestore
final docRef = await FirebaseFirestore.instance.collection('complaints').add({
  'reporterUid': uid,
  'category': _selectedCategory,
  'priority': _selectedPriority,
  'status': 'pending',
  'block': _selectedBlock,
  'floor': _selectedFloor,
  'room': _roomController.text.trim(),
  'description': _descriptionController.text.trim(),
  'photoUrls': photoUrls,
  'createdAt': FieldValue.serverTimestamp(),
});

// 3. Show success + ticket ID
showDialog(... 'Ticket ID: #${docRef.id.substring(0, 6).toUpperCase()}' ...);
```

### Assigning a ticket (`admin_triage_screen.dart`)
```dart
await FirebaseFirestore.instance.collection('complaints').doc(widget.complaintId).update({
  'priority': _selectedPriority,
  'assignedTechnician': _selectedTechnician,
  'internalNotes': _notesController.text.trim(),
  'status': 'in_progress',
});
```

### Image compression before upload (`new_complaint_screen.dart`)
```dart
final compressedBytes = await FlutterImageCompress.compressWithList(
  rawBytes, minWidth: 1024, minHeight: 1024, quality: 70,
);
```

### Live stats stream (`teacher_home_screen.dart`)
```dart
Stream<QuerySnapshot> _myComplaintsStream() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  return FirebaseFirestore.instance
      .collection('complaints')
      .where('reporterUid', isEqualTo: uid)
      .snapshots();
}
```

## 6.4 Screenshots

> Insert screenshots here — Login, Registration, Teacher Home, New Complaint, My Tickets, Complaint Details, Admin Dashboard, Triage, Resolution, Duplicate Detection, Campus Map, Booking Dashboard.

---

# 7. Testing

## 7.1 Testing Strategy

The project currently ships the **stock Flutter counter test** (`test/widget_test.dart`) which does **not** match the app and will fail if pumped on `MyApp`. Replacing it with real tests is recommended (see 7.4). The test cases below are the **designed** test plan.

### Functional test cases

| TC | Scenario | Steps | Expected result | Status |
| --- | --- | --- | --- | --- |
| F01 | Registration (teacher) | Register with valid data, Teacher tab | Account created; redirect to login | ✔ Manual |
| F02 | Registration (admin) | Admin tab with wrong key | "Incorrect Admin Secret Key." | ✔ Manual |
| F03 | Login success | Valid email/password | Routes to role dashboard | ✔ Manual |
| F04 | Login failure | Wrong password | Friendly error snackbar | ✔ Manual |
| F05 | Submit complaint | All fields + photo | Ticket dialog, Firestore doc created | ✔ Manual |
| F06 | Submit complaint validation | Missing block/room/etc. | Snackbar prompts | ✔ Manual |
| F07 | My Tickets filters | Filter by Pending/In Progress/Resolved | Filtered list | ✔ Manual |
| F08 | Search tickets | Search category/room | Matching results | ✔ Manual |
| F09 | Triage assign | Select technician + priority | Status in_progress, technician saved | ✔ Manual |
| F10 | Resolve & close | Proof photo + notes → Confirm & Close | Status resolved | ✔ Manual |
| F11 | Rework | Request Rework | Back to in_progress | ✔ Manual |
| F12 | Duplicate merge | Select duplicates → Merge | Merged + linked to master | ✔ Manual |
| F13 | Campus map | Tap pin, Get Directions | Google Maps opens | ✔ Manual |
| F14 | Booking form | Fill venue/occasion | Validation messages / submit snackbar | ✔ Manual |

### Usability test cases
- U01: All core actions reachable within ≤ 3 taps from the dashboard.
- U02: Status badges and priority colors are consistently readable.
- U03: Error messages are human-readable (not raw exception text).
- U04: Forms show progress indicators while submitting (no frozen UI).

### Performance test cases
- P01: App cold-start < 3 s on a mid-range Android device.
- P02: Complaint list scrolls at 60 fps with 100+ docs.
- P03: Image pick → compress → upload completes within ~10 s on 4G.
- P04: Firestore stream updates reflected in < 2 s.

## 7.2 Firebase Emulator Suite (Local Testing)

Not yet configured. Recommended setup to test without touching production data:

1. Install emulators:
   ```bash
   firebase init emulators
   firebase emulators:start
   ```
2. Select **Firestore** and **Auth** emulators.
3. In the Flutter app, switch to emulator instances in debug mode:
   ```dart
   // main.dart (debug only)
   if (kDebugMode) {
     await FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
     await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
   }
   ```
4. Seed sample data in the emulator UI and run the full flow locally.

## 7.3 Bug Tracking & Fixes

- Track issues in **GitHub Issues** with labels: `bug`, `enhancement`, `ui`, `backend`.
- One notable bug already fixed (documented in code comments in `admin_triage_screen.dart`): **priority selector being overwritten by Firestore snapshots during build**. Fixed by seeding `_selectedPriority` exactly once using a `_priorityInitialized` flag + `addPostFrameCallback`.
- Another documented fix: `admin_home_screen.dart` metric-card overflow resolved by lowering `childAspectRatio` to 0.85.

## 7.4 Recommended test additions

```dart
// test/widget_test.dart replacement sketch
testWidgets('Login screen renders', (tester) async {
  await tester.pumpWidget(const MyApp());
  expect(find.text('NASC Grievance Portal'), findsOneWidget);
});
```
> `flutter test` requires Firebase initialized; use `Firebase.initializeApp` with test options or inject mocks.

---

# 8. User Manual

## 8.1 Installation

### From an APK (Android)
1. Build a release APK: `flutter build apk --release` (output: `build/app/outputs/flutter-apk/app-release.apk`).
2. Transfer the APK to the device and open it; allow **Install from unknown sources** if prompted.

### From Play Store / App Store (when published)
1. Prepare signing: set up `key.properties` + upload keystore (see Flutter docs).
2. Publish via **Play Console** or **App Store Connect**.
3. Users install from the store and sign in with their institutional email.

### From source (development)
```bash
flutter pub get
flutter run        # or: flutter run -d chrome / -d windows
```

## 8.2 Registration & Login

1. Open the app → **Sign up**.
2. Choose the **Teacher** or **Admin** tab.
3. Fill: Full Name, Staff ID/Admin ID, Department, Designation, Official Email ID, Mobile Number, Password, Confirm Password.
4. (Admin only) enter the **Admin Secret Key**.
5. Tap **Register** → back to Login → sign in with the new credentials.
6. You are routed to your dashboard automatically.

## 8.3 Step-by-Step Usage

### Reporting a complaint (Teacher)
1. Home → **Report Complaint**.
2. Select **Block**, **Floor**, enter **Room/Facility**.
3. Pick a **Category** and a **Priority**.
4. Write the **Description**; optionally add up to **3 photos**.
5. **Submit Complaint** → note your **Ticket ID** (e.g., `#AB12CD`).

### Tracking a complaint (Teacher)
1. Home → **My Complaints**.
2. Use **search** (category/room) and **filter chips**.
3. Tap a ticket for full details — status updates live.

### Admin triage
1. Admin dashboard → tap a ticket.
2. Set **priority**, pick a **technician**, add **notes** → **Assign Ticket**.
3. Use **Status Management** buttons to move to In Progress / Reopen.

### Admin resolution
1. On an `in_progress` ticket → **Resolve Ticket**.
2. Upload the **Technician Proof** photo, add **Closure Notes**.
3. **Confirm & Close** (→ resolved) or **Request Rework** (→ back to in_progress).

### Admin duplicate detection
1. Open a ticket → tap the copy icon (Check Duplicates).
2. Review **Similar Reports**; tick the duplicates.
3. **Merge Selected** → duplicates become `merged` and link to the master.

### Campus map & booking
- **Campus Map:** tap pins, zoom +/−, Get Directions, Share.
- **Booking:** Booking tab → **Booking** → fill form → Submit; **Booking Ticket** lists your bookings.

## 8.4 Error Messages & Troubleshooting

| Message | Cause | Resolution |
| --- | --- | --- |
| "No account found with this email." | Email not registered | Register first. |
| "Incorrect password. Please try again." | Wrong password | Retry or reset password (feature pending). |
| "An account already exists with this email." | Duplicate registration | Log in instead. |
| "Password is too weak. Use at least 6 characters." | Short password | Use ≥ 6 characters. |
| "Incorrect Admin Secret Key." | Wrong admin key | Contact administrator. |
| "Please select a block/floor..." | Missing required field | Fill all required fields. |
| List not loading | Missing Firestore index | Run `firebase deploy --only firestore:indexes`. |
| Photos not uploading | Cloudinary credentials / internet | Verify cloud name & preset; retry. |
| "Failed to assign/close ticket." | Firestore rules or network | Check rules and connection. |

---

# 9. Results & Performance

## 9.1 Feature Outcomes

| Feature | Outcome |
| --- | --- |
| Complaint reporting | Works end-to-end: pick → compress → upload → save → ticket ID |
| Real-time tracking | Status changes appear live via Firestore streams |
| Admin triage/resolution | Full lifecycle (pending → in_progress → resolved) with audit fields |
| Duplicate merge | Same block+floor+category tickets detected and merged |
| Campus map | Interactive, directions + share working |
| Booking | UI complete; **persistence pending** (see limitations) |

## 9.2 Performance Observations (indicative)
- **Speed:** Streams render within ~1–2 s on 4G; local filtering (search/filter chips) is instant.
- **Accuracy:** Status/priority strings are consistent across writer and reader screens (validated by matching field names).
- **Reliability:** Compression (min 1024px, q70) keeps uploads small; failed uploads are skipped without failing the complaint.
- **Resource use:** All lists are unbounded on the client (no pagination) — add `.limit()` + `startAfter()` for large datasets.

## 9.3 Firebase Analytics (recommended)
Not yet enabled. To add:
1. Add `firebase_analytics` to `pubspec.yaml`.
2. Enable **Analytics** in the Firebase console.
3. Log key events:
   ```dart
   await FirebaseAnalytics.instance.logEvent(
     name: 'complaint_submitted',
     parameters: {'category': 'electrical', 'priority': 'high'},
   );
   ```
4. Monitor **user engagement**, **screen views**, and **crash reports** (enable Crashlytics with `firebase_crashlytics`) in the console dashboard.

---

# 10. Conclusion & Future Scope

## 10.1 Achievements
- Built a **complete complaint lifecycle** from reporting to verified resolution.
- Achieved **real-time transparency** without a custom server (Firebase BaaS).
- **Cross-platform** from a single Flutter codebase.
- **Role-based** experience for teachers and admins.
- **Beginner-friendly, well-commented** code — suitable as a learning reference and easily maintainable.
- Auxiliary utilities (campus map, contacts, booking UI) broaden usefulness beyond complaints.

## 10.2 Limitations
- **Booking persistence:** the booking form (`new_booking_screen.dart`) only shows a snackbar — it does not write to Firestore yet, while the ticket list and dashboard summary already read from `bookings`.
- **Notifications:** the bell icon is decorative; no push notifications.
- **Forgot password:** button present but not wired to `sendPasswordResetEmail`.
- **Admin secret key** is hardcoded in the client.
- **Firestore security rules** are not defined.
- **Booking admin approval** flow does not exist (statuses `approved`/`completed` are counted but never set).
- **Tests:** only the stock Flutter counter test exists.

## 10.3 Future Upgrades
1. **Persist booking documents** (`bookedByUid`, `status: 'pending'`, `purpose`, `createdAt`) and add an **admin booking approval screen**.
2. **Push notifications** via Firebase Cloud Messaging on status change / assignment / approval.
3. **Cloud Functions** for admin-key validation, duplicate auto-detection, and scheduled report generation.
4. **Firestore security rules** + role-based read/write enforcement.
5. **Firebase Analytics + Crashlytics** for engagement and stability monitoring.
6. **Pagination & search** on Firestore queries for scalability with large datasets.
7. **Google Sign-In / OTP** authentication options and password reset.
8. **Student role** and public reporting portal; offline-first support via `cloud_firestore` offline persistence.
9. **Firebase Storage** migration or hybrid storage strategy as an alternative to Cloudinary.
10. **CI/CD** with the GitHub Actions workflows described in Section 5.3.

---

# 11. References

### Documentation
- Flutter documentation — https://docs.flutter.dev
- Firebase documentation — https://firebase.google.com/docs
- Firebase Auth — https://firebase.google.com/docs/auth
- Cloud Firestore — https://firebase.google.com/docs/firestore
- FlutterFire (Firebase for Flutter) — https://firebase.flutter.dev
- Cloudinary API — https://cloudinary.com/documentation
- GitHub Actions — https://docs.github.com/actions
- Firebase Hosting on GitHub Actions — https://github.com/FirebaseExtended/action-hosting-deploy
- FlutterFire CLI — https://firebase.flutter.dev/docs/cli

### Packages used (pub.dev)
- `firebase_core`, `firebase_auth`, `cloud_firestore`
- `image_picker`, `flutter_image_compress`
- `http`, `intl`, `url_launcher`, `share_plus`, `cupertino_icons`

### Tools
- Flutter SDK 3.12.x, Dart 3.12.x
- Android Studio / VS Code
- Firebase Console + Firebase CLI
- Git + GitHub
- Cloudinary console

### Reference material (learning)
- Flutter official codelabs: https://docs.flutter.dev/get-started/codelab
- Firebase + Flutter codelab: https://firebase.google.com/codelabs/firebase-get-to-know-flutter

---

# 12. Appendices

## Appendix A — Key Code Snippets

### `lib/services/auth_service.dart` — signUp
```dart
final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
  email: email.trim(), password: password);
await FirebaseFirestore.instance.collection('users')
    .doc(userCredential.user!.uid).set({
  'fullName': fullName, 'staffId': staffId, 'department': department,
  'designation': designation, 'email': email.trim(), 'mobile': mobile,
  'role': role, 'createdAt': FieldValue.serverTimestamp(),
});
```

### `lib/services/cloudinary_service.dart` — uploadImage
```dart
final request = http.MultipartRequest('POST',
  Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload'));
request.fields['upload_preset'] = _uploadPreset;
request.files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: fileName));
final response = await request.send();
// ... returns jsonData['secure_url'] on 200
```

### Duplicate merge (`admin_duplicate_screen.dart`)
```dart
for (final duplicateId in _selectedDuplicateIds) {
  await FirebaseFirestore.instance.collection('complaints').doc(duplicateId).update({
    'status': 'merged', 'mergedInto': masterId,
  });
}
```

## Appendix B — Additional Screenshots

> Insert any remaining screenshots here (empty-state screens, error snackbars, web build, release APK install).

## Appendix C — API / Endpoint Summary

| Endpoint / Call | Type | Purpose |
| --- | --- | --- |
| `POST https://api.cloudinary.com/v1_1/awmitzkw/image/upload` | HTTP multipart | Image upload (preset: `nasc_complaints`) |
| `FirebaseAuth.signInWithEmailAndPassword` | SDK | Login |
| `FirebaseAuth.createUserWithEmailAndPassword` | SDK | Registration |
| `Firestore.collection('complaints').add/update/snapshots` | SDK | Complaint CRUD + live stream |
| `Firestore.collection('users').doc(uid).get/set` | SDK | Profile read/write |
| `Firestore.collection('bookings').where().snapshots()` | SDK | Booking read |

---

*End of Project Manual — NASC Grievance Portal v1.0.0*
