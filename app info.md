# App Info — NASC Grievance Portal

High-level application documentation: what the app is, its architecture, screens, flows, and design system.

---

## 1. Application Overview

- **Name:** NASC Grievance Portal
- **Package name:** `nasc_grievance_portal`
- **Version:** 1.0.0+1
- **Platform:** Flutter (Android, iOS, Web, Windows, macOS)
- **Target users:** Teachers (reporters) and Admins (maintenance/facility management) at Nehru Arts and Science College

The app digitizes the campus grievance workflow — from "I see a broken fan in Lab 102" to "ticket closed with before/after proof" — in one place.

---

## 2. Tech Stack

| Category | Choice |
| --- | --- |
| Language | Dart (`sdk ^3.12.2`) |
| UI framework | Flutter, Material 3 |
| Backend | Firebase Authentication, Cloud Firestore |
| Image storage | Cloudinary |
| State management | StatefulWidget + setState (no third-party state lib) |
| Routing | Manual `Navigator.push` (no named routes) |

### Key dependencies (`pubspec.yaml`)
- `firebase_core`, `firebase_auth`, `cloud_firestore`
- `image_picker`, `flutter_image_compress`
- `http` (Cloudinary upload)
- `intl` (date formatting)
- `url_launcher` (call, maps)
- `share_plus` (share location)

---

## 3. App Entry Point & Flow

`lib/main.dart` → initializes Firebase → `MaterialApp` (seed color `0xFF0F766E`, Material 3) → `LoginScreen`.

```
LoginScreen
  ├── role == 'teacher' → TeacherHomeScreen
  └── role == 'admin'   → AdminHomeScreen
```

---

## 4. Screens

### 4.1 Shared / Auth
| Screen | File | Purpose |
| --- | --- | --- |
| Login | `login_screen.dart` | Email/password sign in, role-based redirect, forgot-password placeholder |
| Register | `register_screen.dart` | Teacher/Admin tabs, full profile form, admin secret key |

### 4.2 Teacher Side
| Screen | File | Purpose |
| --- | --- | --- |
| Teacher Home | `teacher_home_screen.dart` | Header w/ profile, campus status card, quick-action grid (Report, My Complaints, Contact Maintenance, Campus Map), live complaint summary, Report/Booking bottom nav |
| New Complaint | `new_complaint_screen.dart` | Location, category grid, priority, description, up to 3 photos → Cloudinary → Firestore |
| My Complaints | `my_complaints_screen.dart` | Search + status filter + live list of own tickets |
| Complaint Details | `complaint_details_screen.dart` | Live ticket detail view (status, date, photos) |
| Campus Map | `campus_map_screen.dart` | Zoomable map image with tappable pins, directions, share |
| Booking Dashboard | `booking_dashboard_screen.dart` | Booking actions (New Booking, Booking Ticket, Campus Map) + live booking summary |
| New Booking | `new_booking_screen.dart` | Venue + equipment quantity request form (write NOT yet implemented) |
| Booking Ticket | `booking_ticket_screen.dart` | Live list of own bookings from `bookings` collection |

### 4.3 Admin Side
| Screen | File | Purpose |
| --- | --- | --- |
| Admin Home | `admin_home_screen.dart` | Live metric cards (total/pending/in-progress/resolved/high-priority) + recent tickets w/ reporter names |
| Admin Triage | `admin_triage_screen.dart` | Priority, technician assignment, internal notes, status changes, link to duplicate check |
| Admin Resolution | `admin_resolution_screen.dart` | Before/after verification, proof photo upload, closure notes, Confirm & Close / Request Rework |
| Admin Duplicate | `admin_duplicate_screen.dart` | Finds same block+floor+category tickets, merges selected into master |

---

## 5. Key Flows

### Complaint lifecycle
```
Teacher submits (pending)
  → Admin triages: priority + technician + notes (in_progress)
  → Admin resolves: proof photo + closure notes
       ├─ Confirm & Close  → resolved
       └─ Request Rework   → back to in_progress
  → (optional) Duplicate merge → merged
```

### Image pipeline
```
image_picker (q85) → compress (min 1024, q70) → Cloudinary upload → URL stored in complaint
```

### Live updates
All complaint/booking lists use `StreamBuilder` + Firestore `.snapshots()`, so screens update in real time whenever an admin (or user) changes a document.

---

## 6. Design System (`lib/utils/app_colors.dart`)

| Token | Value | Usage |
| --- | --- | --- |
| `primary` | `0xFF0F766E` (teal) | Buttons, headings, active states |
| `secondary` | `0xFF14B8A6` | Icons, resolved accents |
| `background` | `0xFFF8FAFC` | App background |
| `surface` | `0xFFFFFFFF` | Cards / inputs |
| `onSurface` | `0xFF0F172A` | Main text |
| `onSurfaceVariant` | `0xFF475569` | Subtitles, hints |
| `outlineVariant` | `0xFFCBD5E1` | Borders |
| `error` | `0xFFBA1A1A` | Validation / high priority |

**Layout conventions:** teacher screens center content at `maxWidth: 480`; admin screens use `maxWidth: 700`.

---

## 7. Naming & Data Conventions

- **Ticket number** = first 6 characters of the Firestore document ID, uppercased (e.g. `#AB12CD`).
- **Status strings:** `pending`, `in_progress`, `resolved`, `merged`.
- **Priority strings:** `low`, `medium`, `high`.
- **Categories:** `electrical`, `plumbing`, `it`, `carpentry`, `cleaning`, `furniture`, `wifi`, `other`.
- **Field names** in Firestore must be identical across writer and reader screens.

---

## 8. Current Gaps / Next Steps

- Booking form is a UI-only placeholder — write to Firestore next.
- Notifications bell is decorative.
- Forgot-password flow is unwired.
- Admin secret key should move server-side.
- Firestore security rules missing.
- `test/widget_test.dart` is the stock counter test and does not match the app.
