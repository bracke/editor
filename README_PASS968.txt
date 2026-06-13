Editor Phase 579 - Pass968

Implemented generic formal/actual kind conformance foundation.

Changes:
- Extended Editor.Ada_Generic_Contracts with Generic_Actual_Kind.
- Generic instantiations now retain positional and named actual-kind metadata.
- Formal/actual matching records compatible, mismatched, and unknown kind counts.
- Added Generic_Actual_Match_Formal_Kind_Mismatch.
- Added Kind_Mismatch_Count_For_Instance query helper.
- Added AUnit regression Test_Ada_Generic_Formal_Actual_Kind_Conformance_Pass968.
- Updated parser coverage, release checklist, and README notes.

Scope:
This is a compiler-grade generic-contract building block. It does not yet complete formal subprogram profile conformance, formal package contract matching, overload resolution, private-view legality, freezing/representation legality, compiler invocation, LSP integration, renderer-side parsing, background scanning, file mutation, or dirty-state mutation.
