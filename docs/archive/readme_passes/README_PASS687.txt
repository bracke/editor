# Editor Pass 687

This pass deepens the token-cursor grammar for Ada use clauses.

## Implemented

- Added `Production_Use_Package_Name_List` so ordinary `use P, Q;` clauses retain an explicit list production rather than only per-name markers.
- Added `Production_Use_Type_Subtype_Mark_List` so both `use type T, U;` and `use all type T, U;` retain an explicit subtype-mark list production.
- Added `Production_Use_All_Type_Prefix` to preserve the Ada 2012 `all type` prefix as a first-class structural marker.
- Added `Production_Use_Clause_Separator` to retain comma separators in use-clause name lists.
- Added bounded recovery for empty and trailing-comma use-clause lists while continuing into following declarations.

## Tests

AUnit coverage was extended for:

- context-clause `use`, `use type`, and `use all type` forms;
- declarative-part use clauses without context-clause ownership leakage;
- explicit package-name and subtype-mark list productions;
- comma separator retention;
- class-wide attribute suffix retention in `use all type` subtype marks;
- malformed empty and trailing-comma use-clause recovery into following declarations.

## Scope

This improves structural grammar coverage for Ada use clauses. It is not compiler-grade legality checking for visibility, subtype-mark legality, package-name legality, freezing, limited-view restrictions, or semantic effects of use visibility.
