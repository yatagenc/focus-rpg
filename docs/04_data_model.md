# Data Model

## Profile

Stores one save slot and its long-term progression:

- profile id
- class
- total XP
- level
- gold
- created date
- last played date
- total study minutes
- total completed sessions

## Session

Stores completed focus sessions:

- profile id
- session type
- start/end timestamps
- duration minutes
- completed flag
- XP earned
- gold earned

## Item Ownership

The schema supports item ownership with quantity, but shop logic is not implemented yet.

## Cosmetics

Cosmetics, owned cosmetics, and equipped cosmetics are seeded/structured for future use.

## App Settings

Global settings are not profile-bound. They are stored in `AppSettings`.
