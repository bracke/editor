Pass1070 implements dispatching-call legality diagnostics.

Added package:
- Editor.Ada_Dispatching_Call_Legality

Extended package:
- Editor.Ada_Expression_Diagnostics

Scope:
- Consumes Editor.Ada_Expression_Types dispatching-call inference metadata.
- Classifies static binding, dynamic dispatch, primitive targets, controlling-result cases, unresolved targets, ambiguous targets, and unknown controlling operands/results.
- Preserves expression identity, syntax node, controlling subtype, result subtype, primitive/controlling/ambiguous/unknown counters, source spans, source fingerprints, and deterministic legality fingerprints.
- Projects unresolved/ambiguous/unknown dispatching legality barriers into expression diagnostics.
- Keeps resolved dispatching classifications metadata-only and non-diagnostic.

Regression:
- Test_Ada_Dispatching_Call_Legality_Pass1070

Invariant:
- No rendering-side parsing.
- No file saves/reloads during analysis.
- No dirty-state mutation.
- No command/keybinding/workspace/render mutation leaks.
- Analysis remains deterministic, bounded, and snapshot-owned.
