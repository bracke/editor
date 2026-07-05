Pass1066 — Exact record layout size/alignment validation

Added Editor.Ada_Record_Layout_Exact_Validation. The package consumes Editor.Ada_Representation_Legality and Editor.Ada_Record_Layout_Validation, then derives deterministic whole-record layout metadata from component bit spans and Size/Alignment representation clauses. It classifies target summaries, exact Size clauses, padded Size clauses, Size clauses smaller than occupied bits, compatible Alignment clauses, non-power-of-two Alignment clauses, static/target alignment errors, propagated component errors, counters, target lookup, and stable fingerprints.

Added Test_Ada_Record_Layout_Exact_Size_Alignment_Pass1066. Updated README, parser coverage matrix, syntax-colouring notes, release checklist, and strict runtime validation notes.

This pass adds one compiler-grade building block for exact record representation layout validation. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
