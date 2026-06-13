# Editor Phase 579 - Pass 700

Pass 700 deepens structural grammar coverage for Ada entry/select constructs.

## Implemented

- Added token-cursor productions:
  - `Production_Select_Entry_Call_Alternative`
  - `Production_Timed_Entry_Call_Alternative`
  - `Production_Conditional_Entry_Call_Alternative`
  - `Production_Select_Delay_Alternative`
  - `Production_Entry_Call_Entry_Name`
  - `Production_Entry_Call_Index`
- Retained select alternatives containing entry calls separately from ordinary call-shaped statements.
- Retained timed-entry-call delay alternatives inside select statements.
- Retained conditional-entry-call else alternatives inside select statements.
- Retained delay/terminate-family alternatives with a tasking-specific select marker.
- Retained entry-call target names and indexed/actual entry-call prefixes separately from generic call targets.
- Added AUnit regression coverage for entry calls, timed entry calls, conditional entry calls, guarded selective alternatives, delay alternatives, terminate alternatives, and recovery into following declarations.
- Updated the phase validation guard and release/documentation notes.

## Scope

This improves structural grammar coverage for Ada entry calls and select alternatives. It is not compiler-grade legality checking for entry family resolution, callable-profile conformance, timed-entry-call legality, conditional-entry-call legality, selective-accept legality, guard semantics, delay semantics, terminate alternative legality, accessibility, visibility, or runtime tasking behavior.
