# Editor Phase 579 Pass845 — Null-record aggregate keyword and recovery depth

Pass845 improves structural grammar coverage for Ada extension aggregates that use the `with null record` form.

## Parser/token-cursor changes

- Adds explicit null-record aggregate keyword metadata:
  - `Production_Null_Record_Aggregate_Null_Keyword`
  - `Production_Null_Record_Aggregate_Record_Keyword`
- Adds bounded recovery metadata for malformed/in-progress null-record aggregates:
  - `Production_Null_Record_Aggregate_Missing_Record_Recovery_Boundary`
- Preserves the existing `Production_Null_Record_Aggregate` marker for well-formed `with null record` extension aggregates.
- Keeps ordinary extension aggregate component association recovery separate from the `with null record` path.

## Regression coverage

Adds AUnit coverage in `Test_Language_Model_Token_Cursor_Null_Record_Aggregate_Keyword_Recovery_Pass845` for:

- well-formed `with null record` aggregates;
- explicit `null` / `record` keyword markers;
- malformed `with null` recovery;
- recovery into following declarations.

This is structural grammar metadata only. It is not compiler-grade aggregate legality checking, tagged-type legality checking, type resolution, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
