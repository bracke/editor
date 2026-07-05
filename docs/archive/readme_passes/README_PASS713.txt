# Editor pass713 — return statement grammar depth

Pass713 deepens token-cursor coverage for Ada return statement families while
keeping analysis deterministic, snapshot-owned, and structural.

## Implemented

- Added explicit extended-return return-object defining-name markers.
- Added return-object subtype indication and initializer markers.
- Added explicit `do` and `end return` boundary markers for extended return
  statements.
- Added bounded return recovery boundaries for malformed extended return
  headers and missing statement terminators.
- Preserved existing simple return, expression return, and extended-return
  compatibility markers.
- Added AUnit coverage in
  `Test_Language_Model_Token_Cursor_Return_Statement_Depth_Grammar_Completeness`.
- Updated validation guards and parser-facing documentation.

## Non-goals

This is structural grammar coverage only. It does not perform compiler-grade
return-type checking, return-object legality, limited-type build-in-place
semantics, control-flow analysis, function/procedure context validation,
accessibility checks, definite-assignment analysis, or overload resolution.
