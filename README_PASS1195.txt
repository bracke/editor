Pass1195 - Final semantic diagnostic feed integration

This pass extends Editor.Ada_Semantic_Diagnostic_Feed with Build_With_Final_Semantic_Diagnostics.

The pass connects the Pass1194 final semantic diagnostic integration model into the existing snapshot-guarded semantic diagnostic feed and index path while preserving the final blocker family selected by the semantic engines.  It deliberately does not add UI projection, status, command, palette, keybinding, workspace, render, LSP, compiler, parser-generator, or file-system behavior.

The feed integration:

* emits only final rows whose Pass1194 status is an emitted diagnostic;
* withholds legal final rows as non-diagnostic semantic evidence;
* maps final cross-unit blockers to cross-unit diagnostic source rows;
* maps final generic replay blockers to generic-contract diagnostic source rows;
* maps final representation/freezing blockers to representation diagnostic source rows;
* keeps overload/type, flow/contract, tasking/protected, elaboration, accessibility/lifetime, discriminant/variant, multiple, and unknown final blockers as expression-source diagnostics;
* preserves final severity, node, source span, message, fingerprint, and source fingerprint;
* rejects stale final semantic input with zero active feed rows;
* preserves rejected-row accounting when final input or the base snapshot guard is stale;
* remains deterministic, bounded, and snapshot-owned.

Added regression:

* Test_Ada_Final_Semantic_Diagnostic_Feed_Pass1195

Updated files include:

* src/core/editor-ada_semantic_diagnostic_feed.ads
* src/core/editor-ada_semantic_diagnostic_feed.adb
* tests/src/test_ada_final_semantic_diagnostic_feed_pass1195.ads
* tests/src/test_ada_final_semantic_diagnostic_feed_pass1195.adb
* tests/src/core_suite.adb
* README_PASS1195.txt
* README.md
* ada_parser_coverage_matrix.md
* syntax_colouring_notes.md
* release_checklist.md
* strict_runtime_validation.md
