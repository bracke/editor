Pass1056 - Ada view-aware compatibility integration

This pass adds Editor.Ada_View_Aware_Compatibility, a deterministic bridge that projects private-view and limited-view compatibility effects from existing expression/type metadata into a consumer-facing model.

Implemented:
- New package Editor.Ada_View_Aware_Compatibility.
- Classification of subtype-compatibility statuses for private partial views, full views, hidden full views, compatible types, incompatible types, and indeterminate cases.
- Classification of expression-level cross-unit selected-name statuses for resolved, limited, private, unresolved, missing, ambiguous, and overflow prefixes.
- Preserved expression identity, syntax node, selected-name identity/status, source span, expected/actual subtype labels, cross-unit target/selector metadata, and deterministic fingerprints.
- Counters for compatible, private-view, limited-view, unresolved, incompatible, and indeterminate entries.
- Lookup helper First_For_Expression and status counting.
- AUnit regression Test_Ada_View_Aware_Compatibility_Pass1056.

Invariant notes:
- No rendering-side parsing.
- No file saves or reloads during analysis.
- No dirty-state mutation.
- No command-palette, keybinding, workspace, or render mutation leaks.
- Analysis remains deterministic, bounded, and snapshot-owned.
