# Architecture

## Layers

- `views/`: Flutter screens and UI composition.
- `services/`: Application-facing APIs used by views.
- `data/repositories/`: Database operations and transactions.
- `data/models/`: Database-backed model objects.
- `core/`: App routes, progression rules, and app-level domain helpers.

## Current Flow

1. UI calls `SaveService`.
2. `SaveService` delegates to `GameRepository` on native platforms.
3. `GameRepository` reads and writes SQLite through `AppDatabase`.
4. Session completion uses `ProgressionSystem` to calculate XP, gold, and level.

## Platform Notes

Native targets use SQLite. Web has lightweight fallback storage for convenience, but native remains the reliable persistence target.
