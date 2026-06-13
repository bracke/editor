Editor Phase 579 - Pass967

This pass extends the generic contract model with the first deterministic formal/actual matching layer for compiler-grade Ada analysis.

Changed:
- Extended `Editor.Ada_Generic_Contracts` with `Generic_Actual_Match_Info` records.
- Added formal/actual matching statuses for valid instances, malformed instances, unresolved/ambiguous generic names, non-generic targets, missing formal regions, too many positional actuals, unknown named actuals, duplicate named actuals, and missing required formals.
- Added APIs to enumerate match records and fetch a match by generic instance ID.
- Added AUnit regression `Test_Ada_Generic_Actual_Matching_Foundation_Pass967`.
- Updated README, parser coverage, syntax-colouring notes, release checklist, and validation records.

Scope:
This is a compiler-grade generic-contract staging layer. Full Ada generic conformance still requires type/formal matching, formal subprogram profile conformance, formal package contract matching, generic body contract visibility, overload resolution, private-view rules, freezing/representation legality, and cross-unit semantic closure.
