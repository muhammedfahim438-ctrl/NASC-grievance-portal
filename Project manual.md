# Project Manual — NASC Grievance Portal

**Version:** 1.0.0  
**Platform:** Flutter (Android, iOS, Web, Windows, macOS)  
**Backend:** Firebase (Authentication + Cloud Firestore) + Cloudinary  
**Documentation scope:** For students, faculty, admins, and maintenance staff.

---

## 1. About the Project

The **NASC Grievance Portal** is a campus grievance management application built for **Nehru Arts and Science College (NASC)**. It digitizes the complaint/issue-reporting workflow so that faculty members can raise maintenance issues (electrical, plumbing, IT, etc.) with photos and track them in real time, while administrators can triage, assign technicians, verify resolutions, and detect duplicate reports. The app also supports venue/resource booking requests for campus events.

### Why this project exists
- Replaces paper registers and phone calls for reporting issues.
- Gives complainants a transparent view of ticket status at all times.
- Helps admins prioritize (High / Medium / Low) and assign the right technician.
- Reduces duplicate work by merging identical complaints.

### Roles
| Role | What they can do |
| --- | --- |
| **Teacher** | Report complaints, upload photos, track status, contact maintenance, use campus map, request venue bookings |
| **Admin** | View all complaints, live metrics, triage & assign, resolve with proof, merge duplicates |

---

## 2. Installation & Setup

### 2.1 Prerequisites
- Flutter SDK `^3.12.2` (Dart `^3.12.2`)
- Firebase project `nasc-grievance-portal` with Authentication (Email/Password) and Cloud Firestore enabled
- Cloudinary account with an upload preset
- Android Studio / Xcode / VS Code as needed per platform

### 2.2 Steps
1. **Clone / copy** the project folder.
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **Configure Firebase** (regenerates `lib/firebase_options.dart` and `android/app/google-services.json`):
   ```bash
   flutterfire configure --project=nasc-grievance-portal
   ```
4. **Set Cloudinary credentials** in `lib/services/cloudinary_service.dart`:
   ```dart
   static const String _cloudName = 'awmitkzw';
   static const String _uploadPreset = 'nasc_complaints';
   ```
5. **Deploy Firestore indexes** (required for the My Tickets and duplicate-detection queries):
   ```bash
   firebase deploy --only firestore:indexes
   ```
6. **Run the app:**
   ```bash
   flutter run
   ```

---

## 3. User Guide

### 3.1 Creating an Account (Registration)

1. Open the app — the **Login** screen appears.
2. Tap **Sign up**.
3. Choose a tab at the top:
   - **Teacher** — to register as a faculty member.
   - **Admin** — to register as an administrator.
4. Fill in: Full Name, Staff ID (or Admin ID), Department, Designation, Official Email ID, Mobile Number, Password, Confirm Password.
5. For the **Admin** tab, also enter the **Admin Secret Key** (`NASC2024ADMIN`).
6. Tap **Register**. You will be returned to the Login screen to sign in.

> Admin access is protected by a secret key so that only authorized staff can create admin accounts.

### 3.2 Logging In

1. Enter your institutional email and password.
2. Tap **Sign In**.
3. You are automatically routed to the correct dashboard based on your role (Teacher or Admin).

Friendly error messages are shown for wrong passwords, unknown emails, etc.

### 3.3 Teacher — Reporting a Complaint

1. From the Teacher home, tap **Report Complaint**.
2. **Location Details:** select Block (A/B/C/D), Floor, and enter Room/Facility (e.g. Lab 102).
3. **Complaint Category:** pick one — Electrical, Plumbing, IT/Proj., Carpentry, Cleaning, Furniture, Wi-Fi, or Other.
4. **Priority Level:** Low, Medium, or High.
5. **Issue Description:** describe the issue clearly.
6. **Upload Images (Optional):** add up to 3 photos (compressed automatically).
7. Tap **Submit Complaint**.

On success you receive a **Ticket ID** (e.g. `#AB12CD`) and a confirmation dialog: *"The maintenance team has been notified."*

### 3.4 Teacher — Tracking Complaints

- Tap **My Complaints** on the home screen.
- Use the **search bar** (category or room) and **filter chips** (All / Pending / In Progress / Resolved).
- Tap any ticket to open **Complaint Details**:
  - Ticket ID, status badge, submission date/time.
  - Category, priority, location, full description.
  - Uploaded photos (if any).
- The details screen updates **live** — if an admin changes the status while you are viewing, the screen refreshes by itself.

### 3.5 Teacher — Complaint Summary Dashboard

The teacher home screen shows four live stat cards computed from your own complaints:
- Active Reports
- Resolved
- High Priority
- Total Submitted

### 3.6 Teacher — Campus Map

1. Tap **Campus Map**.
2. Tap a **pin** on the map to select a building (Arts Block A, Science Block, Central Library, Admin Block).
3. The bottom card shows name, address, and walking distance.
4. **Get Directions** opens Google Maps; **Share Location** shares the address.
5. Use the **+ / −** buttons to zoom and the **locate** button to reset.

### 3.7 Teacher — Contact Maintenance

The **Contact Maintenance** quick-action lists Main Desk, Electrical Shop, and Plumbing Unit. Tap the call icon to dial the number directly.

### 3.8 Teacher — Booking a Venue (Booking Tab)

1. Tap the **Booking** tab at the bottom → **Booking Dashboard**.
2. Tap **Booking** to create a request.
3. Select a **Location** (Auditorium, Seminar Hall, Lobby, Department).
4. Select a **Booking Category** and set quantities (Mic, Speaker, Camera, Light, Chairs, Tables, Carpets, Others).
5. Enter **Organizer Name**, **Occasion** (mandatory), **Booking Duration** (from/to date and time), and additional notes.
6. Tap **Submit Booking Request**.
7. Tap **Booking Ticket** to view your submitted bookings with their status.
8. The dashboard shows a **Booking Summary** with Total, Pending, Approved, and Completed counts (live from Firestore).

### 3.9 Admin — Dashboard

After logging in as admin you see:
- **Header** with Admin Dashboard title and Logout button.
- **Live metrics cards:** Total Complaints, Pending Review, In Progress, Resolved, High Priority.
- **Recent Tickets** list (newest first). Each card shows the ticket number, status, reporter name, location, category, and priority.

### 3.10 Admin — Triage & Assignment

Tap any ticket to open **Triage & Assignment**:
1. Review the ticket info, photos, and current status.
2. **Status Management:** move the ticket to **In Progress**, then **Resolve Ticket**, or **Reopen Ticket** if it was resolved.
3. **Action & Assignment:**
   - Set **Priority Level** (Low / Medium / High).
   - Select an **Assigned Technician** (Electrician, Plumber, General Maintenance, IT Support).
   - Add **Internal Notes** (optional instructions).
4. Tap **Assign Ticket**. This sets status to `in_progress` and saves the technician.

### 3.11 Admin — Resolution & Closure

From a ticket `in_progress`, tap **Resolve Ticket**:
1. **Grievance Verification** shows the original issue photo beside a **Technician Proof** photo slot — tap the proof box to upload the resolved-state photo.
2. Add **Closure Notes** (optional).
3. Choose:
   - **Request Rework** — sends the ticket back to `in_progress`.
   - **Confirm & Close** — marks the ticket `resolved` and saves the proof photo + notes.

### 3.12 Admin — Duplicate Detection

Tap the copy icon (or use the duplicate screen) to find **Similar Reports** — other active tickets in the same block, floor, and category.
1. Select the duplicates using the checkboxes.
2. **Merge Selected** marks each duplicate as `merged` and links it to the master ticket.
3. **Discard as Non-Duplicate** simply goes back.

---

## 4. Lifecycle of a Complaint

```
Reported (pending)
      │
      ▼
Triage & Assignment → status = in_progress, technician assigned
      │
      ▼
Resolution & Closure → proof photo + closure notes
      ├─ Confirm & Close → status = resolved
      └─ Request Rework  → status = in_progress (back to work)
```

Duplicate tickets can be merged at any stage; a merged ticket's status becomes `merged`.

---

## 5. Firestore Data Model

### Collection `users`
| Field | Type | Notes |
| --- | --- | --- |
| fullName | string | Display name |
| staffId | string | Staff/Admin ID |
| department | string | e.g. cs, cs_ds, aiml, bca, others |
| designation | string | staff / admin |
| email | string | Login email |
| mobile | string | Contact number |
| role | string | `teacher` or `admin` |
| createdAt | timestamp | Server time |

### Collection `complaints`
| Field | Type | Notes |
| --- | --- | --- |
| reporterUid | string | UID of the reporting teacher |
| category | string | electrical, plumbing, it, carpentry, cleaning, furniture, wifi, other |
| priority | string | low / medium / high |
| status | string | pending / in_progress / resolved / merged |
| block | string | A/B/C/D Block |
| floor | string | Ground–Fourth Floor |
| room | string | Room/facility |
| description | string | Issue description |
| photoUrls | string[] | Cloudinary URLs of complaint photos |
| assignedTechnician | string | Set during triage (optional) |
| internalNotes | string | Admin notes for technician (optional) |
| closureNotes | string | Resolution remarks (optional) |
| proofPhotoUrl | string | Before/after proof (optional) |
| mergedInto | string | Master ticket ID if merged (optional) |
| createdAt | timestamp | Server time |

### Collection `bookings`
| Field | Type | Notes |
| --- | --- | --- |
| bookedByUid | string | UID of the requesting teacher |
| status | string | pending / approved / completed |
| purpose / title | string | Occasion/event name |
| createdAt | timestamp | Server time |

---

## 6. Troubleshooting

| Problem | Likely cause / fix |
| --- | --- |
| "No account found with this email" | Email not registered — sign up first. |
| "Incorrect email or password" | Wrong credentials — reset password or retry. |
| "An account already exists with this email" | Email already registered — log in instead. |
| Complaint list won't load | Firestore index missing — deploy `firestore.indexes.json`. |
| Photos fail to upload | Check Cloudinary cloud name / upload preset and internet connection. |
| Admin registration rejected | The Admin Secret Key entered is incorrect. |
| Tickets not updating | Check Firestore security rules allow reads/writes for the collection. |

---

## 7. Known Limitations & Roadmap

- **Forgot password** — button exists but is not wired up yet.
- **Bookings** — the request form is not yet persisted to Firestore (`new_booking_screen.dart` shows a placeholder submit); the ticket list reads from `bookings` but nothing writes to it yet.
- **Notifications** — the bell icon is visual only.
- **Campus map locations** are hardcoded in `campus_location_model.dart`; can move to Firestore later.
- **Admin secret key** is hardcoded in `register_screen.dart` — move to a secure server/Cloud Function in production.
- **Firestore security rules** are not present in this repo — define them before production.

---

## 8. Version History

| Version | Date | Notes |
| --- | --- | --- |
| 1.0.0 | 2026 | Complaint reporting, tracking, admin triage/resolution/duplicates, campus map, booking UI |
