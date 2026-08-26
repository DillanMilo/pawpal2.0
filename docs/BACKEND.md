# PawPal Backend Documentation

> Single source of truth for all backend architecture, database schema, security, services, and integrations.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Database Schema (Complete SQL)](#2-database-schema-complete-sql)
3. [Row-Level Security (RLS) Policies](#3-row-level-security-rls-policies)
4. [Storage Buckets](#4-storage-buckets)
5. [Authentication](#5-authentication)
6. [Security Features](#6-security-features)
7. [API Operations by Service](#7-api-operations-by-service)
8. [Data Models](#8-data-models)
9. [Third-Party Integrations](#9-third-party-integrations)
10. [Caching Strategy](#10-caching-strategy)
11. [Environment Setup](#11-environment-setup)
12. [Backend Maintenance Notes](#12-backend-maintenance-notes)

---

## 1. Architecture Overview

PawPal uses **Supabase** as its Backend-as-a-Service (BaaS). There is no custom server -- all backend logic runs via the Supabase platform combined with client-side service classes in Flutter.

### Technology Stack

| Layer | Technology |
|-------|-----------|
| Client | Flutter (Dart) |
| BaaS | Supabase (hosted PostgreSQL, Auth, Storage, Realtime) |
| Auth | Supabase Auth (email/password, Google OAuth, Apple OAuth) |
| Database | PostgreSQL (via Supabase) |
| File Storage | Supabase Storage (S3-compatible) |
| Places API | Google Places API (REST, via `http` package) |
| Notifications | `flutter_local_notifications` (device-local scheduling) |
| Connectivity | `connectivity_plus` |

### Data Flow

```
Flutter App
    |
    v
Service Layer (lib/services/)
    |  - AuthService, PetService, MedicalService, etc.
    |  - Each service holds a reference to SupabaseService.client
    v
Supabase Flutter SDK (supabase_flutter)
    |  - Handles auth tokens, REST calls, realtime subscriptions
    v
Supabase Platform
    |  - Auth (JWT tokens, OAuth providers)
    |  - PostgREST (auto-generated REST API from schema)
    |  - Storage (file uploads/downloads)
    v
PostgreSQL Database
    |  - Tables with RLS policies
    |  - Trigger: handle_new_user()
```

### Key Design Decisions

- **No custom server**: All data access goes through Supabase's auto-generated REST API (PostgREST). Security is enforced entirely via Row-Level Security (RLS) policies in PostgreSQL.
- **Service layer pattern**: Each domain (pets, medical, activities, etc.) has a dedicated service class that encapsulates all Supabase calls.
- **Client-side UUID generation**: UUIDs are generated client-side using the `uuid` package before inserting records.
- **Environment variables**: All secrets (Supabase URL, anon key, Google API key) are loaded from a `.env` file via `flutter_dotenv`.

---

## 2. Database Schema (Complete SQL)

The full schema lives in `supabase/migrations/001_initial_schema.sql`. Below is the complete SQL with annotations.

### Full Migration SQL

```sql
-- PawPal Database Schema
-- Version: 1.0.0

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- TABLES
-- ============================================================

-- Users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    name TEXT,
    photo_url TEXT,
    phone_number TEXT,
    zip_code TEXT,
    notifications_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Pets table
CREATE TABLE IF NOT EXISTS public.pets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    species TEXT NOT NULL,
    breed TEXT,
    date_of_birth DATE,
    gender TEXT NOT NULL,
    photo_url TEXT,
    weight DECIMAL(5,2),
    color_markings TEXT,
    microchip_number TEXT,
    spayed_neutered BOOLEAN DEFAULT false,
    adoption_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Medical records table
CREATE TABLE IF NOT EXISTS public.medical_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pet_id UUID NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    date DATE NOT NULL,
    end_date DATE,
    next_due_date DATE,
    provider TEXT,
    dosage TEXT,
    frequency TEXT,
    document_url TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Activities table
CREATE TABLE IF NOT EXISTS public.activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pet_id UUID NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    duration_minutes INTEGER,
    distance DECIMAL(5,2),
    notes TEXT,
    photo_urls TEXT[],
    points INTEGER DEFAULT 0,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Appointments table
CREATE TABLE IF NOT EXISTS public.appointments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    pet_id UUID REFERENCES public.pets(id) ON DELETE SET NULL,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    date_time TIMESTAMP WITH TIME ZONE NOT NULL,
    provider TEXT,
    provider_address TEXT,
    notes TEXT,
    reminder_minutes_before INTEGER,
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Reminders table
CREATE TABLE IF NOT EXISTS public.reminders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    pet_id UUID REFERENCES public.pets(id) ON DELETE SET NULL,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    due_date TIMESTAMP WITH TIME ZONE NOT NULL,
    is_completed BOOLEAN DEFAULT false,
    is_recurring BOOLEAN DEFAULT false,
    recurring_pattern TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Achievements table
CREATE TABLE IF NOT EXISTS public.achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    badge_id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    icon_name TEXT NOT NULL,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, badge_id)
);

-- Favorite providers table
CREATE TABLE IF NOT EXISTS public.favorite_providers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    place_id TEXT,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    address TEXT NOT NULL,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    phone_number TEXT,
    website TEXT,
    rating DECIMAL(2,1),
    review_count INTEGER,
    photo_url TEXT,
    opening_hours JSONB,
    services TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_pets_user_id ON public.pets(user_id);
CREATE INDEX IF NOT EXISTS idx_medical_records_pet_id ON public.medical_records(pet_id);
CREATE INDEX IF NOT EXISTS idx_activities_pet_id ON public.activities(pet_id);
CREATE INDEX IF NOT EXISTS idx_activities_user_id ON public.activities(user_id);
CREATE INDEX IF NOT EXISTS idx_activities_start_time ON public.activities(start_time);
CREATE INDEX IF NOT EXISTS idx_appointments_user_id ON public.appointments(user_id);
CREATE INDEX IF NOT EXISTS idx_appointments_date_time ON public.appointments(date_time);
CREATE INDEX IF NOT EXISTS idx_reminders_user_id ON public.reminders(user_id);
CREATE INDEX IF NOT EXISTS idx_reminders_due_date ON public.reminders(due_date);
CREATE INDEX IF NOT EXISTS idx_achievements_user_id ON public.achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_favorite_providers_user_id ON public.favorite_providers(user_id);
```

### Table Reference

#### `public.users`
Extends Supabase `auth.users`. Created automatically by the `handle_new_user()` trigger on signup.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PK, FK -> auth.users(id) ON DELETE CASCADE | Matches the Supabase auth user ID |
| `email` | TEXT | NOT NULL | User's email address |
| `name` | TEXT | nullable | Display name |
| `photo_url` | TEXT | nullable | URL to profile photo in storage |
| `phone_number` | TEXT | nullable | Phone number |
| `zip_code` | TEXT | nullable | Used for location-based service search |
| `notifications_enabled` | BOOLEAN | DEFAULT true | Master notification toggle |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Row creation time |
| `updated_at` | TIMESTAMPTZ | DEFAULT NOW() | Last update time |

#### `public.pets`
Core entity -- each pet belongs to one user.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PK, DEFAULT uuid_generate_v4() | Auto-generated pet ID |
| `user_id` | UUID | NOT NULL, FK -> users(id) ON DELETE CASCADE | Owner |
| `name` | TEXT | NOT NULL | Pet name |
| `species` | TEXT | NOT NULL | Dog, Cat, Bird, Fish, Rabbit, Hamster, Guinea Pig, Reptile, Other |
| `breed` | TEXT | nullable | Breed name |
| `date_of_birth` | DATE | nullable | Birthday |
| `gender` | TEXT | NOT NULL | Gender |
| `photo_url` | TEXT | nullable | URL to pet photo in storage |
| `weight` | DECIMAL(5,2) | nullable | Weight (max 999.99) |
| `color_markings` | TEXT | nullable | Color/marking description |
| `microchip_number` | TEXT | nullable | Microchip ID |
| `spayed_neutered` | BOOLEAN | DEFAULT false | Spay/neuter status |
| `adoption_date` | DATE | nullable | Date pet was adopted |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Row creation time |
| `updated_at` | TIMESTAMPTZ | DEFAULT NOW() | Last update time |

#### `public.medical_records`
Medical history entries linked to a pet. Supports multiple record types.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PK, DEFAULT uuid_generate_v4() | Record ID |
| `pet_id` | UUID | NOT NULL, FK -> pets(id) ON DELETE CASCADE | Parent pet |
| `type` | TEXT | NOT NULL | One of: medication, vaccination, allergy, condition, vetVisit, groomingVisit, surgery, labResult |
| `title` | TEXT | NOT NULL | Record title |
| `description` | TEXT | nullable | Detailed description |
| `date` | DATE | NOT NULL | Date of record |
| `end_date` | DATE | nullable | End date (for medications) |
| `next_due_date` | DATE | nullable | Next due date (for vaccinations) |
| `provider` | TEXT | nullable | Vet/provider name |
| `dosage` | TEXT | nullable | Medication dosage |
| `frequency` | TEXT | nullable | Medication frequency |
| `document_url` | TEXT | nullable | URL to uploaded document |
| `metadata` | JSONB | nullable | Flexible extra data |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Row creation time |
| `updated_at` | TIMESTAMPTZ | DEFAULT NOW() | Last update time |

#### `public.activities`
Activity log entries. Each activity earns points toward badges.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PK, DEFAULT uuid_generate_v4() | Activity ID |
| `pet_id` | UUID | NOT NULL, FK -> pets(id) ON DELETE CASCADE | Associated pet |
| `user_id` | UUID | NOT NULL, FK -> users(id) ON DELETE CASCADE | Logging user |
| `type` | TEXT | NOT NULL | Walk, Play, Train, Feed, Groom, Vet Visit, Social, Rest |
| `start_time` | TIMESTAMPTZ | NOT NULL | When activity started |
| `end_time` | TIMESTAMPTZ | nullable | When activity ended |
| `duration_minutes` | INTEGER | nullable | Duration in minutes |
| `distance` | DECIMAL(5,2) | nullable | Distance (for walks) |
| `notes` | TEXT | nullable | Free-text notes |
| `photo_urls` | TEXT[] | nullable | Array of photo URLs |
| `points` | INTEGER | DEFAULT 0 | Points earned |
| `metadata` | JSONB | nullable | Flexible extra data |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Row creation time |

**Points by activity type:**

| Type | Points |
|------|--------|
| Walk | 10 |
| Play | 8 |
| Train | 15 |
| Feed | 5 |
| Groom | 7 |
| Vet Visit | 20 |
| Social | 12 |
| Rest | 3 |

#### `public.appointments`
Scheduled appointments. Can optionally be linked to a pet.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PK, DEFAULT uuid_generate_v4() | Appointment ID |
| `user_id` | UUID | NOT NULL, FK -> users(id) ON DELETE CASCADE | Owner |
| `pet_id` | UUID | FK -> pets(id) ON DELETE SET NULL | Optional pet link (SET NULL on pet deletion) |
| `type` | TEXT | NOT NULL | Vet, Grooming, Training, Other |
| `title` | TEXT | NOT NULL | Appointment title |
| `date_time` | TIMESTAMPTZ | NOT NULL | Scheduled date/time |
| `provider` | TEXT | nullable | Provider name |
| `provider_address` | TEXT | nullable | Provider address |
| `notes` | TEXT | nullable | Notes |
| `reminder_minutes_before` | INTEGER | nullable | How many minutes before to remind |
| `is_completed` | BOOLEAN | DEFAULT false | Completion status |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Row creation time |
| `updated_at` | TIMESTAMPTZ | DEFAULT NOW() | Last update time |

#### `public.reminders`
Reminders with optional recurrence. Can optionally be linked to a pet.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PK, DEFAULT uuid_generate_v4() | Reminder ID |
| `user_id` | UUID | NOT NULL, FK -> users(id) ON DELETE CASCADE | Owner |
| `pet_id` | UUID | FK -> pets(id) ON DELETE SET NULL | Optional pet link |
| `type` | TEXT | NOT NULL | Medication, Vaccination, Appointment, Grooming, Custom |
| `title` | TEXT | NOT NULL | Reminder title |
| `description` | TEXT | nullable | Description |
| `due_date` | TIMESTAMPTZ | NOT NULL | When the reminder is due |
| `is_completed` | BOOLEAN | DEFAULT false | Completion status |
| `is_recurring` | BOOLEAN | DEFAULT false | Whether this repeats |
| `recurring_pattern` | TEXT | nullable | daily, weekly, or monthly |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Row creation time |
| `updated_at` | TIMESTAMPTZ | DEFAULT NOW() | Last update time |

#### `public.achievements`
Unlocked badges/achievements per user. Each (user_id, badge_id) pair is unique.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PK, DEFAULT uuid_generate_v4() | Achievement ID |
| `user_id` | UUID | NOT NULL, FK -> users(id) ON DELETE CASCADE | Owner |
| `badge_id` | TEXT | NOT NULL, UNIQUE(user_id, badge_id) | Badge identifier |
| `name` | TEXT | NOT NULL | Display name |
| `description` | TEXT | NOT NULL | What was achieved |
| `icon_name` | TEXT | NOT NULL | Material icon name |
| `unlocked_at` | TIMESTAMPTZ | DEFAULT NOW() | When unlocked |

**Available badges:**

| badge_id | Name | Requirement | Threshold |
|----------|------|-------------|-----------|
| `first_walk` | First Walk | Complete 1 walk | 1 |
| `week_warrior` | Week Warrior | 7-day activity streak | 7 |
| `training_pro` | Training Pro | 10 training sessions | 10 |
| `social_butterfly` | Social Butterfly | 5 socialization events | 5 |
| `health_champion` | Health Champion | All vaccinations up to date | 1 |
| `consistent_caregiver` | Consistent Caregiver | 30-day streak | 30 |

#### `public.favorite_providers`
User-saved favorite service providers (vets, groomers, pet stores).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PK, DEFAULT uuid_generate_v4() | Record ID |
| `user_id` | UUID | NOT NULL, FK -> users(id) ON DELETE CASCADE | Owner |
| `place_id` | TEXT | nullable | Google Places ID |
| `name` | TEXT | NOT NULL | Provider name |
| `type` | TEXT | NOT NULL | vet, groomer, pet_store |
| `address` | TEXT | NOT NULL | Full address |
| `latitude` | DECIMAL(10,8) | nullable | Lat coordinate |
| `longitude` | DECIMAL(11,8) | nullable | Lng coordinate |
| `phone_number` | TEXT | nullable | Phone |
| `website` | TEXT | nullable | Website URL |
| `rating` | DECIMAL(2,1) | nullable | Rating (0.0-9.9) |
| `review_count` | INTEGER | nullable | Number of reviews |
| `photo_url` | TEXT | nullable | Photo URL |
| `opening_hours` | JSONB | nullable | Structured opening hours |
| `services` | TEXT[] | nullable | Array of service names |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Row creation time |

### Indexes

| Index Name | Table | Column(s) | Purpose |
|-----------|-------|-----------|---------|
| `idx_pets_user_id` | pets | user_id | Fast pet lookup by owner |
| `idx_medical_records_pet_id` | medical_records | pet_id | Fast medical record lookup by pet |
| `idx_activities_pet_id` | activities | pet_id | Fast activity lookup by pet |
| `idx_activities_user_id` | activities | user_id | Fast activity lookup by user |
| `idx_activities_start_time` | activities | start_time | Date-range activity queries |
| `idx_appointments_user_id` | appointments | user_id | Fast appointment lookup by user |
| `idx_appointments_date_time` | appointments | date_time | Date-range appointment queries |
| `idx_reminders_user_id` | reminders | user_id | Fast reminder lookup by user |
| `idx_reminders_due_date` | reminders | due_date | Due-date range queries |
| `idx_achievements_user_id` | achievements | user_id | Fast achievement lookup by user |
| `idx_favorite_providers_user_id` | favorite_providers | user_id | Fast provider lookup by user |

### Trigger Function: `handle_new_user()`

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1))
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

**How it works:**
1. When a new row is inserted into `auth.users` (i.e., a user signs up), the trigger fires.
2. The function inserts a corresponding row into `public.users`.
3. The `name` field is populated from `raw_user_meta_data->>'name'` (set during signup). If not present, it falls back to the portion of the email before `@`.
4. The function runs as `SECURITY DEFINER`, meaning it executes with the privileges of the function owner (bypassing RLS), which is necessary because the newly created user doesn't yet have a session.

---

## 3. Row-Level Security (RLS) Policies

RLS is enabled on **all 8 tables**. Every policy uses `auth.uid()` to identify the current user from their JWT token.

### `public.users`

| Policy Name | Operation | Rule |
|-------------|-----------|------|
| Users can view own profile | SELECT | `auth.uid() = id` |
| Users can update own profile | UPDATE | `auth.uid() = id` |
| Users can insert own profile | INSERT | `auth.uid() = id` (WITH CHECK) |

Users can only read, update, and insert their own profile row. There is no DELETE policy -- account deletion is handled via the service layer which deletes the user row directly.

### `public.pets`

| Policy Name | Operation | Rule |
|-------------|-----------|------|
| Users can view own pets | SELECT | `auth.uid() = user_id` |
| Users can insert own pets | INSERT | `auth.uid() = user_id` (WITH CHECK) |
| Users can update own pets | UPDATE | `auth.uid() = user_id` |
| Users can delete own pets | DELETE | `auth.uid() = user_id` |

Full CRUD restricted to the pet's owner.

### `public.medical_records`

| Policy Name | Operation | Rule |
|-------------|-----------|------|
| Users can view own pets medical records | SELECT | `EXISTS (SELECT 1 FROM pets WHERE pets.id = medical_records.pet_id AND pets.user_id = auth.uid())` |
| Users can insert medical records for own pets | INSERT | Same subquery (WITH CHECK) |
| Users can update medical records for own pets | UPDATE | Same subquery |
| Users can delete medical records for own pets | DELETE | Same subquery |

Medical records do not have a direct `user_id` column. Access is controlled by joining through the `pets` table -- you can only access medical records for pets you own.

### `public.activities`

| Policy Name | Operation | Rule |
|-------------|-----------|------|
| Users can view own activities | SELECT | `auth.uid() = user_id` |
| Users can insert own activities | INSERT | `auth.uid() = user_id` (WITH CHECK) |
| Users can update own activities | UPDATE | `auth.uid() = user_id` |
| Users can delete own activities | DELETE | `auth.uid() = user_id` |

### `public.appointments`

| Policy Name | Operation | Rule |
|-------------|-----------|------|
| Users can view own appointments | SELECT | `auth.uid() = user_id` |
| Users can insert own appointments | INSERT | `auth.uid() = user_id` (WITH CHECK) |
| Users can update own appointments | UPDATE | `auth.uid() = user_id` |
| Users can delete own appointments | DELETE | `auth.uid() = user_id` |

### `public.reminders`

| Policy Name | Operation | Rule |
|-------------|-----------|------|
| Users can view own reminders | SELECT | `auth.uid() = user_id` |
| Users can insert own reminders | INSERT | `auth.uid() = user_id` (WITH CHECK) |
| Users can update own reminders | UPDATE | `auth.uid() = user_id` |
| Users can delete own reminders | DELETE | `auth.uid() = user_id` |

### `public.achievements`

| Policy Name | Operation | Rule |
|-------------|-----------|------|
| Users can view own achievements | SELECT | `auth.uid() = user_id` |
| Users can insert own achievements | INSERT | `auth.uid() = user_id` (WITH CHECK) |

Achievements are insert-only from the client side (no update or delete policies). Once earned, they persist.

### `public.favorite_providers`

| Policy Name | Operation | Rule |
|-------------|-----------|------|
| Users can view own favorite providers | SELECT | `auth.uid() = user_id` |
| Users can insert own favorite providers | INSERT | `auth.uid() = user_id` (WITH CHECK) |
| Users can update own favorite providers | UPDATE | `auth.uid() = user_id` |
| Users can delete own favorite providers | DELETE | `auth.uid() = user_id` |

---

## 4. Storage Buckets

Four Supabase Storage buckets are used, defined as constants in `lib/utils/constants.dart`:

| Bucket Name | Constant | Purpose | Path Pattern |
|-------------|----------|---------|-------------|
| `profile-photos` | `AppConstants.profilePhotosBucket` | User avatar/profile images | `{userId}/{uuid}.{ext}` |
| `pet-photos` | `AppConstants.petPhotosBucket` | Pet profile pictures | `{petId}/{uuid}.{ext}` |
| `medical-documents` | `AppConstants.medicalDocsBucket` | Uploaded medical documents (PDFs, images) | `{petId}/{uuid}.{ext}` |
| `activity-photos` | `AppConstants.activityPhotosBucket` | Photos attached to activity logs | Not yet implemented in service layer |

### Access Patterns

- **Upload**: Files are uploaded via `SupabaseClient.storage.from(bucket).upload(path, file)`.
- **Public URLs**: After upload, a public URL is obtained via `.getPublicUrl(path)` and stored in the relevant table row (`photo_url`, `document_url`).
- **Deletion**: When a pet or medical record is deleted, the service layer extracts the file path from the URL and calls `.remove([path])` to clean up storage. Deletion errors are silently caught to avoid blocking the primary operation.

### File Naming Convention

All uploaded files use UUID-based filenames to prevent collisions:
```
{parentId}/{uuid_v4}.{original_extension}
```

---

## 5. Authentication

Authentication is handled by Supabase Auth, accessed through `AuthService` (`lib/services/auth_service.dart`).

### Email/Password Signup

```dart
final response = await _client.auth.signUp(
  email: email,
  password: password,
  data: {'name': name},  // stored in raw_user_meta_data
);
```

After signup, the `handle_new_user()` trigger automatically creates a `public.users` row. The `AuthService` also calls `_createUserProfile()` as a fallback to ensure the profile row exists.

### Email/Password Sign In

```dart
final response = await _client.auth.signInWithPassword(
  email: email,
  password: password,
);
```

### Google OAuth

```dart
final response = await _client.auth.signInWithOAuth(
  OAuthProvider.google,
  redirectTo: kIsWeb
      ? 'https://your-production-domain.com/auth/callback'
      : 'com.creativecurrents.pawpal://login-callback/',
);
```

- **Native redirect URI**: `com.creativecurrents.pawpal://login-callback/`
- **Web redirect path**: `/auth/callback`
- Opens a browser/webview for the Google consent flow.
- On success, Supabase creates the `auth.users` row and the trigger creates the `public.users` profile.

### Apple OAuth

```dart
final response = await _client.auth.signInWithOAuth(
  OAuthProvider.apple,
  redirectTo: kIsWeb
      ? 'https://your-production-domain.com/auth/callback'
      : 'com.creativecurrents.pawpal://login-callback/',
);
```

- Same redirect URI pattern as Google.
- Requires Apple Sign In entitlement configured in Xcode.

### Password Reset

```dart
await _client.auth.resetPasswordForEmail(email);
```

Sends a password reset email via Supabase Auth. The user clicks the link, which redirects back to the app.

### Password Update

```dart
await _client.auth.updateUser(UserAttributes(password: newPassword));
```

Used after the user is authenticated (e.g., from a "change password" screen).

### Session Management

- Supabase Flutter SDK manages JWT tokens automatically, including refresh.
- Session state is observed via `SupabaseService.authStateChanges` (a stream of `AuthState`).
- Current user is available synchronously via `SupabaseService.currentUser` and `SupabaseService.currentUserId`.
- `SupabaseService.isAuthenticated` provides a quick boolean check.

### Account Deletion

```dart
// Deletes user profile row (cascades to all owned data), then signs out
await _client.from('users').delete().eq('id', userId);
await signOut();
```

Due to `ON DELETE CASCADE` on all foreign keys referencing `users(id)`, deleting the user profile row cascades and removes all pets, activities, appointments, reminders, achievements, and favorite providers.

---

## 6. Security Features

### Environment Variable Management

- All secrets are stored in a `.env` file at the project root.
- `.env` is listed in `.gitignore` to prevent accidental commits.
- An `.env.example` file documents the required variables without real values.
- The `flutter_dotenv` package loads `.env` at app startup.
- Access via `dotenv.env['KEY_NAME']` with fallback to empty string if missing.

**Required variables:**
```
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
GOOGLE_PLACES_API_KEY=your_google_places_api_key
```

### Row-Level Security Model

Every table has RLS enabled. The security model follows a strict "users can only access their own data" pattern:

- **Direct ownership**: Most tables have a `user_id` column checked against `auth.uid()`.
- **Indirect ownership**: `medical_records` uses a subquery through `pets` to verify ownership.
- **No public/shared data**: There are no policies that allow cross-user access.
- **Write protection**: INSERT uses `WITH CHECK` to prevent users from creating data under another user's ID.

### API Key Security

| Key | Exposure | Purpose |
|-----|----------|---------|
| **Supabase Anon Key** | Embedded in client app (expected) | Used for all client-side requests. Safe to expose because RLS enforces access control. This key only allows operations the RLS policies permit for the authenticated user. |
| **Supabase Service Key** | Never exposed in client | Server-side only. Bypasses RLS. Not used in this app since there is no custom server. |
| **Google Places API Key** | Embedded in client app | Restricted via Google Cloud Console (API restrictions, app restrictions). |

### Input Validation

- All forms use Flutter's `Form` widget with `_formKey.currentState!.validate()` to enforce client-side validation before submission.
- Validation is applied on signup, login, pet creation, pet editing, medical records, vet visits, medications, and password reset screens.

### Data Isolation

- Users cannot query, update, or delete data belonging to other users.
- RLS policies are the primary enforcement mechanism; even if client-side code had a bug, the database would reject unauthorized access.
- Cascade deletions ensure that when a user or pet is deleted, all dependent data is cleaned up.

### OAuth Security

- OAuth redirect URI (`com.creativecurrents.pawpal://login-callback/`) uses a custom URL scheme tied to the app.
- Token exchange is handled by the Supabase SDK -- tokens are stored securely on-device.
- OAuth providers (Google, Apple) must be configured in the Supabase dashboard with matching client IDs and secrets.

### Storage Bucket Security

- Storage buckets should have their own RLS-style policies configured in the Supabase dashboard.
- File paths are namespaced by user/pet ID to prevent path collisions.
- Public URLs are used for serving images (no auth required for reading -- configure bucket policies accordingly).

### Known Security Considerations Going Forward

- **Rate limiting**: Not currently implemented. Supabase provides some built-in rate limiting, but custom rate limiting (e.g., for auth attempts) should be considered.
- **Encryption at rest**: Supabase encrypts data at rest by default on their managed platform.
- **Audit logging**: Not currently implemented. Consider adding a database audit trail for sensitive operations (account deletion, medical record changes).
- **Input sanitization**: While RLS prevents unauthorized access, adding server-side input sanitization (via Supabase Edge Functions) could provide defense in depth.
- **API key restrictions**: The Google Places API key should be restricted by platform (iOS bundle ID, Android package name) in the Google Cloud Console.

---

## 7. API Operations by Service

### SupabaseService (`lib/services/supabase_service.dart`)

Singleton accessor for the Supabase client. Not a CRUD service -- it provides infrastructure.

| Method/Property | Description |
|----------------|-------------|
| `initialize()` | Initializes Supabase with URL and anon key from constants |
| `client` | Static getter for the `SupabaseClient` instance |
| `currentUser` | Currently authenticated `User` or null |
| `currentUserId` | Current user's UUID string or null |
| `isAuthenticated` | Quick boolean check |
| `authStateChanges` | Stream of `AuthState` for reactive auth state |

### AuthService (`lib/services/auth_service.dart`)

**Table**: `users`

| Method | Operation | Query Pattern |
|--------|-----------|--------------|
| `signUp(email, password, name)` | Auth signup + INSERT | `_client.auth.signUp(...)` then `_client.from('users').insert(...)` |
| `signIn(email, password)` | Auth login | `_client.auth.signInWithPassword(...)` |
| `signInWithGoogle()` | OAuth | `_client.auth.signInWithOAuth(OAuthProvider.google, ...)` |
| `signInWithApple()` | OAuth | `_client.auth.signInWithOAuth(OAuthProvider.apple, ...)` |
| `signOut()` | Auth logout | `_client.auth.signOut()` |
| `resetPassword(email)` | Password reset | `_client.auth.resetPasswordForEmail(email)` |
| `updatePassword(newPassword)` | Password update | `_client.auth.updateUser(UserAttributes(password: ...))` |
| `getCurrentUserProfile()` | SELECT | `.from('users').select().eq('id', userId).maybeSingle()` |
| `updateUserProfile(profile)` | UPDATE | `.from('users').update(data).eq('id', profile.id).select().single()` |
| `deleteAccount()` | DELETE + signOut | `.from('users').delete().eq('id', userId)` (cascades all data) |

**Error handling**: Exceptions propagate to the caller (UI/provider layer). The UI displays error messages via snackbars or dialogs.

### PetService (`lib/services/pet_service.dart`)

**Table**: `pets` | **Storage**: `pet-photos` bucket

| Method | Operation | Query Pattern |
|--------|-----------|--------------|
| `getPets()` | SELECT all | `.from('pets').select().eq('user_id', userId).order('created_at', ascending: false)` |
| `getPet(petId)` | SELECT one | `.from('pets').select().eq('id', petId).maybeSingle()` |
| `createPet(pet)` | INSERT | `.from('pets').insert(data).select().single()` |
| `updatePet(pet)` | UPDATE | `.from('pets').update(data).eq('id', pet.id).select().single()` |
| `deletePet(petId)` | DELETE | Deletes photo from storage, then `.from('pets').delete().eq('id', petId)` |
| `uploadPhoto(petId, file)` | Storage upload | `.storage.from('pet-photos').upload(path, file)` |
| `getPetCount()` | SELECT count | `.from('pets').select('id').eq('user_id', userId)` then `.length` |

### MedicalService (`lib/services/medical_service.dart`)

**Table**: `medical_records` | **Storage**: `medical-documents` bucket

| Method | Operation | Query Pattern |
|--------|-----------|--------------|
| `getMedicalRecords(petId)` | SELECT all for pet | `.eq('pet_id', petId).order('date', ascending: false)` |
| `getMedicalRecordsByType(petId, type)` | SELECT filtered | `.eq('pet_id', petId).eq('type', type.name)` |
| `getActiveMedications(petId)` | SELECT active meds | `.eq('type', 'medication').or('end_date.is.null,end_date.gt.$now')` |
| `getUpcomingVaccinations(petId)` | SELECT upcoming vaxx | `.eq('type', 'vaccination').not('next_due_date', 'is', null)` |
| `getAllergies(petId)` | SELECT allergies | `.eq('type', 'allergy')` |
| `createMedicalRecord(record)` | INSERT | `.insert(data).select().single()` |
| `updateMedicalRecord(record)` | UPDATE | `.update(data).eq('id', record.id).select().single()` |
| `deleteMedicalRecord(recordId)` | DELETE | Deletes document from storage, then `.delete().eq('id', recordId)` |
| `uploadDocument(petId, file)` | Storage upload | `.storage.from('medical-documents').upload(path, file)` |
| `areVaccinationsUpToDate(petId)` | Business logic | Fetches upcoming vaccinations, checks if any `nextDueDate` is in the past |

### ActivityService (`lib/services/activity_service.dart`)

**Table**: `activities`

| Method | Operation | Query Pattern |
|--------|-----------|--------------|
| `getActivities(petId, limit?)` | SELECT for pet | `.eq('pet_id', petId).order('start_time', ascending: false)` |
| `getActivitiesInRange(petId, start, end)` | SELECT date range | `.eq('pet_id', petId).gte('start_time', start).lte('start_time', end)` |
| `getPetActivities(petId, limit?)` | Alias | Calls `getActivities()` |
| `getUserActivities(limit?)` | Alias | Calls `getAllUserActivities()` |
| `getAllUserActivities(limit?)` | SELECT all user | `.eq('user_id', userId).order('start_time', ascending: false)` |
| `getTodayActivities(petId)` | SELECT today | Uses `getActivitiesInRange()` with start/end of today |
| `logActivity(activity)` | INSERT | Calculates points, `.insert(data).select().single()` |
| `updateActivity(activity)` | UPDATE | `.update(data).eq('id', activity.id).select().single()` |
| `deleteActivity(activityId)` | DELETE | `.delete().eq('id', activityId)` |
| `getTotalPoints()` | Aggregate | Fetches all points for user, sums client-side |
| `getActivityCountsByType(petId)` | Aggregate | Fetches all types for pet, counts client-side |
| `getCurrentStreak()` | Business logic | Fetches last 365 days of activities, builds date set, walks backward counting consecutive days |
| `getWeeklySummary(petId)` | Aggregate | Fetches current week activities, groups points by day |

### AppointmentService (`lib/services/appointment_service.dart`)

**Table**: `appointments`

| Method | Operation | Query Pattern |
|--------|-----------|--------------|
| `getAppointments()` | SELECT all | `.eq('user_id', userId).order('date_time', ascending: true)` |
| `getPetAppointments(petId)` | SELECT for pet | `.eq('pet_id', petId).order('date_time', ascending: true)` |
| `getUpcomingAppointments(limit?)` | SELECT upcoming | `.eq('is_completed', false).gte('date_time', now)` |
| `getAppointmentsInRange(start, end)` | SELECT range | `.gte('date_time', start).lte('date_time', end)` |
| `getAppointmentsForDay(date)` | SELECT day | Uses `getAppointmentsInRange()` with start/end of day |
| `getTodayAppointments()` | SELECT today | Calls `getAppointmentsForDay(DateTime.now())` |
| `createAppointment(appointment)` | INSERT | `.insert(data).select().single()` |
| `updateAppointment(appointment)` | UPDATE | `.update(data).eq('id', appointment.id).select().single()` |
| `markAsCompleted(appointmentId)` | UPDATE | `.update({'is_completed': true, 'updated_at': now}).eq('id', id)` |
| `deleteAppointment(appointmentId)` | DELETE | `.delete().eq('id', appointmentId)` |
| `getMonthlyAppointmentCounts(year, month)` | Aggregate | Fetches range, groups by date client-side |

### ReminderService (`lib/services/reminder_service.dart`)

**Table**: `reminders`

| Method | Operation | Query Pattern |
|--------|-----------|--------------|
| `getReminders()` | SELECT all | `.eq('user_id', userId).order('due_date', ascending: true)` |
| `getPetReminders(petId)` | SELECT for pet | `.eq('pet_id', petId).order('due_date', ascending: true)` |
| `getActiveReminders()` | SELECT incomplete | `.eq('is_completed', false)` |
| `getUpcomingReminders()` | SELECT next 7 days | `.eq('is_completed', false).gte('due_date', now).lte('due_date', weekFromNow)` |
| `getOverdueReminders()` | SELECT overdue | `.eq('is_completed', false).lt('due_date', now)` |
| `getTodayReminders()` | SELECT today | `.gte('due_date', startOfDay).lt('due_date', endOfDay)` |
| `createReminder(reminder)` | INSERT | `.insert(data).select().single()` |
| `updateReminder(reminder)` | UPDATE | `.update(data).eq('id', reminder.id).select().single()` |
| `markAsCompleted(reminderId)` | UPDATE + recurse | Marks complete, then if recurring, auto-creates next reminder |
| `deleteReminder(reminderId)` | DELETE | `.delete().eq('id', reminderId)` |

**Recurring reminder logic**: When a recurring reminder is completed, `_createNextRecurringReminder()` calculates the next due date based on `recurring_pattern` (daily: +1 day, weekly: +7 days, monthly: +1 month) and creates a new reminder.

### NotificationService (`lib/services/notification_service.dart`)

**No database interaction.** This is a device-local notification service using `flutter_local_notifications`.

| Method | Description |
|--------|-------------|
| `initialize()` | Initializes the notification plugin with Android/iOS settings |
| `requestPermissions()` | Requests notification permissions from the OS |
| `showNotification(id, title, body, payload?)` | Shows an immediate notification |
| `scheduleNotification(id, title, body, scheduledDate, payload?)` | Schedules a future notification using `zonedSchedule` |
| `scheduleReminderNotification(reminder)` | Schedules two notifications: 1 hour before due and at due time |
| `cancelNotification(id)` | Cancels a single notification |
| `cancelReminderNotifications(reminderId)` | Cancels both notifications for a reminder |
| `cancelAllNotifications()` | Cancels all pending notifications |
| `getPendingNotifications()` | Lists all pending notification requests |
| `scheduleDailyActivityReminder(hour, minute)` | Recurring daily notification at specified time |
| `scheduleStreakReminder()` | One-time notification at 8 PM to maintain streak |

**Notification channels (Android):**

| Channel ID | Name | Purpose |
|------------|------|---------|
| `pawpal_general` | General Notifications | Immediate notifications |
| `pawpal_reminders` | Reminders | Scheduled reminder notifications |
| `pawpal_daily` | Daily Reminders | Daily activity prompts |
| `pawpal_streaks` | Streak Reminders | Streak maintenance alerts |

**Notification tap routing**: Payloads are mapped to app routes:
- `reminder:{id}` -> `/reminders`
- `daily_activity` -> `/log-activity`
- `streak_reminder` -> `/log-activity`
- `pet:{petId}` -> `/pet/{petId}`
- fallback -> `/home`

**Preference-gated scheduling**: Both `scheduleReminderNotification()` and `scheduleDailyActivityReminder()` check `SharedPreferences` before scheduling. A master toggle (`notifications_enabled`) and per-type toggles (`reminder_notifications`, `streak_notifications`) must be enabled.

### PlacesService (`lib/services/places_service.dart`)

**No database interaction.** Calls the Google Places API directly via HTTP.

| Method | Description |
|--------|-------------|
| `getCurrentLocation()` | Gets device GPS coordinates via `geolocator` |
| `searchNearbyPlaces(type, lat, lng, radius?)` | Nearby Search API call |
| `searchByZipcode(type, zipcode, radius?)` | Geocodes zipcode, then calls `searchNearbyPlaces` |
| `getPlaceDetails(placeId)` | Place Details API call |

---

## 8. Data Models

All models live in `lib/models/` and are re-exported via `lib/models/models.dart`.

### UserProfile

| Field | Dart Type | DB Column | Notes |
|-------|-----------|-----------|-------|
| `id` | `String` | `id` | UUID |
| `email` | `String` | `email` | Required |
| `name` | `String?` | `name` | |
| `photoUrl` | `String?` | `photo_url` | Storage URL |
| `phoneNumber` | `String?` | `phone_number` | |
| `zipCode` | `String?` | `zip_code` | |
| `notificationsEnabled` | `bool` | `notifications_enabled` | Default true |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |

Methods: `fromJson`, `toJson`, `copyWith`

### Pet

| Field | Dart Type | DB Column | Notes |
|-------|-----------|-----------|-------|
| `id` | `String` | `id` | UUID |
| `userId` | `String` | `user_id` | Owner FK |
| `name` | `String` | `name` | Required |
| `species` | `String` | `species` | Required |
| `breed` | `String?` | `breed` | |
| `dateOfBirth` | `DateTime?` | `date_of_birth` | |
| `gender` | `String` | `gender` | Required |
| `photoUrl` | `String?` | `photo_url` | Storage URL |
| `weight` | `double?` | `weight` | |
| `colorMarkings` | `String?` | `color_markings` | |
| `microchipNumber` | `String?` | `microchip_number` | |
| `spayedNeutered` | `bool` | `spayed_neutered` | Default false |
| `adoptionDate` | `DateTime?` | `adoption_date` | |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |

**Computed properties:**
- `ageInYears` -> `int?` -- calculates age from `dateOfBirth`
- `ageDisplay` -> `String` -- human-readable age string (e.g., "3 years" or "6 months")

Methods: `fromJson`, `toJson`, `copyWith`

### MedicalRecord

| Field | Dart Type | DB Column | Notes |
|-------|-----------|-----------|-------|
| `id` | `String` | `id` | UUID |
| `petId` | `String` | `pet_id` | Parent pet FK |
| `type` | `MedicalRecordType` | `type` | Enum: medication, vaccination, allergy, condition, vetVisit, groomingVisit, surgery, labResult |
| `title` | `String` | `title` | Required |
| `description` | `String?` | `description` | |
| `date` | `DateTime` | `date` | Required |
| `endDate` | `DateTime?` | `end_date` | For medications |
| `nextDueDate` | `DateTime?` | `next_due_date` | For vaccinations |
| `provider` | `String?` | `provider` | Vet/provider name |
| `dosage` | `String?` | `dosage` | |
| `frequency` | `String?` | `frequency` | |
| `documentUrl` | `String?` | `document_url` | Storage URL |
| `metadata` | `Map<String, dynamic>?` | `metadata` | JSONB |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |

**Computed properties:**
- `isActive` -> `bool` -- for medications, true if `endDate` is null or in the future
- `isDue` -> `bool` -- true if `nextDueDate` is in the past

Methods: `fromJson`, `toJson`, `copyWith`

### Activity

| Field | Dart Type | DB Column | Notes |
|-------|-----------|-----------|-------|
| `id` | `String` | `id` | UUID |
| `petId` | `String` | `pet_id` | FK |
| `userId` | `String` | `user_id` | FK |
| `type` | `String` | `type` | Walk, Play, Train, Feed, Groom, Vet Visit, Social, Rest |
| `startTime` | `DateTime` | `start_time` | Required |
| `endTime` | `DateTime?` | `end_time` | |
| `durationMinutes` | `int?` | `duration_minutes` | |
| `distance` | `double?` | `distance` | |
| `notes` | `String?` | `notes` | |
| `photoUrls` | `List<String>?` | `photo_urls` | TEXT[] |
| `points` | `int` | `points` | Calculated at insert time |
| `metadata` | `Map<String, dynamic>?` | `metadata` | JSONB |
| `createdAt` | `DateTime` | `created_at` | |

**Computed properties:**
- `calculatedDuration` -> `int` -- returns `durationMinutes` if set, otherwise calculates from `startTime`/`endTime`

Methods: `fromJson`, `toJson`, `copyWith`

### Appointment

| Field | Dart Type | DB Column | Notes |
|-------|-----------|-----------|-------|
| `id` | `String` | `id` | UUID |
| `userId` | `String` | `user_id` | FK |
| `petId` | `String?` | `pet_id` | Optional FK |
| `type` | `String` | `type` | Vet, Grooming, Training, Other |
| `title` | `String` | `title` | Required |
| `dateTime` | `DateTime` | `date_time` | Required |
| `provider` | `String?` | `provider` | |
| `providerAddress` | `String?` | `provider_address` | |
| `notes` | `String?` | `notes` | |
| `reminderMinutesBefore` | `int?` | `reminder_minutes_before` | |
| `isCompleted` | `bool` | `is_completed` | Default false |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |

**Computed properties:**
- `isPast` -> `bool` -- true if `dateTime` is before now
- `isToday` -> `bool` -- true if `dateTime` is today
- `isUpcoming` -> `bool` -- true if not past and not today

Methods: `fromJson`, `toJson`, `copyWith`

### Reminder

| Field | Dart Type | DB Column | Notes |
|-------|-----------|-----------|-------|
| `id` | `String` | `id` | UUID |
| `userId` | `String` | `user_id` | FK |
| `petId` | `String?` | `pet_id` | Optional FK |
| `type` | `String` | `type` | Medication, Vaccination, Appointment, Grooming, Custom |
| `title` | `String` | `title` | Required |
| `description` | `String?` | `description` | |
| `dueDate` | `DateTime` | `due_date` | Required |
| `isCompleted` | `bool` | `is_completed` | Default false |
| `isRecurring` | `bool` | `is_recurring` | Default false |
| `recurringPattern` | `String?` | `recurring_pattern` | daily, weekly, monthly |
| `createdAt` | `DateTime` | `created_at` | |
| `updatedAt` | `DateTime` | `updated_at` | |

**Computed properties:**
- `isDue` -> `bool` -- true if `dueDate` is past and not completed
- `isDueToday` -> `bool` -- true if `dueDate` is today and not completed
- `isUpcoming` -> `bool` -- true if within next 7 days and not completed

Methods: `fromJson`, `toJson`, `copyWith`

### Achievement

| Field | Dart Type | DB Column | Notes |
|-------|-----------|-----------|-------|
| `id` | `String` | `id` | UUID |
| `userId` | `String` | `user_id` | FK |
| `badgeId` | `String` | `badge_id` | Unique per user |
| `name` | `String` | `name` | Display name |
| `description` | `String` | `description` | |
| `iconName` | `String` | `icon_name` | Material icon name |
| `unlockedAt` | `DateTime` | `unlocked_at` | |

Methods: `fromJson`, `toJson`

### Badge (client-side only, not stored in DB)

Defines the full catalog of available badges. See `Badge.allBadges` static list in `lib/models/achievement.dart`.

### ServiceProvider

| Field | Dart Type | DB Column | Notes |
|-------|-----------|-----------|-------|
| `id` | `String` | `id` | UUID |
| `placeId` | `String?` | `place_id` | Google Places ID |
| `name` | `String` | `name` | Required |
| `type` | `String` | `type` | vet, groomer, pet_store |
| `address` | `String` | `address` | Required |
| `latitude` | `double?` | `latitude` | |
| `longitude` | `double?` | `longitude` | |
| `phoneNumber` | `String?` | `phone_number` | |
| `website` | `String?` | `website` | |
| `rating` | `double?` | `rating` | |
| `reviewCount` | `int?` | `review_count` | |
| `photoUrl` | `String?` | `photo_url` | |
| `openingHours` | `Map<String, String>?` | `opening_hours` | JSONB |
| `services` | `List<String>?` | `services` | TEXT[] |
| `isFavorite` | `bool` | -- | Client-side flag, not in DB |
| `distance` | `double?` | -- | Calculated client-side, not stored |
| `createdAt` | `DateTime?` | `created_at` | |

**Computed properties:**
- `isOpen` -> `bool` -- checks current day's opening hours
- `distanceDisplay` -> `String` -- formats distance as "X m" or "X.X km"

Methods: `fromJson`, `toJson`, `copyWith`

---

## 9. Third-Party Integrations

### Google Places API

**Base URL**: `https://maps.googleapis.com/maps/api/place`

| Endpoint | Method | Usage |
|----------|--------|-------|
| `/nearbysearch/json` | GET | Search for nearby pet services by type and location |
| `/details/json` | GET | Get detailed info for a specific place (phone, hours, etc.) |
| `/photo` | GET | Fetch place photos via `photo_reference` |

**Geocoding API** (also used):

| Endpoint | Method | Usage |
|----------|--------|-------|
| `https://maps.googleapis.com/maps/api/geocode/json` | GET | Convert zipcode to lat/lng for nearby search |

**Service type mapping:**

| ServiceType enum | Search query | Google Place type |
|-----------------|--------------|-------------------|
| `petStore` | "pet store" | `pet_store` |
| `veterinarian` | "veterinarian" | `veterinary_care` |
| `grooming` | "pet groomer" | Text Search without the broad `pet_store` filter |
| `boarding` | "pet boarding kennel pet hotel dog daycare" | Text Search |

**Default search radius**: 10,000 meters (10 km)

**Photo URL construction:**
```
https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference={ref}&key={API_KEY}
```

### Google Maps

Used implicitly through the Places API for geocoding and location services. The `geolocator` package handles device GPS access.

### Local Notifications

Uses `flutter_local_notifications` with `timezone` package for scheduled notifications.

**Scheduling patterns:**
- **Reminder notifications**: Two per reminder -- 1 hour before due, and at due time
- **Daily activity reminder**: Recurring daily at user-specified time using `matchDateTimeComponents: DateTimeComponents.time`
- **Streak reminder**: One-time at 8 PM to prevent streak loss

**Platform configuration:**
- Android: `@mipmap/ic_launcher` icon, exact scheduling with `AndroidScheduleMode.exactAllowWhileIdle`
- iOS/macOS: Alert, badge, and sound permissions requested via `DarwinInitializationSettings`

---

## 10. Caching Strategy

### In-Memory TTL Cache

Implemented in provider classes (not in the service layer). Both `PetProvider` and `ActivityProvider` use a 5-minute TTL cache:

```dart
static const _cacheThreshold = Duration(minutes: 5);
DateTime? _lastFetched;
```

**Cache behavior:**
- On data fetch, if `_lastFetched` is within the threshold and data exists in memory, the cached data is returned without a network call.
- On any mutation (create, update, delete), `_lastFetched` is set to `null`, forcing a fresh fetch on the next read.
- For `ActivityProvider`, the cache also tracks `_lastFetchedPetId` to invalidate when switching pets.

### Cache Invalidation

Cache is invalidated (set to null) on:
- Creating a new record
- Updating an existing record
- Deleting a record
- Explicit refresh calls

### Offline Connectivity Handling

A `ConnectivityHelper` singleton (`lib/utils/connectivity.dart`) provides:

- `hasInternetConnection()` -> `Future<bool>` -- checks current connectivity state
- `onConnectivityChanged` -> `Stream<bool>` -- emits true/false on connectivity changes

Providers use this to gracefully handle offline scenarios:
- If cached data exists and the device is offline, the cached data is served silently.
- If no cached data exists and the device is offline, the provider can surface an appropriate state to the UI.

**Note**: Full offline-first support (local database, sync queue) is not yet implemented. The current approach is "cache what you have, fail gracefully when offline."

---

## 11. Environment Setup

### Required Environment Variables

Create a `.env` file in the project root:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
GOOGLE_PLACES_API_KEY=AIzaSy...
```

### Supabase Project Setup

1. **Create a Supabase project** at [supabase.com](https://supabase.com).
2. **Run the migration**: Execute the SQL in `supabase/migrations/001_initial_schema.sql` in the Supabase SQL Editor.
3. **Copy credentials**: From Settings > API, copy the Project URL and anon/public key into your `.env` file.

### Storage Bucket Creation

Create these 4 buckets in Supabase Storage (Dashboard > Storage):

1. `profile-photos` -- set to **Public** bucket
2. `pet-photos` -- set to **Public** bucket
3. `medical-documents` -- set to **Public** bucket (or Private with signed URLs if sensitive documents)
4. `activity-photos` -- set to **Public** bucket

For each bucket, add storage policies to restrict uploads/deletes to authenticated users who own the data.

### OAuth Provider Configuration

#### Google OAuth

1. Create a project in [Google Cloud Console](https://console.cloud.google.com).
2. Enable the "Google Identity" (OAuth 2.0) API.
3. Create OAuth 2.0 Client IDs (Web, iOS, Android as needed).
4. In Supabase Dashboard > Authentication > Providers, enable Google and paste the Client ID and Secret.
5. Add the Supabase OAuth callback URL in Google Cloud, and add the app redirect URLs in Supabase URL Configuration.

#### Apple OAuth

1. In Apple Developer Portal, create a Services ID with "Sign in with Apple" enabled.
2. Configure the return URL to your Supabase project's auth callback.
3. In Supabase Dashboard > Authentication > Providers, enable Apple and configure the Services ID and secret key.

### Google Places API Key Setup

1. In Google Cloud Console, enable the **Places API** and **Geocoding API**.
2. Create an API key.
3. Restrict the key by API (Places API, Geocoding API only).
4. Optionally restrict by app (iOS bundle ID, Android package name).
5. Add the key to `.env` as `GOOGLE_PLACES_API_KEY`.

---

## 12. Backend Maintenance Notes

### How to Add New Tables

1. Create a new migration file: `supabase/migrations/002_your_change.sql`
2. Define the table with appropriate columns, types, and constraints.
3. Add indexes for columns that will be frequently queried.
4. Enable RLS: `ALTER TABLE public.new_table ENABLE ROW LEVEL SECURITY;`
5. Add RLS policies for SELECT, INSERT, UPDATE, DELETE as needed.
6. Run the migration in the Supabase SQL Editor.
7. Create a corresponding Dart model in `lib/models/`.
8. Create a service class in `lib/services/`.
9. Export the model from `lib/models/models.dart`.

### How to Add New RLS Policies

```sql
-- Example: Allow users to read shared data
CREATE POLICY "policy_name" ON public.table_name
    FOR SELECT  -- or INSERT, UPDATE, DELETE
    USING (auth.uid() = user_id);  -- or WITH CHECK for INSERT

-- For indirect ownership (like medical_records -> pets):
CREATE POLICY "policy_name" ON public.table_name
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.parent_table
            WHERE parent_table.id = table_name.parent_id
            AND parent_table.user_id = auth.uid()
        )
    );
```

### How to Add New Storage Buckets

1. Create the bucket in Supabase Dashboard > Storage.
2. Set visibility (Public or Private).
3. Add storage policies for the bucket (who can upload, download, delete).
4. Add a constant in `lib/utils/constants.dart`:
   ```dart
   static const String newBucket = 'bucket-name';
   ```
5. Add upload/delete methods in the relevant service class.

### Credential Rotation Process

#### Supabase Anon Key

1. Rotate the key in Supabase Dashboard > Settings > API.
2. Update the `SUPABASE_ANON_KEY` in `.env`.
3. Rebuild and redeploy the app.
4. The old key is immediately invalidated -- existing app sessions will break until users update.

#### Google Places API Key

1. Create a new key in Google Cloud Console.
2. Apply the same restrictions as the old key.
3. Update `GOOGLE_PLACES_API_KEY` in `.env`.
4. Disable the old key after the new app version is deployed.

#### OAuth Client Secrets

1. Rotate in the respective provider dashboard (Google Cloud, Apple Developer).
2. Update the secret in Supabase Dashboard > Authentication > Providers.
3. No app rebuild needed -- the secret is only stored server-side in Supabase.
