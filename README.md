# Focus RPG

Focus RPG is a Flutter-based focus timer and productivity app with RPG-inspired progression systems. The current build includes a main menu, save slots, character class selection, local profile persistence, and the first database layer for sessions, inventory, and cosmetics.

## Features

- Dark themed Flutter UI with main menu, settings, save slots, and character selection routes.
- Up to three local save profiles.
- Character classes: Mage, Knight, Archer, and Thief.
- SQLite persistence through `sqflite`.
- Seeded item and cosmetic tables for future progression and reward systems.
- Repository layer for profiles, focus sessions, inventory quantities, owned cosmetics, and equipped cosmetics.

## Tech Stack

- Flutter
- Dart
- `sqflite`
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

This is an early prototype. The data model is in place for focus sessions and RPG progression, while the current UI focuses on profile slot creation and class selection. The next likely milestones are session timers, reward calculation, inventory views, and cosmetic equipment screens.
