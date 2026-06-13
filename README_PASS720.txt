# Editor Phase 579 — Pass 720

Pass 720 implements nr 10 as a focused local duplicate-choice diagnostics pass.

## Scope

This pass adds conservative legality-adjacent diagnostics for syntactic duplicate
choices/selectors that are already retained by the parser and language model.
It intentionally remains local and structural; it does not try to perform full
Ada choice coverage, staticness, visibility, overload resolution, or expected
Type analysis.

## Changes

- Added language-model diagnostic kinds:
  - `Legality_Duplicate_Case_Choice`
  - `Legality_Duplicate_Variant_Choice`
  - `Legality_Duplicate_Exception_Choice`
  - `Legality_Duplicate_Aggregate_Component_Choice`
  - `Legality_Duplicate_Delta_Aggregate_Component`
- Added local duplicate-choice helpers in `Editor.Ada_Declaration_Parser`:
  - `Normalized_Choice_Text`
  - `Choice_Count_In_List`
  - `Looks_Like_Aggregate_Context`
- Added diagnostics for duplicate choices/selectors in:
  - one case-statement alternative, e.g. `when A | A =>`
  - one variant-record alternative, e.g. `when 1 | 1 =>`
  - one exception handler, e.g. `when Constraint_Error | Constraint_Error =>`
  - one aggregate expression with duplicate named component selectors
  - one delta aggregate expression with duplicate component selectors
- Preserved existing local duplicate diagnostics for labels, block labels,
  generic actual formals, call named actuals, pragma named arguments, aspect
  associations, and representation clauses.

## Tests

- Added AUnit regression coverage:
  - `Test_Language_Model_Legality_Local_Duplicate_Choice_Pass`

## Validation guards

- Updated `tools/phase579_language_validation_check.adb` to require the new
  diagnostic kinds, parser helper, and regression coverage.

## Non-goals

This improves bounded local legality-adjacent diagnostics. It is not
compiler-grade legality checking for case coverage, overlapping static ranges,
variant coverage, exception handler reachability, aggregate typing, component
coverage, duplicate choices across non-local control-flow contexts, overload
resolution, visibility, or expected-type analysis.
