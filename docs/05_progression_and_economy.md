# Progression And Economy

## XP

- Base XP per valid study minute: 8
- Default multiplier: 1.0
- XP is integer based.
- Level cap: 100

## Gold

- Gold is derived from XP.
- Current ratio: `floor(earnedXp * 0.1)`
- This keeps gold tied to real study effort.

## Level Thresholds

Thresholds are generated deterministically from `ProgressionSystem`.

Fixed early thresholds:

- Level 1 -> 2: 100 XP
- Level 2 -> 3: 150 XP
- Level 3 -> 4: 250 XP
- Level 4 -> 5: 400 XP

After that, piecewise scaling targets roughly 1.5M cumulative XP for level 100.

## Future Economy Hooks

- streak multiplier
- focus mode multiplier
- minigame bonus gold
- shop pricing
- cosmetic rarity tiers
