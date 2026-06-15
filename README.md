# Brewer Diary v1

Flutter starter app for tracking wine, mead, SG/ABV, ingredients, tastings, and notes.

## Features

- Separate tabs for ideas, completed batches, ratings, and settings
- Batch list with status, dates, OG, FG, calculated ABV, and age
- Add/edit batches
- Ingredient list per batch
- Free notes
- Gravity readings timeline
- Tasting notes with category scores and calculated average
- Local persistence using `shared_preferences`
- JSON export/import strings from settings screen

## Setup

```bash
flutter pub get
flutter run
```

## Seed data

The first spreadsheet screenshot has been converted into importable seed data:

```text
seed/brewer_diary_seed.json
```

To load it into the app:

1. Open the app.
2. Go to **Beállítások**.
3. Tap **JSON import**.
4. Paste the content of `seed/brewer_diary_seed.json`.
5. Tap **Import**.

Notes:

- The purple `Mayer chili mead` row did not show exact dates in the screenshot, so it has a placeholder start date and an explanatory note.
- Rows without visible ratings keep `manualRating` as `null`.
- ABV is calculated from OG/FG inside the app rather than stored as a separate imported value.

## Current code shape

The app is still intentionally kept in a single `lib/main.dart` file while the UI is moving quickly. The next clean-up step should be a modular split into `models/`, `screens/`, `controllers/`, and `data/` once the tab structure and seed import flow feel right.
