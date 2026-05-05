# Testing Strategy

## Unit Tests

Progression rules should remain covered by unit tests:

- fixed thresholds
- threshold count
- monotonic growth
- cumulative XP range
- level cap
- XP/gold rewards

## Manual Tests

Manual test flows:

- create save
- restart app and verify persistence
- start session
- complete session
- verify XP/gold/profile updates
- cancel session and verify no completed session is written
- open profile and verify recent sessions

## Platform Priority

Windows desktop is the current persistence validation target. Android should become the primary target once mobile iteration starts.
