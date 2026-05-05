# Decision Log

## Native Persistence

Use SQLite on native platforms. Windows uses `sqflite_common_ffi`.

## Web Persistence

Web is not the primary persistence target. It exists for quick UI checks only.

## Progression

Progression rules live in `core/progression.dart` so database, UI, and tests share one source of truth.

## Reward Calculation

Rewards are based on valid focus minutes, not total session time. Break time does not grant rewards.

## Profile Access

The main hub avatar opens the profile page. The bottom hub action area is reserved for Start Session.
