# Focus RPG

Focus RPG is a Flutter-based focus timer and productivity app with RPG-inspired progression systems. The current build includes a portrait-oriented mobile layout, main menu, persistent save slots, character class selection, global settings, a main hub, focus sessions, profile statistics, and the first database layer for sessions, inventory, and cosmetics.

## Features

- Dark themed Flutter UI with portrait-oriented main menu, settings, save slots, character selection, main hub, focus session, and profile routes.
- Up to three local save profiles.
- Character classes: Mage, Knight, Archer, and Thief.
- SQLite persistence through `sqflite`, with Windows support through `sqflite_common_ffi`.
- Global settings persistence for dark mode, sound effects, music, and volume levels.
- Focus session flow with start confirmation, break handling, completion, cancellation confirmation, and recent session history.
- XP, level threshold, and gold reward calculations based on valid study minutes.
- Seeded item and cosmetic tables for future progression and reward systems.
- Repository layer for profiles, settings, focus sessions, inventory quantities, owned cosmetics, and equipped cosmetics.

## Tech Stack

- Flutter
- Dart
- `sqflite`
- `sqflite_common_ffi`
- `path`
- `path_provider`

## Project Structure

```text
lib/
  core/                 Route names and app-level constants
  data/database/        SQLite database setup and schema
  data/models/          Database-backed model objects
  data/repositories/    Repository API for game data
  models/               UI-facing save models
  services/             App services used by screens
  views/                Flutter pages
  widgets/              Shared UI widgets
```

## Project Documentation

See [docs/README.md](docs/README.md) for product goals, architecture, progression, economy, UI direction, testing strategy, and roadmap notes.

## Getting Started

Install Flutter, then fetch dependencies:

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```

Run the web app with persistent browser storage:

```powershell
.\scripts\run_web_persistent.ps1
```

Run the test suite:

```bash
flutter test
```

## Current Status

This is an early playable prototype. The app can create and persist save slots, open a selected profile into the main hub, start and complete focus sessions, award XP and gold from valid study minutes, show profile statistics, and list recent sessions. Global settings are also persisted outside individual save files.

Several systems are intentionally still placeholder-level. Shop, inventory UI, cosmetic equipment, power-ups, animated backgrounds, audio feedback, and AFK-prevention minigames are planned but not production-ready yet. The break unlock duration is currently shortened for testing and should be restored before a release build.
