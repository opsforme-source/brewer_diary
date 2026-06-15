# Brewer Diary v1

Flutter starter app for tracking wine, mead, SG/ABV, ingredients, tastings, and notes.

## Features

- Separate tabs for ideas, completed batches, ratings, and settings
- Batch list with status, dates, OG, FG, calculated ABV, total age, and bottle age
- Add/edit batches
- Ingredient list per batch
- Free notes
- Gravity readings timeline
- Tasting notes with category scores and calculated average
- Local persistence using `shared_preferences`
- Bundled seed import from the original spreadsheet screenshot
- JSON export/import strings from settings screen

## Setup

```bash
flutter pub get
flutter run
```

## Seed data

The first spreadsheet screenshot has been converted into bundled seed data:

```text
seed/brewer_diary_seed.json
```

To load it into the app:

1. Open the app.
2. Go to **Beállítások**.
3. Tap **Alap adatok betöltése**.
4. Confirm the import.

Notes:

- The purple `Mayer chili mead` row did not show exact dates in the screenshot, so it has a placeholder start date and an explanatory note.
- Rows without visible ratings keep `manualRating` as `null`.
- ABV is calculated from OG/FG inside the app rather than stored as a separate imported value.

## Code structure

```text
lib/
  main.dart                         App entrypoint only
  app/brewer_diary_app.dart         Theme and root app wiring
  calculators/gravity_calculator.dart
  controllers/batch_controller.dart State and local persistence
  models/                           Data/domain objects and JSON parsing
  screens/                          User-facing screens and dialogs
```

### Responsibility map

- `models/brew_batch.dart`: main domain model, derived ABV, total age, bottle age, and finished-date age stop logic.
- `models/brew_status.dart`: batch lifecycle states and Hungarian labels.
- `controllers/batch_controller.dart`: loads, saves, imports, exports, and mutates batches.
- `screens/ideas_screen.dart`: planned batches only.
- `screens/batch_list_screen.dart`: production list for active/completed batches, without scoring clutter.
- `screens/rating_screen.dart`: detailed tasting scores.
- `screens/batch_edit_screen.dart`: create/edit form, default FG 1.000, finished date handling.
- `screens/batch_detail_screen.dart`: production details, ingredients, SG readings, and notes.
- `screens/settings_screen.dart`: bundled seed import plus JSON export/import.
