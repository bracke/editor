# Editor Phase 579 - Pass 653

This pass improves structural token-cursor grammar coverage for Ada delay statements.

## Changes

- Added dedicated productions for delay-statement expression operands:
  - `Production_Delay_Until_Expression`
  - `Production_Delay_Relative_Expression`
- Updated delay-statement parsing so `delay until ...;` retains the absolute-time expression position explicitly.
- Updated delay-statement parsing so `delay ...;` retains the relative-duration expression position explicitly.
- Preserved the existing `Production_Delay_Statement`, `Production_Delay_Until_Statement`, and `Production_Delay_Relative_Statement` classifications.
- Extended AUnit regression coverage for relative delays, absolute delays, qualified delay expressions, selected-name time expressions, and recovery into a following statement.

## Scope

This is structural grammar coverage only. It does not perform compiler-grade legality checking for delay-expression type conformance, time-base validity, tasking restrictions, or real-time semantics.
