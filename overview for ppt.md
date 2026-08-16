# Overview for PPT — NASC Grievance Portal

Slide-by-slide content outline for a project presentation. Each section maps to one or two slides and includes suggested talking points.

---

## Slide 1 — Title
**NASC Grievance Portal**
*Campus Complaint Management System*

- Project for Nehru Arts and Science College
- Cross-platform mobile app (Flutter)
- Presented by: [Your Name / Team]

---

## Slide 2 — Problem Statement
- Campus maintenance issues (broken fans, plumbing, Wi-Fi, furniture) are reported through paper registers or word of mouth.
- No transparency — complainants don't know when or if their issue will be fixed.
- No prioritization — urgent issues can sit unnoticed among routine requests.
- Duplicate complaints waste the maintenance team's time.
- Venue/resource booking requests have no organized workflow.

---

## Slide 3 — Solution
**A single app that digitizes the entire grievance lifecycle:**

1. Teachers raise complaints with location, category, priority, description, and photos.
2. Complainants see live status — pending → in progress → resolved.
3. Admins triage, assign technicians, and verify with before/after proof photos.
4. Duplicate reports are detected and merged.
5. Venue & resource booking requests are managed in one place.

---

## Slide 4 — Target Users / Roles
| Role | Capabilities |
| --- | --- |
| **Teacher** | Report complaint, upload photos, track tickets, campus map, contact maintenance, booking requests |
| **Admin** | Live dashboard metrics, triage & assign, resolve with proof, merge duplicates |

---

## Slide 5 — Tech Stack
- **Frontend:** Flutter (Dart) — single codebase for Android, iOS, Web, Windows, macOS
- **UI:** Material 3 design, teal brand color `#0F766E`
- **Backend:** Firebase Authentication + Cloud Firestore (no server to maintain)
- **Image hosting:** Cloudinary (photos + proof images)
- **Real-time:** Firestore streams — status updates appear live

---

## Slide 6 — Architecture
```
Flutter App
   │
   ├── Firebase Auth ──► Login / Registration, role-based dashboards
   ├── Cloud Firestore ──► users, complaints, bookings collections
   └── Cloudinary ──► image upload → secure URL stored in Firestore
```

- State management: StatefulWidget + setState (simple, beginner-friendly)
- Routing: manual Navigator.push

---

## Slide 7 — Key Features (Teacher)
- **Report Complaint:** block/floor/room, 8 categories, priority, description, up to 3 photos
- **My Tickets:** search + status filters, live status updates
- **Complaint Summary:** active / resolved / high-priority / total stat cards
- **Campus Map:** zoomable map with building pins, directions (Google Maps), share
- **Contact Maintenance:** tap-to-call help desk numbers
- **Booking:** venue + equipment quantity requests (UI ready)

---

## Slide 8 — Key Features (Admin)
- **Dashboard:** live metrics — total, pending, in-progress, resolved, high-priority
- **Triage & Assignment:** set priority, pick technician, internal notes
- **Resolution & Closure:** before/after photo verification, closure notes, confirm & close / request rework
- **Duplicate Detection:** auto-finds same block + floor + category tickets, merge into one master ticket

---

## Slide 9 — Complaint Lifecycle
```
Reported (pending)
   │  Admin triages → priority + technician
   ▼
In Progress
   │  Admin verifies with proof photo
   ├─ Confirm & Close → Resolved
   └─ Request Rework → In Progress
```
Duplicate tickets → status `merged`

---

## Slide 10 — Data Model (Firestore)
- **users:** fullName, staffId, department, designation, email, mobile, role
- **complaints:** reporterUid, category, priority, status, block, floor, room, description, photoUrls, + optional technician/notes/proof/mergedInto, createdAt
- **bookings:** bookedByUid, status, purpose, createdAt

---

## Slide 11 — How It Works (Demo Flow)
1. Teacher registers / logs in → Teacher dashboard.
2. Submit a complaint with a photo → Ticket ID generated (`#AB12CD`).
3. Admin sees it on the dashboard → assigns technician, sets priority.
4. Technician fixes it → admin uploads proof photo → Confirm & Close.
5. Teacher opens My Tickets → sees status **Resolved** in real time.

---

## Slide 12 — Security & Safety
- Role-based routing: admin vs. teacher dashboards
- Admin registration gated by a secret key
- Images compressed before upload (faster, cheaper)
- *Note:* admin key + Firestore security rules to be hardened before production

---

## Slide 13 — Achievements / Highlights
- Complete complaint lifecycle — no paper needed
- Real-time updates without a custom backend server
- Cross-platform: one Flutter codebase runs on Android/iOS/Web/Desktop
- Beginner-friendly code with extensive inline comments (great learning resource)

---

## Slide 14 — Limitations & Future Work
- **Booking persistence:** form is built; next step is writing to Firestore + admin approval
- Notifications (bell icon is visual only)
- Forgot-password flow to be implemented
- Move admin secret key server-side
- Add Firestore security rules
- Add meaningful widget tests (current test is the Flutter counter template)

---

## Slide 15 — Conclusion
- The NASC Grievance Portal replaces manual reporting with a transparent, real-time, mobile-first workflow.
- It empowers teachers with visibility and admins with control.
- Built on a modern, scalable stack that can grow with the campus.

**Thank You** — Questions welcome.
