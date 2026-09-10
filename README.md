# HabitFlow

A Flutter habit tracker that treats trading discipline as a first-class
habit category alongside everyday habits (water, exercise, reading,
sleep...) - so you can see "did I follow my trading plan today" right
next to "did I drink enough water", with real streaks, a completion-rate
history, and a small celebration when you hit a milestone.

Built for Android. Local-first: everything is stored on-device with
[Hive](https://pub.dev/packages/hive) - no backend, no account, no
network dependency for the app to work.

## Features

- Two habit domains, visually distinct everywhere: **General** (teal) and
  **Trading** (amber/gold) - e.g. "Followed my trading plan", "No revenge
  trading", "Respected max risk per trade", "Pre-market checklist"
  alongside "Drink water", "Exercise", "Meditate".
- Quick-start templates for both domains, or fully custom habits with
  their own emoji, color, and repeat schedule (daily or specific
  weekdays).
- Real streaks: current streak, longest streak ever, and a 30-day
  completion rate - computed from actual logged days, not guessed.
- A GitHub-contributions-style calendar heatmap per habit.
- A small confetti celebration when a habit's streak hits 7/14/30/60/100/365 days.
- A stats screen: overall completion rate, best streak, a 7-day bar
  chart, and a per-category breakdown.
- Smooth, purpose-built animations: an animated completion toggle, a
  custom-painted progress ring for "today", Hero transitions from list to
  detail, and staggered list entrance animations - no generic
  off-the-shelf look.

## Tech stack

- **Flutter** (Material 3, dark theme)
- **Hive** for local persistence (pure Dart, no native platform code)
- **provider** for state management
- **fl_chart** for the stats bar chart, **confetti** for celebrations,
  **flutter_animate** for entrance animations

No `google_fonts` or any other runtime-fetched asset - the UI renders
instantly offline using the platform's bundled font, refined with custom
weights/letter-spacing. This is a deliberate choice, not an oversight: a
habit tracker should never depend on a network call just to draw text
(and, as a bonus, it also means the app doesn't need a network connection
to look right, on your phone or in CI).

## Getting started

```
flutter pub get
flutter run          # requires a connected device/emulator, or `-d chrome` for web
```

## Running tests

```
flutter analyze
flutter test
```

All 15 tests (repository streak logic, provider, and two widget smoke
tests) pass. Coverage includes the streak/completion-rate math - see
`test/data/habit_repository_test.dart` for the documented definition of
"streak" (consecutive *scheduled* days completed; non-scheduled days
never break it; today not being done yet doesn't zero out yesterday's
streak).

**Note on widget tests**: `HabitRepository` does real `dart:io` file
writes (Hive). Flutter's `testWidgets` runs on a fake clock, which does
not let genuine async I/O resolve inside a test body on its own - any
such call triggered during a test (not just in `setUp`) has to go through
`tester.runAsync(...)`, and after `runAsync` you still need to give the
real event loop an actual turn (e.g. a tiny `Future.delayed`) before
`pumpAndSettle()`, since `pumpAndSettle` only waits for scheduled
*frames*, not arbitrary pending Futures. Both widget tests do this - see
the comment at the top of `test/widget/app_smoke_test.dart` before
"simplifying" it. Separately, in this project's original dev sandbox
(a constrained, root-executed container), the `flutter_tester` process
itself takes a while and prints a benign `Bad state: Cannot close sink
while adding stream` during shutdown *after* all named tests have already
passed - that's a harness/process-teardown quirk of that specific
environment, not a failing test (a plain `flutter test test/data
test/providers` run, with no widget bindings involved, exits cleanly and
instantly). If your machine doesn't reproduce it, that's expected too.

## Building the APK

This project was originally developed in a sandbox with **no Android
SDK** and no access to `dl.google.com` (where the SDK is normally
fetched) - so the release APK couldn't be built locally there. Two ways
to get a real one:

1. **GitHub Actions (works with zero local setup)**: push to `main` or
   run the "Build Android APK" workflow manually from the Actions tab.
   It builds on a GitHub-hosted runner (Android SDK preinstalled),
   analyzes, tests, then builds `app-release.apk` and uploads it as a
   downloadable artifact. See `.github/workflows/build_apk.yml`.
2. **Locally, with Android Studio installed**:
   ```
   flutter build apk --release
   ```
   The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

## Project structure

```
lib/
├── models/          Habit, HabitLog, HabitCategory, habit templates
├── data/            HabitRepository - all Hive reads/writes + streak math
├── providers/       HabitProvider (ChangeNotifier) - the only thing screens talk to
├── screens/         Home, Add/Edit Habit, Habit Detail, Stats
├── widgets/         ProgressRing, HabitTile, CalendarHeatmap, CelebrationOverlay, CategoryChip
├── theme/           AppColors / AppTheme
└── app.dart, main.dart

test/
├── data/            streak/completion-rate logic (pure Dart, fast)
├── providers/       HabitProvider behavior, including milestone detection
└── widget/          end-to-end smoke tests through the real UI
```

## What's next (not implemented yet, honestly)

- Notifications/reminders.
- iOS build (the project only configures Android + web platforms today;
  adding iOS is a `flutter create --platforms ios .` away but needs a Mac
  to actually build and sign).
- Cloud sync/backup of the local Hive data.
- Editing a habit's schedule doesn't retroactively re-evaluate past
  streaks under the new schedule - it only affects future days.
