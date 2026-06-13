Pass1330 - Ada context-clause, with/use, and unit-visibility vertical slice

Implemented Editor.Ada_Context_Clause_With_Use_Vertical_Slice_Legality.

This pass adds a source-shaped legality model for context clauses and unit visibility. It covers ordinary with clauses, private with clauses, limited with clauses, use package clauses, use type clauses, target-unit and target-type resolution, duplicate with/use detection, nonlimited dependency-cycle rejection, limited-view cycle acceptance, private-child visibility barriers, full-view use through limited views, package-body context propagation, generic contract context presence, ambiguous use-visible homographs outside overload filtering, and stale source/unit/view/closure fingerprint rejection.

Added AUnit coverage in Test_Ada_Context_Clause_With_Use_Vertical_Slice_Legality_Pass1330 and registered it in Core_Suite.

This continues the post-pass1296 vertical-slice plan and avoids diagnostic/provenance/recheck churn.
