# Session Mechanics

## Focus Timer

The main timer tracks active focus time. This is the value used for valid study minutes and rewards.

## Total Timer

The smaller total timer includes break time and shows total session duration.

## Breaks

Break unlock currently uses a shortened test interval. Production should restore the intended 20 minute unlock. Breaks pause focus time and run their own countdown.

## Completion

Only `Complete Session` writes a session record. Cancel exits without saving a completed session.

## Reward Validation

Valid study minutes are calculated with floor division. Sessions shorter than one full valid minute grant 0 XP and 0 gold.
