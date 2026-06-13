# Editor Phase 579 pass712 — assignment / call statement ambiguity grammar depth

Pass712 deepens token-cursor coverage for Ada statement forms whose leading
name can be either an assignment target or a call target.

## Implemented

- Added statement-name suffix grammar markers before assignment/call
  classification.
- Added assignment-target markers for selected, indexed, sliced, and explicit
  dereference targets.
- Added call-target markers for selected call names, indexed/actual suffixes,
  and named actual associations.
- Added a bounded recovery boundary for statement-looking names where a missing
  `:=` would otherwise collapse into an ordinary call-shaped recovery path.
- Added AUnit coverage in
  `Test_Language_Model_Token_Cursor_Assignment_Call_Ambiguity_Grammar_Completeness`.
- Updated validation guards and parser-facing documentation.

## Non-goals

This is structural grammar coverage only. It does not perform compiler-grade
resolution for procedure calls vs entry calls, indexed components vs function
calls, slice legality, assignment target legality, access dereference legality,
overload resolution, visibility, mode checking, or expected-type analysis.
