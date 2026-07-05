Pass1197 - Final semantic diagnostic search index

This pass adds Editor.Ada_Final_Semantic_Diagnostic_Search_Index.

The package indexes Pass1196 final semantic diagnostic provenance for real semantic debugging. It preserves blocker-family identity across final diagnostic integration, unified feed insertion, index linking, and provenance rows without adding command, palette, status-line, workspace, or render projection layers.

The index supports deterministic queries by:

* final blocker family,
* provenance status,
* final diagnostic status,
* provenance stage,
* syntax node,
* source span and exact position,
* source fingerprint,
* unified feed link, and
* semantic diagnostic index link.

Preserved blocker families include cross-unit closure, overload/type, generic replay, representation/freezing, flow/contract, tasking/protected, elaboration, accessibility/lifetime, discriminant/variant, AST repair, coverage gates, view barriers, multiple blockers, unknown blockers, stale inputs, withheld legal rows, and indeterminate rows.

The model is deterministic, bounded, snapshot-owned, and performs no parsing, file IO, save/reload, dirty-state mutation, command/keybinding/workspace/render mutation, LSP use, compiler invocation, or external parser generation.

AUnit coverage was added in Test_Ada_Final_Semantic_Diagnostic_Search_Index_Pass1197 and registered in tests/src/core_suite.adb.
