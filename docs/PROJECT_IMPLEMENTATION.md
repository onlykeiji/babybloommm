# Project Implementation

## 1. Implementation Overview

BabyBloom was implemented as a cross-platform Flutter application supported by Supabase services. The system provides three user journeys: Family Planning, Pregnancy, and Baby Care. A user selects a journey during onboarding, and the application stores this selection as the user's application mode. On succeeding logins, the stored mode is retrieved and the user is directed to the appropriate dashboard.

The application uses Flutter and Dart for the user interface and application logic. Supabase Authentication manages user accounts and sessions, while Supabase PostgreSQL stores user profiles, settings, health records, care logs, community data, and progress records. Row-Level Security (RLS) policies are used on most user-owned tables so authenticated users can access only their own information. Google Gemini is integrated for the Bloom AI assistant, while the `pdf` and `printing` packages are used to generate and share selected reports.

The implementation follows a feature-oriented project structure. Authentication and onboarding screens are separated from the main application features. Shared services, state stores, themes, and reusable interface components are placed in the core layer. Feature screens use store classes to retrieve and persist records through the Supabase client. Reactive screen updates are primarily handled with Flutter stateful widgets, `ValueNotifier`, and `ValueListenableBuilder`.

## 2. Authentication and Session Management

### 2.1 Purpose

The authentication module protects personal health and baby-care information and provides each user with an individual system account.

### 2.2 User workflow

A new user creates an account by entering a name, email address, password, and password confirmation and accepting the terms. Supabase creates the authentication account and sends an email verification code. The user enters the code in the application before gaining access to the main system.

An existing user signs in with an email address and password. After authentication, the application retrieves the associated profile and saved application mode. A verified user is routed to the Family Planning, Pregnancy, or Baby Care dashboard. A user without a saved mode is sent to journey onboarding.

The module also provides logout, forgotten-password recovery, recovery-code verification, password reset, and authenticated password change. Changing a password requires verification of the current password before the new password is submitted.

### 2.3 Database and service interaction

Supabase Authentication stores account credentials and manages sessions. A database trigger creates a corresponding row in the `profiles` table when an authentication account is created. The profile contains the user's name, email, birth date, journey stage, and application mode.

### 2.4 Validation and error handling

Registration validates required fields, email format, a minimum password length of six characters, matching passwords, and acceptance of the terms. Login and recovery forms reject empty required values. Authentication exceptions returned by Supabase are caught and presented through form messages or snackbars. Loading states prevent repeated submissions while a request is being processed.

## 3. Onboarding and Journey Management

The onboarding module introduces the application and allows the user to select Family Planning, Pregnancy, or Baby Care. The selected journey is stored in the user's profile as the application mode. Mode-specific onboarding collects relevant initial information, such as cycle preferences, pregnancy information, or baby profile details.

The saved mode controls dashboard content, the title of the second bottom-navigation destination, available settings, and the information supplied to Bloom AI. Because the mode is retrieved after login, users do not need to repeat journey selection during every session.

## 4. User Profile and Application Settings

### 4.1 Profile management

The Profile module allows the authenticated user to view and update personal details and change the account password. Profile retrieval and updates use the `profiles` table and the authenticated account identifier.

Profile functionality consists of automatic creation, retrieval, and update. Direct account deletion is not currently implemented and is therefore not treated as completed CRUD functionality.

### 4.2 Application settings

The application maintains one `app_settings` record per account. Depending on the active journey, the user can configure cycle lengths, period length, luteal-phase length, pregnancy week, due date, pre-pregnancy weight, tracking categories, measurement unit, and notification preferences. Privacy-related preferences include anonymous posting and research-data preference values.

Settings are initially inserted or retrieved and are subsequently updated through Supabase. A unique user index prevents multiple settings rows for one account. Database constraints provide accepted ranges for selected numerical settings.

Some preferences are only partially implemented. Haptic feedback, research-data sharing, and several notification categories can be saved, but they are not connected to complete application-wide services. The language screen currently supports English and identifies additional languages as in progress. Measurement-unit selection is also not consistently applied to every measurement display.

### 4.3 Support functions

The Help Center displays built-in frequently asked questions. Contact Us validates the subject and message before creating a `support_requests` record owned by the current user. Rate BabyBloom allows a score and optional feedback to be inserted or updated in `app_ratings`.

Data export and account deletion are partially implemented. Their screens and confirmation messages exist, but the system does not yet generate an export, send an email, or delete the Supabase authentication account and related data.

## 5. Main Navigation and Interface

The principal interface uses a five-item bottom navigation bar. Its destinations are Home; Cycle, Journey, or Grow according to the current mode; Community; Insights; and Profile. Navigation uses Flutter `MaterialPageRoute` operations. When switching primary tabs, the application returns to the main navigation level before opening the selected module, reducing duplicate routes.

Secondary features use back navigation and dedicated screens or dialogs. Shared UI components provide consistent backgrounds, cards, statistics, buttons, confirmation dialogs, headers, and the bottom navigation bar. Content is constrained to a readable maximum width to improve presentation on larger displays while retaining a mobile-focused layout.

## 6. Family Planning Module

### 6.1 Daily cycle logging

The Family Planning module allows the user to record period flow, mood, symptoms, and notes for a selected date. Each record is stored in `daily_logs` and is identified by the authenticated user and log date. An upsert operation creates a new daily record or updates an existing record for the same date.

The user can select dates through the calendar or weekly date strip, enter the available tracking values, and save the daily log. The dashboard and insights screens refresh from the stored data. This feature implements create, read, and update operations; deletion of an entire daily log is not available.

### 6.2 Cycle prediction

The system calculates estimated period, fertile-window, and ovulation dates from the user's cycle settings and saved period-start records. Prediction is performed locally in the application and does not use an external medical API. The interface identifies the results as estimates rather than medical diagnoses.

### 6.3 Family Planning insights

The Insights module analyzes saved cycle logs to display cycle regularity, cycle variability, trends, frequently recorded symptoms, recent moods, and informational suggestions. Empty states are shown when insufficient records exist. The calculations are derived from the user's records and settings rather than generated sample data.

### 6.4 Lessons and reports

Family Planning lessons and quiz questions are embedded in the application. Successful lesson completion is saved in `lesson_completions`, using a user-and-lesson relationship to prevent duplicate progress records. Selected insight information can be converted into a PDF and opened through the platform printing or sharing interface.

## 7. Pregnancy Module

### 7.1 Pregnancy dashboard and journey

The Pregnancy dashboard displays the current week, trimester, estimated due date, baby-development information, pregnancy tips, mood, and symptom check-ins. Pregnancy week and due-date information come from `app_settings`. Week-specific developmental descriptions and guidance are built into the application and are not retrieved from an external medical database.

The Journey screen presents pregnancy progress and milestone summaries. Some week selections provide only a short informational response instead of a complete detailed drill-down; this portion is considered partially implemented.

### 7.2 Pregnancy weight tracking

Pregnancy weight entries are stored in `pregnancy_weight_entries` by authenticated user and date. The user can add a measurement, retrieve measurements, and update an entry for an existing date through an upsert operation. Complete historical deletion and record-management controls are not currently available, so the feature provides partial rather than full CRUD.

### 7.3 Contraction timer

The contraction timer records the start, end, duration, and occurrence of contractions. Users can view saved contractions and clear recorded sessions. It supports creation, retrieval, and deletion but does not provide individual record editing.

The current `contractions` table is not associated with a user identifier and uses permissive database access. Although the interface is functional, user-level isolation for this data remains in progress.

### 7.4 Hospital bag checklist

The checklist provides built-in preparation items and allows the user to mark or unmark packed items. Completion state is stored in `hospital_bag_progress`. The checklist does not provide user-created item management.

Like contraction records, hospital bag progress is not currently scoped by `user_id`. Its interface works, but account-level database isolation is incomplete.

### 7.5 Baby-name exploration

Users can search and filter a built-in list of baby names and add custom names. Custom entries are saved per account in `baby_name_entries` and can be deleted. Although an update policy exists, the current interface does not provide complete custom-name editing. Favorites function within the open screen but are not stored after the application is restarted.

### 7.6 Kick counter

The kick counter stores every tap as an individual timestamped event in `pregnancy_kick_logs`. When the Pregnancy dashboard opens, it retrieves the authenticated user's events for the current local day and restores the displayed count. Reset removes only that user's kick events for the current day. Row-Level Security permits users to read, create, and delete only their own kick records.

## 8. Health Record Management

### 8.1 Medication records

Medication management allows the user to create, view, edit, and delete medication records. A record may include the medication name, dosage or instructions, schedule information, and reminder status. Records in `medication_reminders` are associated with `user_id`, and RLS restricts access to the owner.

The medication name is required. Supabase failures are caught and reported, while confirmation is requested before destructive actions.

### 8.2 Health appointments

Users can create, view, update, and delete healthcare appointments. Appointment information and reminder state are stored in `health_appointments` and scoped to the authenticated account. The title is required, and date entry is controlled through the application's date-selection interface.

### 8.3 Vaccine log

The vaccine log supports complete CRUD operations for administered or planned vaccines. Users can select or enter a vaccine, save its date and status, edit the record, enable a reminder for an incomplete vaccine, or delete it.

Completed vaccine records are treated as historical information rather than future events. The application disables their reminder control, and the database contains a check constraint preventing a completed record from retaining an enabled reminder. The Baby Care interface also contains a built-in informational list of common infant vaccines. This list is static and should be used together with professional medical advice and the applicable national immunization schedule.

Medication, appointment, and vaccine records are scoped directly to the user rather than to `baby_id`. Under the one-baby-per-account rule, they function as the health records for that account's baby, but the relationship is indirect at the database level.

## 9. Baby Care Module

### 9.1 Baby profile

The Baby Care journey requires a baby profile. After login, the application checks `baby_profiles` for a record owned by the authenticated account. When a profile exists, it is retrieved and displayed automatically. The user is asked to create a profile only when no existing record is found.

The profile stores identifying and birth-related details, including the baby's name and date of birth. Users can create, view, edit, and delete the profile. Form validation rejects an empty name, a future birth date, and invalid measurement values.

A partial unique index on `baby_profiles.user_id` enforces one baby profile per account. Child records such as growth, milestones, and care logs use the baby identifier, while RLS policies confirm that the referenced baby belongs to the current user.

### 9.2 Baby Today care logs

The Baby Today screen records routine feeding, diaper, and sleep activities. A care log stores the activity type, occurrence time, optional duration, optional amount, and descriptive details. Feeding details may represent breastfeeding, bottle feeding, formula, or pumped milk; diaper logs distinguish wet, dirty, or mixed changes; and sleep records may identify naps or nighttime sleep.

The user can add an activity, review its history, edit it, and delete it. These operations use `baby_care_logs`, with both `user_id` and `baby_id` ownership checks. The dashboard presents today's totals so the user can immediately review recorded care.

Validation prevents significantly future occurrence times, invalid durations or quantities, and overly long descriptions. Database constraints additionally reject negative amounts and durations.

### 9.3 Growth tracking

The Grow screen records weight, height or length, and head circumference. The user can select a measurement type, save a dated entry, review historical entries, update a record, or delete it. Data is stored in `growth_entries` and protected through ownership of the associated baby profile.

The screen displays the latest measurement and a simplified reference chart. The reference curves are illustrative WHO-style ranges and are clearly identified as non-diagnostic. Growth forms require positive numeric values and reject future dates. The current general maximum-value validation is shared across measurement types and could be made more measurement-specific in future development.

### 9.4 Developmental milestones

The milestone interface combines developmental information, suggested activities, and completion controls on the Grow screen. Built-in milestone definitions cover two and four weeks and two, four, six, nine, twelve, fifteen, eighteen, and twenty-four months. Each entry identifies a developmental domain, explains the expected behavior, and recommends an activity a caregiver can perform with the baby.

The system calculates the baby's age from the date of birth. A milestone remains locked until the required age is reached. If the user attempts to complete it early, the action is rejected with an explanatory message. When an eligible milestone is marked complete, an achievement is inserted into `milestones`; unmarking deletes the achievement record. The achievement date must fall between the baby's birth date and the current date.

Milestone definitions are static application content. Users manage achievement status but cannot alter the definitions themselves.

### 9.5 Baby Care insights

The Baby Care Insights screen converts saved records into a practical overview. It displays today's number of feeds and diaper changes, total sleep duration, a seven-day care summary, feeding quantities, latest growth values, and milestone progress. Personalized cards change according to the available data, while empty states explain which activities should be recorded before patterns can be calculated.

All displayed values are derived from the authenticated user's care logs, growth entries, and milestone records. The insight calculations occur in the Flutter application and do not use an external analytics service.

## 10. Community Module

### 10.1 Community posts

Authenticated users can create a status or question, select a topic, and choose whether the displayed author should be anonymous. The Community screen retrieves posts and provides topic filtering, My Posts, and Liked views.

Post authors can edit or delete their own posts. The interface displays management controls only for the owner. Post content is required and limited in length. The `community_posts` table stores author, topic, body, display choice, and engagement counters.

At the database level, the author-only update migration exists; however, the original schema also defines a broad legacy update policy. If that policy remains deployed, it should be removed because PostgreSQL permissive policies can allow an operation when any applicable policy permits it. The application-level ownership controls work, but final database hardening is still in progress.

### 10.2 One like per account

Post likes are stored in `community_post_likes`. Its composite primary key of `post_id` and `user_id` ensures that one authenticated account can like a particular post only once. Selecting an unliked post inserts a relationship, while selecting an already liked post removes it. A database trigger recalculates and synchronizes the post's like count after every insert or delete.

RLS allows authenticated users to read like relationships, insert only their own like, and remove only their own like.

### 10.3 Comments

Users can open a discussion, view its comments, and add a comment. `community_comments` stores the post reference, user identity, author display information, and message. A trigger updates the parent post's comment count.

Comment creation and reading are functional. Comment editing and deletion are not implemented and are therefore considered in progress.

### 10.4 Groups and messages

The application displays predefined community groups and allows an authenticated user to join one. Membership is stored in `group_memberships`, and a trigger maintains group member totals. Group members can retrieve and send messages through `group_messages`. RLS checks membership before permitting message access.

Leaving a group and editing or deleting messages are not implemented. Group participation therefore provides create-and-read functionality rather than complete CRUD.

## 11. Insights and Report Generation

Insights are separated by application mode to keep information relevant to the user's current journey. Family Planning insights analyze cycles, symptoms, and moods. Pregnancy insights use pregnancy settings and check-in records. Baby Care insights summarize feeds, diapers, sleep, growth, and milestones.

The application handles missing information using empty-state cards rather than generating unsupported conclusions. Family Planning and Pregnancy report information can be converted into a PDF. The report is generated locally and passed to the platform's printing or sharing workflow.

## 12. Bloom AI Integration

Bloom AI provides a conversational assistant available from the main application screens. Before sending a request, the system prepares context using the authenticated profile, selected journey, relevant settings, and available tracking summaries. The prompt restricts responses to Family Planning, Pregnancy, and Baby Care topics and requests concise, supportive answers with medical caution where appropriate.

Requests are submitted to the Google Gemini API through the HTTP package. API responses are parsed and displayed in the conversation. Network and API failures are caught and shown to the user.

The integration is operational when a valid API key is configured. The current key configuration is client-side; moving Gemini requests to a protected backend or Supabase Edge Function remains a recommended security improvement rather than a completed feature.

## 13. Database Security and Authorization

Supabase RLS provides the primary database authorization mechanism. Most personal tables compare `auth.uid()` with their `user_id`. Baby-related child tables additionally verify ownership through `baby_profiles`. Foreign keys apply cascading deletion where appropriate, and unique indexes prevent duplicate settings, daily logs, milestones, baby profiles, ratings, and likes.

Database triggers perform automatic profile creation, timestamp maintenance, engagement-counter synchronization, and group-member counting. Check constraints protect selected status and numerical values.

Two legacy areas remain partially secured: `contractions` and `hospital_bag_progress` do not contain user ownership, and the legacy broad Community post update policy may remain unless explicitly removed. These limitations should be corrected before production deployment.

The base `schema.sql` also contains an unused legacy `belly_photos` table. There is no active photo picker, upload workflow, file-storage integration, or photo attachment interface in the current application. Consequently, photo or file attachment is not an implemented system feature. App Lock is likewise absent from the current implementation.

## 14. Form Validation and Error Handling

Forms use required-field checks, format validation, numerical ranges, date restrictions, text-length limits, and ownership checks according to the type of information being submitted. Destructive actions generally display a confirmation dialog. Save buttons use loading states to reduce duplicate requests.

Asynchronous database and API calls are normally enclosed in exception handling. The interface uses inline messages, snackbars, loading indicators, and empty-state components to communicate outcomes. Optimistic interface updates used by selected toggles are rolled back when persistence fails.

Startup retrieval failures are sometimes suppressed so an individual screen can retry loading later. This prevents startup failure but may temporarily display empty or default information without a detailed error. Some optional fields also rely primarily on client validation, and automated coverage is currently limited to a basic Flutter widget test. Comprehensive unit, integration, database-policy, and form-validation tests remain in progress.

## 15. Current Implementation Status

The current BabyBloom implementation provides operational authentication, mode-specific dashboards, user settings, Family Planning logs and estimates, Pregnancy information, Baby Care profile and activity management, growth tracking, age-controlled milestones, health-record CRUD, community post CRUD, one-like-per-account enforcement, mode-relevant insights, educational lessons, PDF reports, support submission, and Bloom AI integration.

The following functions are explicitly classified as partially implemented or in progress:

- Device-level scheduled notifications and push notifications
- Actual user-data export and account deletion
- Complete use of unit, haptic, research-data, and anonymous-post preferences
- Historical Pregnancy weight deletion and management
- Persistent baby-name favorites and custom-name editing
- Comment editing and deletion
- Leaving groups and managing existing group messages
- User isolation for contraction and hospital-bag records
- Removal of the legacy broad Community post update policy
- Comprehensive automated test coverage

These limitations are not presented as completed system capabilities. They identify the exact boundary between the functions currently operating in the application and the features that require further implementation or database hardening.
