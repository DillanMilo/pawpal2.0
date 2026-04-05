# PawPal 2.0 Features

> Complete feature inventory as of 2026-04-04

---

## Authentication & Accounts

| Feature | Details |
|---------|---------|
| Email/password signup | Registration with name, email, password (8-char min, RFC email validation) |
| Email/password login | Sign in with existing credentials |
| Google OAuth | One-tap Google sign-in with OAuth redirect |
| Apple OAuth | Sign in with Apple ID |
| Password reset | Email-based password recovery flow |
| User profile | Name, email, phone, zip code, profile photo upload |
| Session management | Auto-restore sessions via Supabase Auth |
| Secure sign out | Clears all provider state and navigates to login |

---

## Pet Management

| Feature | Details |
|---------|---------|
| Add pet | Name, species (9 types), breed, gender, DOB, weight, color, microchip number, spayed/neutered status |
| Edit pet | Update all pet information, change photo |
| Delete pet | Remove pet with confirmation |
| Multiple pets | Manage unlimited pets per account |
| Pet photos | Upload from camera or gallery, image cropping, cached display |
| Pet carousel | Swipeable pet cards on home screen with quick selection |
| Pet detail view | Full profile with medical, activity, and passport access |

**Supported species:** Dog, Cat, Bird, Fish, Rabbit, Hamster, Guinea Pig, Reptile, Other

---

## Medical Records

| Feature | Details |
|---------|---------|
| Record types | Vaccination, Medication, Allergy, Vet Visit, Grooming, Surgery, Lab Result |
| Create record | Title, description, date, provider, type-specific fields |
| Edit record | Pre-filled form with existing data, update in place |
| Document upload | Attach photos/documents to medical records |
| Due date tracking | Next due date for vaccinations and medications |
| Active medications | Track current medications with start/end dates |
| Dosage & frequency | Record medication dosage and schedule |
| Filter by type | View records filtered by medical record type |

---

## Pet Passport

| Feature | Details |
|---------|---------|
| QR code generation | Unique QR code containing pet identity and health data |
| Privacy controls | Toggle what info to include (basic info, vaccinations, medications, allergies, emergency contact) |
| Share passport | Native share dialog with formatted text passport |
| Export | Formatted text export respecting privacy toggle settings |

---

## Activity Tracking

| Feature | Details |
|---------|---------|
| Activity types | Walk (10pts), Play (8pts), Train (15pts), Feed (5pts), Groom (7pts), Vet Visit (20pts), Social (12pts), Rest (3pts) |
| Timer mode | Start/stop timer for real-time activity tracking |
| Manual entry | Log activity with custom duration |
| Points system | Earn points per activity, tracked per user |
| Streaks | Consecutive day tracking (optimized single-query calculation) |
| Activity history | Filterable by type and date, grouped by day |
| Weekly chart | Visual bar chart of weekly activity (fl_chart) |
| Per-pet history | View activity history for individual pets |

---

## Gamification

| Feature | Details |
|---------|---------|
| Paw Points | Cumulative points earned from all activities |
| Day Streaks | Consecutive days with at least one logged activity |
| Badges | Unlockable achievements based on milestones |
| Achievement preview | Badge display on profile screen |

**Badge types:**
| Badge | Threshold |
|-------|-----------|
| First Walk | 1 walk logged |
| Week Warrior | 7-day streak |
| Training Pro | 10 training sessions |
| Social Butterfly | 5 social activities |
| Health Champion | All vaccinations up to date |
| Consistent Caregiver | 30-day streak |

---

## Calendar & Appointments

| Feature | Details |
|---------|---------|
| Calendar view | Monthly calendar with marked appointment dates |
| Create appointment | Title, date/time, pet selection, type, notes |
| Appointment types | Vet, Grooming, Training, Other |
| Mark complete | Toggle appointment completion status |
| Date navigation | Browse months, select individual dates |

---

## Reminders

| Feature | Details |
|---------|---------|
| Create reminder | Title, type, due date, pet selection, notes |
| Reminder types | Medication, Vaccination, Appointment, Grooming, Custom |
| Recurring patterns | Daily, weekly, monthly auto-creation on completion |
| Filter by status | All, Today, Upcoming, Overdue |
| Mark complete | Complete reminders with automatic next-occurrence creation |
| Delete | Remove reminders |

---

## Push Notifications

| Feature | Details |
|---------|---------|
| Reminder alerts | Notification 1 hour before + at due time |
| Daily activity reminder | Configurable daily prompt to log activities |
| Streak reminders | Alert to maintain activity streaks |
| Notification preferences | Master toggle + per-type toggles (persisted via SharedPreferences) |
| Tap navigation | Tapping a notification navigates to the relevant screen |
| Android channels | Separate notification channels for different types |

---

## Provider Discovery

| Feature | Details |
|---------|---------|
| Service types | Veterinarians, Groomers, Pet Stores (Pet Sitters coming soon) |
| GPS search | Auto-detect location, search within 10km radius |
| Zipcode search | Fallback search by zipcode when GPS denied |
| Place details | Name, address, rating, open/closed status, phone, hours |
| Photo display | Google Places photos with cached loading |
| Directions | Deep link to maps for directions |
| Call | Direct phone call to business |
| Pull-to-refresh | Refresh search results |
| Business listing | Full detail view with all place information |

---

## User Profile

| Feature | Details |
|---------|---------|
| Stats overview | Total points, current streak, pets count |
| Achievement badges | Preview of earned and locked badges |
| Notification settings | Master toggle + Reminder Alerts + Streak Reminders (persisted) |
| Sign out | Secure logout with state cleanup |

---

## Quick Actions

| Feature | Details |
|---------|---------|
| Quick actions menu | Fast access to common tasks from home screen |
| Add medication | Streamlined medication logging with pet selection |
| Add vet visit | Quick vet visit recording |
| Add grooming | Fast grooming service logging |

---

## Offline Mode

| Feature | Details |
|---------|---------|
| Connectivity detection | Real-time monitoring via `connectivity_plus` |
| Offline banner | Auto-showing/dismissing MaterialBanner when offline |
| Cached data | Serves cached data from providers when offline (5-min TTL) |
| Graceful degradation | Informative error messages instead of crashes when offline |

---

## Dark Theme

| Feature | Details |
|---------|---------|
| System auto-switch | Follows device light/dark mode setting |
| Dark surfaces | Custom dark background, surface, and card colors |
| Brand consistency | Same accent colors and gradients adapted for dark mode |
| WCAG AA contrast | All text meets accessibility contrast requirements |

---

## Accessibility

| Feature | Details |
|---------|---------|
| Screen reader support | Semantics labels on all interactive elements (~26 files) |
| Button semantics | All tappable elements use proper button widgets (InkWell/IconButton) |
| Tooltips | Descriptive tooltips on all icon-only buttons |
| Color contrast | WCAG AA compliant text colors |
| Focus states | Proper focus borders on form fields and interactive elements |

---

## Security

| Feature | Details |
|---------|---------|
| Environment secrets | API keys stored in `.env` file (gitignored), loaded via `flutter_dotenv` |
| Row-Level Security | All Supabase tables have RLS policies — users can only access own data |
| Input validation | RFC-compliant email regex, 8-character minimum passwords |
| Secure storage | `flutter_secure_storage` available for sensitive credentials |
| OAuth security | Configured redirect URIs for Google and Apple sign-in |
| Error handling | Global ErrorWidget.builder for release mode, 404 route handler |

---

## Developer Experience

| Feature | Details |
|---------|---------|
| 127 automated tests | Models, providers, widgets, services, constants |
| GitHub Actions CI/CD | Lint + test + build Android APK + build iOS on every push/PR |
| PR template | Standardized pull request format |
| Backend documentation | Comprehensive `docs/BACKEND.md` with full SQL, RLS policies, API operations |
| Roadmap | `docs/ROADMAP.md` with completed phases and future plans |
| Progress tracking | `docs/PROGRESS.md` with iteration log and file inventory |

---

## Technical Architecture

| Component | Technology |
|-----------|-----------|
| Framework | Flutter 3.10+ / Dart |
| Backend | Supabase (PostgreSQL, Auth, Storage) |
| State management | Provider (ChangeNotifier pattern) |
| Navigation | GoRouter with auth guards and shell routes |
| Theming | Material Design 3, Google Fonts (Outfit), light + dark |
| Charts | fl_chart |
| Calendar | table_calendar |
| QR codes | pretty_qr_code |
| Location | geolocator + Google Places API |
| Notifications | flutter_local_notifications + timezone |
| Connectivity | connectivity_plus |
| Sharing | share_plus |
| Image handling | image_picker + image_cropper + cached_network_image |
| Environment | flutter_dotenv |
| CI/CD | GitHub Actions |
